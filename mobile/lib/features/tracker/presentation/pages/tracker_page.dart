import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_card.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/responsive.dart';
import '../../../../core/widgets/student_brain_loader.dart';
import '../providers/tracker_provider.dart';
import 'create_session_dialog.dart';

class TrackerPage extends ConsumerWidget {
  const TrackerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackerState = ref.watch(trackerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Tracker & Focus Sessions'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => const CreateSessionDialog(),
        ),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Book Session',
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(trackerProvider.notifier).loadTrackerData(),
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
                  // 1. Streak & Rewards Banner
                  GlassCard(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.flame.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.local_fire_department_rounded, color: AppColors.flame, size: 26),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${trackerState.streaks['current_streak'] ?? 0} Day Active Streak',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Best Record: ${trackerState.streaks['longest_streak'] ?? 0} days',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        AppButton(
                          label: 'Live Focus',
                          onPressed: () => context.push('/tracker/live'),
                          height: 38,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 2. Active Session Card if in progress
                  if (trackerState.activeSession != null) ...[
                    GlassCard(
                      borderColor: AppColors.primary,
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.success,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'SESSION CURRENTLY RUNNING',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            trackerState.activeSession!.subject,
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Duration: ${trackerState.activeSession!.totalMinutes} mins',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                            ),
                          ),
                          const SizedBox(height: 14),
                          AppButton(
                            label: 'Open Fullscreen Timer',
                            icon: const Icon(Icons.fullscreen_rounded, size: 20),
                            onPressed: () => context.push('/tracker/live'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],

                  // 3. Section Title
                  const Text(
                    'Study Sessions History & Schedule',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),

                  // 4. Sessions List
                  if (trackerState.isLoading && trackerState.sessions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 36),
                      child: StudentBrainLoader(
                        message: 'Syncing focus sessions & streaks...',
                      ),
                    )
                  else if (trackerState.error != null)
                    ErrorCard(
                      message: trackerState.error!,
                      onRetry: () => ref.read(trackerProvider.notifier).loadTrackerData(),
                    )
                  else if (trackerState.sessions.isEmpty)
                    EmptyState(
                      icon: Icons.timer_outlined,
                      title: 'No Sessions Logged Yet',
                      subtitle: 'Book a focus session to build streaks and unlock achievement badges.',
                      actionLabel: 'Book First Session',
                      onAction: () => showDialog(
                        context: context,
                        builder: (_) => const CreateSessionDialog(),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: trackerState.sessions.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final session = trackerState.sessions[index];
                        final isScheduled = session.isScheduled;
                        final isCompleted = session.isCompleted;

                        Color statusColor = AppColors.primary;
                        String statusLabel = session.status.toUpperCase();
                        IconData statusIcon = Icons.hourglass_top_rounded;

                        if (isCompleted) {
                          statusColor = AppColors.success;
                          statusLabel = 'COMPLETED';
                          statusIcon = Icons.check_circle_rounded;
                        } else if (isScheduled) {
                          statusColor = AppColors.primary;
                          statusLabel = 'SCHEDULED';
                          statusIcon = Icons.alarm_rounded;
                        } else if (session.status.toUpperCase() == 'IN_PROGRESS') {
                          statusColor = AppColors.warning;
                          statusLabel = 'IN PROGRESS';
                          statusIcon = Icons.bolt_rounded;
                        } else if (session.status.toUpperCase() == 'MISSED') {
                          statusColor = AppColors.error;
                          statusLabel = 'MISSED';
                          statusIcon = Icons.cancel_rounded;
                        }

                        // Format readable date
                        String displayDate = session.sessionDate;
                        try {
                          final dt = DateTime.parse(session.sessionDate);
                          const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                          displayDate = '${dt.day} ${months[dt.month - 1]}, ${dt.year}';
                        } catch (_) {}

                        // Format 12-hour AM/PM time
                        String displayTime = '';
                        if (session.startTime != null && session.startTime!.isNotEmpty) {
                          final parts = session.startTime!.split(':');
                          if (parts.isNotEmpty) {
                            final hr = int.tryParse(parts[0]) ?? 0;
                            final min = parts.length > 1 ? parts[1] : '00';
                            final period = hr >= 12 ? 'PM' : 'AM';
                            final h12 = hr == 0 ? 12 : (hr > 12 ? hr - 12 : hr);
                            final hStr = h12.toString().padLeft(2, '0');
                            displayTime = '$hStr:$min $period';
                          }
                        }

                        final dateAndTime = displayTime.isNotEmpty
                            ? '$displayDate  •  ⏰ $displayTime'
                            : displayDate;

                        return GlassCard(
                          padding: const EdgeInsets.all(16),
                          onTap: () => _showSessionDetailsModal(context, ref, session),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Row 1: Subject + Status Badge + Delete Action
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Text(
                                      session.subject,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: statusColor.withValues(alpha: 0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(statusIcon, size: 12, color: statusColor),
                                        const SizedBox(width: 4),
                                        Text(
                                          statusLabel,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: statusColor,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                    tooltip: 'Delete Session Record',
                                    onPressed: () => _confirmDeleteSession(context, ref, session),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),

                              // Row 2: Date & Time Display
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    size: 13,
                                    color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                                  ),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      dateAndTime,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Right-aligned focus duration badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isDark ? AppColors.surfaceDarkSubtle : AppColors.surfaceLightSubtle,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.hourglass_bottom_rounded, size: 11, color: AppColors.primary),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${session.totalMinutes} min focus',
                                          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (session.quizTaken && session.quizScore != null) ...[
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.stars_rounded, size: 12, color: AppColors.accent),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Diagnostic: ${session.quizScore!.toInt()}%',
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.accent),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              if (session.courseTitle != null || session.materialTitle != null) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.auto_stories_outlined, size: 13, color: AppColors.primary),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        [
                                          if (session.courseTitle != null) session.courseTitle!,
                                          if (session.materialTitle != null) session.materialTitle!,
                                        ].join(' • '),
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],

                              if (session.notes.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  session.notes,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],

                              if (isScheduled) ...[
                                const SizedBox(height: 12),
                                AppButton(
                                  label: 'Start Focus Session',
                                  height: 38,
                                  onPressed: () async {
                                    final err = await ref.read(trackerProvider.notifier).startSession(session.id);
                                    if (err != null && context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(err),
                                          backgroundColor: AppColors.error,
                                        ),
                                      );
                                    } else if (context.mounted) {
                                      context.push('/tracker/live');
                                    }
                                  },
                                ),
                              ],
                              if (session.status.toUpperCase() == 'IN_PROGRESS') ...[
                                const SizedBox(height: 12),
                                AppButton(
                                  label: 'Continue Live Focus',
                                  icon: const Icon(Icons.bolt_rounded, size: 16),
                                  height: 38,
                                  onPressed: () => context.push('/tracker/live'),
                                ),
                              ],
                              if (isCompleted && !session.quizTaken) ...[
                                const SizedBox(height: 12),
                                AppButton(
                                  label: 'Take AI Diagnostic Quiz',
                                  variant: AppButtonVariant.outline,
                                  height: 38,
                                  icon: const Icon(Icons.quiz_outlined, size: 16),
                                  onPressed: () => context.push('/ai/quiz/${session.id}'),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
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

  void _confirmDeleteSession(BuildContext context, WidgetRef ref, dynamic session) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Study Session'),
        content: Text('Are you sure you want to delete "${session.subject}"? This history record cannot be recovered.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final success = await ref.read(trackerProvider.notifier).deleteSession(session.id);
              if (!success && context.mounted) {
                final err = ref.read(trackerProvider).error ?? 'Failed to delete session';
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(err), backgroundColor: AppColors.error),
                );
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Session record deleted successfully')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showSessionDetailsModal(BuildContext context, WidgetRef ref, dynamic session) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCompleted = session.status.toUpperCase() == 'COMPLETED';
    final isScheduled = session.status.toUpperCase() == 'SCHEDULED';
    final isInProgress = session.status.toUpperCase() == 'IN_PROGRESS';

    Color statusColor = AppColors.primary;
    String statusLabel = session.status.toUpperCase();
    IconData statusIcon = Icons.hourglass_top_rounded;

    if (isCompleted) {
      statusColor = AppColors.success;
      statusLabel = 'COMPLETED';
      statusIcon = Icons.check_circle_rounded;
    } else if (isScheduled) {
      statusColor = AppColors.primary;
      statusLabel = 'SCHEDULED';
      statusIcon = Icons.alarm_rounded;
    } else if (isInProgress) {
      statusColor = AppColors.warning;
      statusLabel = 'IN PROGRESS';
      statusIcon = Icons.bolt_rounded;
    } else if (session.status.toUpperCase() == 'MISSED') {
      statusColor = AppColors.error;
      statusLabel = 'MISSED';
      statusIcon = Icons.cancel_rounded;
    }

    String displayDate = session.sessionDate;
    try {
      final dt = DateTime.parse(session.sessionDate);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      displayDate = '${dt.day} ${months[dt.month - 1]}, ${dt.year}';
    } catch (_) {}

    String displayTime = 'Not specified';
    if (session.startTime != null && session.startTime!.isNotEmpty) {
      final parts = session.startTime!.split(':');
      if (parts.isNotEmpty) {
        final hr = int.tryParse(parts[0]) ?? 0;
        final min = parts.length > 1 ? parts[1] : '00';
        final period = hr >= 12 ? 'PM' : 'AM';
        final h12 = hr == 0 ? 12 : (hr > 12 ? hr - 12 : hr);
        final hStr = h12.toString().padLeft(2, '0');
        displayTime = '$hStr:$min $period';
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bCtx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          maxWidth: 600,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 1,
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title & Status
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.subject,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusIcon, size: 13, color: statusColor),
                              const SizedBox(width: 5),
                              Text(
                                statusLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: statusColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(bCtx),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Divider(height: 1),
              const SizedBox(height: 18),

              // Key Metrics Grid
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDarkSubtle : AppColors.surfaceLightSubtle,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? AppColors.borderDark : AppColors.borderLight,
                          width: 0.8,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.calendar_today_rounded, size: 14, color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted),
                              const SizedBox(width: 6),
                              Text(
                                'Date & Time',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            displayDate,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                          ),
                          Text(
                            displayTime != 'Not specified' ? '⏰ $displayTime' : displayTime,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDarkSubtle : AppColors.surfaceLightSubtle,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? AppColors.borderDark : AppColors.borderLight,
                          width: 0.8,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.timer_outlined, size: 14, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Text(
                                'Focused Time',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${session.totalMinutes} min',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.primary),
                          ),
                          Text(
                            'Target: ${session.durationMinutes} min',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Course & Material Info
              if (session.courseTitle != null || session.materialTitle != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDarkSubtle : AppColors.surfaceLightSubtle,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      width: 0.8,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (session.courseTitle != null)
                        Row(
                          children: [
                            const Icon(Icons.school_outlined, size: 14, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Course: ${session.courseTitle}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      if (session.courseTitle != null && session.materialTitle != null)
                        const SizedBox(height: 8),
                      if (session.materialTitle != null)
                        Row(
                          children: [
                            const Icon(Icons.menu_book_rounded, size: 14, color: AppColors.secondary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Document: ${session.materialTitle}',
                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Diagnostic Quiz Section
              if (session.quizTaken && session.quizScore != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.stars_rounded, color: AppColors.accent, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'AI Diagnostic Quiz Completed',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Mastery Score: ${session.quizScore!.toInt()}%',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: AppColors.accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Notes / Agenda
              if (session.notes.isNotEmpty) ...[
                const Text(
                  'Session Notes / Agenda',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDarkSubtle : AppColors.surfaceLightSubtle,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    session.notes,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: isDark ? AppColors.textDark : AppColors.textLight,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Actions
              if (isScheduled) ...[
                AppButton(
                  label: 'Start Focus Session Now',
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  onPressed: () async {
                    Navigator.pop(bCtx);
                    final err = await ref.read(trackerProvider.notifier).startSession(session.id);
                    if (err != null && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(err), backgroundColor: AppColors.error),
                      );
                    } else if (context.mounted) {
                      context.push('/tracker/live');
                    }
                  },
                ),
                const SizedBox(height: 10),
              ],
              if (isInProgress) ...[
                AppButton(
                  label: 'Continue Live Focus Session',
                  icon: const Icon(Icons.bolt_rounded, size: 18),
                  onPressed: () {
                    Navigator.pop(bCtx);
                    context.push('/tracker/live');
                  },
                ),
                const SizedBox(height: 10),
              ],
              if (isCompleted && !session.quizTaken) ...[
                AppButton(
                  label: 'Take AI Diagnostic Quiz',
                  variant: AppButtonVariant.outline,
                  icon: const Icon(Icons.quiz_outlined, size: 18),
                  onPressed: () {
                    Navigator.pop(bCtx);
                    context.push('/ai/quiz/${session.id}');
                  },
                ),
                const SizedBox(height: 10),
              ],

              // Delete Session Button
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error, width: 1),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.delete_outline_rounded, size: 16),
                label: const Text('Delete Study Session Record', style: TextStyle(fontWeight: FontWeight.w700)),
                onPressed: () {
                  Navigator.pop(bCtx);
                  _confirmDeleteSession(context, ref, session);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
