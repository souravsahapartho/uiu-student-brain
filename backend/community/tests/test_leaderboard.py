from datetime import date, timedelta
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from accounts.models import User
from community.models import Follow, LeaderboardProfile
from tracker.models import StudySession


class LeaderboardApiTests(APITestCase):
    def setUp(self):
        self.user1 = User.objects.create_user(
            email="alice@example.com",
            password="StrongPass123!",
            full_name="Alice Scholar",
        )
        self.user2 = User.objects.create_user(
            email="bob@example.com",
            password="StrongPass123!",
            full_name="Bob TopStudent",
        )
        self.user3 = User.objects.create_user(
            email="charlie@example.com",
            password="StrongPass123!",
            full_name="Charlie Quiet",
        )

        login_res = self.client.post(
            reverse("login"),
            {"email": "alice@example.com", "password": "StrongPass123!"},
        )
        self.access = login_res.data["access"]
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {self.access}")

        today = date.today()
        # Alice study sessions (60 mins today, 120 mins 2 days ago = 180 mins)
        StudySession.objects.create(
            user=self.user1,
            subject="Algorithms",
            duration_minutes=60,
            session_date=today,
            status="completed",
        )
        StudySession.objects.create(
            user=self.user1,
            subject="Algorithms",
            duration_minutes=120,
            session_date=today - timedelta(days=2),
            status="completed",
        )

        # Bob study sessions (180 mins today, 120 mins yesterday = 300 mins)
        StudySession.objects.create(
            user=self.user2,
            subject="Physics",
            duration_minutes=180,
            session_date=today,
            status="completed",
        )
        StudySession.objects.create(
            user=self.user2,
            subject="Physics",
            duration_minutes=120,
            session_date=today - timedelta(days=1),
            status="completed",
        )

        # Charlie study sessions (200 mins today, but Charlie will NOT opt in)
        StudySession.objects.create(
            user=self.user3,
            subject="Chemistry",
            duration_minutes=200,
            session_date=today,
            status="completed",
        )

    def test_leaderboard_status_default(self):
        res = self.client.get(reverse("community-leaderboard-status"))
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        # Users are opted in by default unless they explicitly opt out
        self.assertTrue(res.data["is_opted_in"])
        self.assertEqual(res.data["user_id"], self.user1.id)

    def test_toggle_opt_in(self):
        # Opt in with a quote
        res = self.client.post(
            reverse("community-leaderboard-opt-in"),
            {"is_opted_in": True, "custom_quote": "Consistency is key!"},
            format="json",
        )
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertTrue(res.data["is_opted_in"])
        self.assertEqual(res.data["custom_quote"], "Consistency is key!")

        # Verify DB
        profile = LeaderboardProfile.objects.get(user=self.user1)
        self.assertTrue(profile.is_opted_in)
        self.assertEqual(profile.custom_quote, "Consistency is key!")

        # Opt back out
        res2 = self.client.post(
            reverse("community-leaderboard-opt-in"),
            {"is_opted_in": False},
            format="json",
        )
        self.assertEqual(res2.status_code, status.HTTP_200_OK)
        self.assertFalse(res2.data["is_opted_in"])

    def test_leaderboard_filtering_and_ranking(self):
        # Opt in Bob and Alice
        LeaderboardProfile.objects.create(
            user=self.user2,
            is_opted_in=True,
            custom_quote="Targeting 4.0 GPA",
        )
        LeaderboardProfile.objects.create(
            user=self.user1,
            is_opted_in=True,
            custom_quote="Focus mode ON",
        )
        # Charlie has opted out
        LeaderboardProfile.objects.create(user=self.user3, is_opted_in=False)

        # Alice follows Bob
        Follow.objects.create(follower=self.user1, following=self.user2)

        # 1. Weekly ranking
        res = self.client.get(reverse("community-leaderboard"), {"timeframe": "weekly"})
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data["total_participants"], 2)
        rankings = res.data["rankings"]
        self.assertEqual(len(rankings), 2)

        # Bob should be #1 (300 mins vs Alice 180 mins)
        self.assertEqual(rankings[0]["user_id"], self.user2.id)
        self.assertEqual(rankings[0]["rank"], 1)
        self.assertEqual(rankings[0]["study_minutes"], 300)
        self.assertTrue(rankings[0]["is_following"])

        # Alice should be #2
        self.assertEqual(rankings[1]["user_id"], self.user1.id)
        self.assertEqual(rankings[1]["rank"], 2)
        self.assertEqual(rankings[1]["study_minutes"], 180)
        self.assertTrue(rankings[1]["is_current_user"])

        # Current user summary
        self.assertEqual(res.data["current_user_rank"], 2)
        self.assertTrue(res.data["is_opted_in"])

        # 2. Streak ranking
        res_streak = self.client.get(reverse("community-leaderboard"), {"timeframe": "streak"})
        self.assertEqual(res_streak.status_code, status.HTTP_200_OK)
        # Bob has 2-day streak (today & yesterday), Alice has 1-day streak (today)
        streak_rankings = res_streak.data["rankings"]
        self.assertEqual(streak_rankings[0]["user_id"], self.user2.id)
        self.assertEqual(streak_rankings[0]["current_streak"], 2)

    def test_leaderboard_when_current_user_not_opted_in(self):
        # Bob is opted in, Alice and Charlie have opted out
        LeaderboardProfile.objects.create(
            user=self.user2,
            is_opted_in=True,
            custom_quote="Studying hard",
        )
        LeaderboardProfile.objects.create(user=self.user1, is_opted_in=False)
        LeaderboardProfile.objects.create(user=self.user3, is_opted_in=False)

        res = self.client.get(reverse("community-leaderboard"))
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertFalse(res.data["is_opted_in"])
        self.assertIsNone(res.data["current_user_rank"])
        # Should still have current_user_entry preview
        self.assertIsNotNone(res.data["current_user_entry"])
        self.assertEqual(res.data["current_user_entry"]["study_minutes"], 180)
        self.assertEqual(len(res.data["rankings"]), 1)
        self.assertEqual(res.data["rankings"][0]["user_id"], self.user2.id)
