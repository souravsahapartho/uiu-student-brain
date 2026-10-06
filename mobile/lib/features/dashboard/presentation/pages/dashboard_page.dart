import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/responsive.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../../core/config/providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/widgets/mandatory_onboarding_dialog.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/notifications_sheet.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  bool _hasCheckedOnboarding = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAcademicOnboarding();
    });
  }

  void _checkAcademicOnboarding() {
    if (_hasCheckedOnboarding || !mounted) return;
    final prefs = ref.read(sharedPreferencesProvider);
    final user = ref.read(authProvider).user;
    final isOnboardedPref = prefs.getBool('academic_onboarding_completed') ?? false;
    final isOnboardedUser = user?.isOnboarded ?? false;

    if (!isOnboardedPref && !isOnboardedUser && user != null) {
      _hasCheckedOnboarding = true;
      showDialog(
        context: context,
        useRootNavigator: true,
        barrierDismissible: false,
        barrierColor: Colors.black.withValues(alpha: 0.85),
        builder: (_) => const MandatoryOnboardingDialog(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final dashState = ref.watch(dashboardProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final progressRatio = dashState.dailyGoalMinutes > 0
        ? (dashState.todayMinutes / dashState.dailyGoalMinutes).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        bottom: dashState.isLoading
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(
                  minHeight: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  backgroundColor: Colors.transparent,
                ),
              )
            : null,
        title: InkWell(
          onTap: () => context.go('/profile'),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
            Stack(
              children: [
                UserAvatar(
                  name: user?.fullName ?? 'Scholar',
                  imageUrl: user?.avatar,
                  seed: user?.email ?? user?.fullName,
                  size: 38,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                        width: 1.8,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          'Hello, ${user?.fullName.split(' ').first ?? 'Scholar'}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.waving_hand_rounded, color: AppColors.accent, size: 16),
                    ],
                  ),
                  const SizedBox(height: 1),
                  Text(
                    user?.department ?? 'UIU Academic Portal',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, size: 22),
                tooltip: 'Notifications',
                onPressed: () => NotificationsSheet.show(context),
              ),
              if (dashState.unreadNotifications > 0)
                Positioned(
                  top: 13,
                  right: 13,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded, size: 21),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(dashboardProvider.notifier).loadDashboard();
        },
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: Responsive.padding(context),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: Responsive.maxContentWidth(context)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Streak & Today Focus Row
                  Row(
                    children: [
                      // Streak Card
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => context.push('/analytics'),
                            child: GlassCard(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: AppColors.flame.withValues(alpha: 0.15),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.local_fire_department_rounded, color: AppColors.flame, size: 18),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Streak',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 11,
                                        color: isDark ? AppColors.textDarkSubtle : AppColors.textLightSubtle,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    '${dashState.currentStreak} Days',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.flame,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Record: ${dashState.longestStreak} days',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? AppColors.textDarkSubtle : AppColors.textLightSubtle,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Today's Focus Card
                      Expanded(
                        child: GlassCard(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Today Focus',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      '${dashState.todayMinutes}m',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        color: isDark ? AppColors.textDark : AppColors.textLight,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Goal: ${dashState.dailyGoalMinutes}m',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? AppColors.textDarkSubtle : AppColors.textLightSubtle,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              CircularPercentIndicator(
                                radius: 24.0,
                                lineWidth: 4.5,
                                percent: progressRatio,
                                center: Text(
                                  '${(progressRatio * 100).toInt()}%',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                progressColor: AppColors.primary,
                                backgroundColor: isDark ? AppColors.borderDark : AppColors.borderLight,
                                circularStrokeCap: CircularStrokeCap.round,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 2. GPA Trajectory Snapshot
                  GlassCard(
                    onTap: () => context.go('/grades'),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.analytics_outlined, size: 18, color: AppColors.primary),
                                const SizedBox(width: 8),
                                const Text(
                                  'GPA Trajectory Forecast',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: AppColors.primary),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem('Current', dashState.currentGpa.toStringAsFixed(2), AppColors.primary),
                            _buildStatItem('Target', dashState.targetGpa.toStringAsFixed(2), AppColors.warning),
                            _buildStatItem('Required', dashState.requiredGpa.toStringAsFixed(2), AppColors.accent),
                          ],
                        ),
                        const SizedBox(height: 10),
                        LinearPercentIndicator(
                          lineHeight: 6.0,
                          percent: (dashState.currentGpa / 4.0).clamp(0.0, 1.0),
                          backgroundColor: isDark ? AppColors.borderDark : AppColors.borderLight,
                          progressColor: AppColors.primary,
                          barRadius: const Radius.circular(3),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 3. Quick Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'Live Focus',
                          icon: const Icon(Icons.play_arrow_rounded, size: 20),
                          onPressed: () => context.push('/tracker/live'),
                          height: 42,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AppButton(
                          label: 'AI Tutor',
                          variant: AppButtonVariant.secondary,
                          icon: const Icon(Icons.smart_toy_outlined, size: 18, color: AppColors.primary),
                          onPressed: () => context.go('/materials'),
                          height: 42,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 4. AI Academic Recommendation
                  GlassCard(
                    padding: const EdgeInsets.all(14),
                    borderColor: AppColors.primary.withValues(alpha: 0.25),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.auto_awesome, color: AppColors.primary, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'AI Study Recommendation',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                dashState.aiRecommendation,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 5. Upcoming Schedule Header & List
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Upcoming Classes',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                      TextButton(
                        onPressed: () => context.go('/planner'),
                        child: const Text('View Routine'),
                      ),
                    ],
                  ),
                  if (dashState.upcomingClasses.isEmpty)
                    GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: Text(
                          'No upcoming classes scheduled today.',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                          ),
                        ),
                      ),
                    )
                  else
                    ...dashState.upcomingClasses.map((item) {
                      final rawSubject = item['subject']?.toString() ?? 'Course Class';
                      final isEvent = rawSubject.toLowerCase().startsWith('[event]') || item['type'] == 'event';
                      final title = isEvent ? rawSubject.replaceFirst(RegExp(r'^\[Event\]\s*', caseSensitive: false), '') : rawSubject;
                      final rawTime = item['start_time']?.toString() ?? '';
                      final formattedTime = rawTime.length >= 5 ? rawTime.substring(0, 5) : rawTime;

                      final accentColor = isEvent ? AppColors.accent : AppColors.primary;
                      final icon = isEvent ? Icons.groups_rounded : Icons.school_rounded;
                      final badgeText = isEvent ? 'STUDY EVENT' : 'ACADEMIC CLASS';
                      final subtitleText = isEvent
                          ? 'Venue: ${item['room'] ?? item['location'] ?? 'Campus / Online Meetup'}'
                          : 'Room: ${item['room'] ?? 'TBA'} • ${item['teacher'] ?? 'Faculty'}';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: GlassCard(
                          onTap: () {
                            if (isEvent) {
                              context.go('/community');
                            } else {
                              context.go('/planner');
                            }
                          },
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: accentColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: accentColor.withValues(alpha: 0.25),
                                  ),
                                ),
                                child: Icon(icon, color: accentColor, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: accentColor.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            badgeText,
                                            style: TextStyle(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w800,
                                              color: accentColor,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      title,
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      subtitleText,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.surfaceDarkSubtle : AppColors.surfaceLightSubtle,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.access_time_rounded, size: 12, color: accentColor),
                                    const SizedBox(width: 4),
                                    Text(
                                      formattedTime,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w800,
                                        color: accentColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 18),

                  // 6. Scholarboard / Top Scholars Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.emoji_events_rounded, color: AppColors.gold, size: 18),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Scholarboard',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: () => context.push('/community/leaderboard'),
                        icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                        label: const Text('View All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (dashState.leaderboardTopThree.isNotEmpty)
                    GlassCard(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Column(
                        children: List.generate(dashState.leaderboardTopThree.length, (index) {
                          final item = dashState.leaderboardTopThree[index];
                          final rank = item['rank'] ?? (index + 1);
                          final name = item['display_name'] ?? item['full_name'] ?? item['username'] ?? 'Scholar #$rank';
                          final rawHours = item['study_hours'] != null
                              ? (double.tryParse('${item['study_hours']}') ?? 0.0)
                              : item['weekly_minutes'] != null
                                  ? (double.tryParse('${item['weekly_minutes']}') ?? 0.0) / 60.0
                                  : 0.0;
                          final hoursStr = '${rawHours.toStringAsFixed(1)}h';
                          final streak = item['current_streak'] ?? 0;
                          final avatarUrl = item['avatar'] as String?;

                          Color rankColor;
                          IconData rankIcon;
                          if (rank == 1) {
                            rankColor = AppColors.gold;
                            rankIcon = Icons.military_tech_rounded;
                          } else if (rank == 2) {
                            rankColor = AppColors.silver;
                            rankIcon = Icons.military_tech_rounded;
                          } else {
                            rankColor = AppColors.bronze;
                            rankIcon = Icons.military_tech_rounded;
                          }

                          return InkWell(
                            onTap: () => context.push('/community/leaderboard'),
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  Container(
                                    width: 26,
                                    height: 26,
                                    decoration: BoxDecoration(
                                      color: rankColor.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Icon(rankIcon, color: rankColor, size: 16),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  UserAvatar(
                                    name: name,
                                    imageUrl: avatarUrl,
                                    seed: name,
                                    size: 34,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          streak > 0 ? '🔥 $streak-day streak' : 'Dedicated Scholar',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(9999),
                                    ),
                                    child: Text(
                                      hoursStr,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    )
                  else
                    GlassCard(
                      onTap: () => context.push('/community/leaderboard'),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.emoji_events_rounded, color: AppColors.gold, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Top Weekly Scholarboard',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Complete focus sessions to take the lead!',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey),
        ),
      ],
    );
  }
}
