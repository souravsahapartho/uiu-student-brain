import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/providers.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/secure_storage_service.dart';

class DashboardState {
  final int currentStreak;
  final int longestStreak;
  final int todayMinutes;
  final int dailyGoalMinutes;
  final double currentGpa;
  final double targetGpa;
  final double requiredGpa;
  final List<Map<String, dynamic>> upcomingClasses;
  final List<Map<String, dynamic>> recentMaterials;
  final List<Map<String, dynamic>> leaderboardTopThree;
  final String aiRecommendation;
  final int unreadNotifications;
  final bool isLoading;
  final String? error;

  const DashboardState({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.todayMinutes = 0,
    this.dailyGoalMinutes = 60,
    this.currentGpa = 3.85,
    this.targetGpa = 3.90,
    this.requiredGpa = 3.94,
    this.upcomingClasses = const [],
    this.recentMaterials = const [],
    this.leaderboardTopThree = const [],
    this.aiRecommendation = 'Maintain your study consistency. Review weak topics from recent quizzes to maximize retention.',
    this.unreadNotifications = 0,
    this.isLoading = false,
    this.error,
  });

  DashboardState copyWith({
    int? currentStreak,
    int? longestStreak,
    int? todayMinutes,
    int? dailyGoalMinutes,
    double? currentGpa,
    double? targetGpa,
    double? requiredGpa,
    List<Map<String, dynamic>>? upcomingClasses,
    List<Map<String, dynamic>>? recentMaterials,
    List<Map<String, dynamic>>? leaderboardTopThree,
    String? aiRecommendation,
    int? unreadNotifications,
    bool? isLoading,
    String? error,
  }) {
    return DashboardState(
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      todayMinutes: todayMinutes ?? this.todayMinutes,
      dailyGoalMinutes: dailyGoalMinutes ?? this.dailyGoalMinutes,
      currentGpa: currentGpa ?? this.currentGpa,
      targetGpa: targetGpa ?? this.targetGpa,
      requiredGpa: requiredGpa ?? this.requiredGpa,
      upcomingClasses: upcomingClasses ?? this.upcomingClasses,
      recentMaterials: recentMaterials ?? this.recentMaterials,
      leaderboardTopThree: leaderboardTopThree ?? this.leaderboardTopThree,
      aiRecommendation: aiRecommendation ?? this.aiRecommendation,
      unreadNotifications: unreadNotifications ?? this.unreadNotifications,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class DashboardNotifier extends StateNotifier<DashboardState> {
  final DioClient _dioClient;
  final SecureStorageService _storageService;

  DashboardNotifier(this._dioClient, this._storageService) : super(const DashboardState()) {
    _loadFromCache();
    loadDashboard();
  }

  void _loadFromCache() {
    try {
      final jsonStr = _storageService.getCachedDashboardJson();
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        state = state.copyWith(
          currentStreak: map['current_streak'] as int?,
          longestStreak: map['longest_streak'] as int?,
          todayMinutes: map['today_minutes'] as int?,
          dailyGoalMinutes: map['daily_goal_minutes'] as int?,
          currentGpa: (map['current_gpa'] != null) ? double.tryParse('${map['current_gpa']}') : null,
          targetGpa: (map['target_gpa'] != null) ? double.tryParse('${map['target_gpa']}') : null,
          requiredGpa: (map['required_gpa'] != null) ? double.tryParse('${map['required_gpa']}') : null,
        );
      }
    } catch (_) {}
  }

  Future<void> loadDashboard() async {
    state = state.copyWith(isLoading: true, error: null);

    int streak = state.currentStreak;
    int maxStreak = state.longestStreak;
    int goalMin = state.dailyGoalMinutes;
    int todayMin = state.todayMinutes;
    double cGpa = state.currentGpa;
    double tGpa = state.targetGpa;
    double rGpa = state.requiredGpa;
    List<Map<String, dynamic>> classes = state.upcomingClasses;
    List<Map<String, dynamic>> materials = state.recentMaterials;
    List<Map<String, dynamic>> topThree = state.leaderboardTopThree;
    int unreadNotifs = state.unreadNotifications;

    try {
      await Future.wait([
        // 1. Streaks
        () async {
          try {
            final streakRes = await _dioClient.get(ApiEndpoints.streaks);
            if (streakRes.data is Map) {
              streak = streakRes.data['current_streak'] ?? streak;
              maxStreak = streakRes.data['longest_streak'] ?? maxStreak;
            }
          } catch (_) {}
        }(),

        // 2. Goal
        () async {
          try {
            final goalRes = await _dioClient.get(ApiEndpoints.studyGoal);
            if (goalRes.data is Map) {
              goalMin = goalRes.data['daily_target_minutes'] ?? goalMin;
              todayMin = goalRes.data['today_minutes'] ?? todayMin;
            }
          } catch (_) {}
        }(),

        // 3. Grade Plan
        () async {
          try {
            final gradeRes = await _dioClient.get(ApiEndpoints.gradePlans);
            if (gradeRes.data is List && (gradeRes.data as List).isNotEmpty) {
              final plan = (gradeRes.data as List).first;
              cGpa = double.tryParse('${plan['current_gpa']}') ?? cGpa;
              tGpa = double.tryParse('${plan['target_gpa']}') ?? tGpa;
              rGpa = double.tryParse('${plan['required_gpa']}') ?? rGpa;
            }
          } catch (_) {}
        }(),

        // 4. Schedules
        () async {
          try {
            final schedRes = await _dioClient.get(ApiEndpoints.schedules);
            if (schedRes.data is List) {
              classes = (schedRes.data as List)
                  .map((e) => Map<String, dynamic>.from(e as Map))
                  .take(4)
                  .toList();
            }
          } catch (_) {}
        }(),

        // 5. Recent Materials
        () async {
          try {
            final matRes = await _dioClient.get(ApiEndpoints.globalMaterials);
            if (matRes.data is List) {
              materials = (matRes.data as List)
                  .map((e) => Map<String, dynamic>.from(e as Map))
                  .take(3)
                  .toList();
            }
          } catch (_) {}
        }(),

        // 6. Leaderboard Preview
        () async {
          try {
            final lbRes = await _dioClient.get(
              ApiEndpoints.leaderboard,
              queryParameters: {'timeframe': 'weekly'},
            );
            if (lbRes.data is Map && lbRes.data['rankings'] is List) {
              topThree = (lbRes.data['rankings'] as List)
                  .map((e) => Map<String, dynamic>.from(e as Map))
                  .take(3)
                  .toList();
            }
          } catch (_) {}
        }(),

        // 7. Unread Notifications Count
        () async {
          try {
            final notifRes = await _dioClient.get(ApiEndpoints.notifications);
            if (notifRes.data is Map && notifRes.data['notifications'] is List) {
              final list = notifRes.data['notifications'] as List;
              unreadNotifs = list.where((n) => n is Map && n['is_read'] != true).length;
            }
          } catch (_) {}
        }(),
      ]);

      state = state.copyWith(
        currentStreak: streak,
        longestStreak: maxStreak,
        todayMinutes: todayMin,
        dailyGoalMinutes: goalMin,
        currentGpa: cGpa,
        targetGpa: tGpa,
        requiredGpa: rGpa,
        upcomingClasses: classes,
        recentMaterials: materials,
        leaderboardTopThree: topThree,
        unreadNotifications: unreadNotifs,
        isLoading: false,
        error: null,
      );

      try {
        final cacheMap = {
          'current_streak': streak,
          'longest_streak': maxStreak,
          'today_minutes': todayMin,
          'daily_goal_minutes': goalMin,
          'current_gpa': cGpa,
          'target_gpa': tGpa,
          'required_gpa': rGpa,
        };
        _storageService.saveCachedDashboardJson(jsonEncode(cacheMap));
      } catch (_) {}
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void setUnreadNotifications(int count) {
    state = state.copyWith(unreadNotifications: count);
  }

  void clearUnreadNotifications() {
    state = state.copyWith(unreadNotifications: 0);
  }
}

final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  final storageService = ref.watch(secureStorageServiceProvider);
  return DashboardNotifier(dioClient, storageService);
});
