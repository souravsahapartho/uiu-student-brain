import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_card.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/responsive.dart';
import '../../../../core/widgets/student_brain_loader.dart';
import '../providers/planner_provider.dart';
import '../../data/models/schedule_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'add_schedule_dialog.dart';

class PlannerPage extends ConsumerWidget {
  const PlannerPage({super.key});

  static const List<String> days = [
    'All',
    'Saturday',
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plannerState = ref.watch(plannerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Routine & Timetable'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(plannerProvider.notifier).loadSchedules(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => const AddScheduleDialog(),
        ),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Add Class',
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          // Day Selector Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: days.map((day) {
                final isSelected = plannerState.selectedDay == day;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(day),
                    selected: isSelected,
                    onSelected: (_) {
                      ref.read(plannerProvider.notifier).selectDay(day);
                    },
                    selectedColor: AppColors.primary.withValues(alpha: 0.2),
                    checkmarkColor: AppColors.primary,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? AppColors.primary
                          : (isDark ? AppColors.textDarkMuted : AppColors.textLightMuted),
                    ),
                    backgroundColor:
                        isDark ? AppColors.surfaceDarkSubtle : AppColors.surfaceLightSubtle,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9999),
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : Colors.transparent,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(),

          // Main Schedule List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(plannerProvider.notifier).loadSchedules(),
              color: AppColors.primary,
              child: Builder(
                builder: (context) {
                  if (plannerState.isLoading) {
                    return const Center(
                      child: StudentBrainLoader(size: 40, message: 'Loading routine & class schedules...'),
                    );
                  }

                  if (plannerState.error != null) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ErrorCard(
                          message: plannerState.error!,
                          onRetry: () =>
                              ref.read(plannerProvider.notifier).loadSchedules(),
                        ),
                      ),
                    );
                  }

                  final schedules = plannerState.filteredSchedules;

                  if (schedules.isEmpty) {
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(24),
                      child: EmptyState(
                        icon: Icons.calendar_today_outlined,
                        title: 'No Classes for ${plannerState.selectedDay}',
                        subtitle:
                            'You do not have any routine classes scheduled for this day.',
                        actionLabel: 'Add Class Routine',
                        onAction: () => showDialog(
                          context: context,
                          builder: (_) => const AddScheduleDialog(),
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: Responsive.padding(context),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: schedules.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = schedules[index];
                      final isEvent = item.subject.startsWith('[Event]') ||
                          item.subject.toLowerCase().contains('hackathon') ||
                          item.subject.toLowerCase().contains('event');

                      if (isEvent) {
                        return _buildEventCard(context, ref, item, isDark);
                      }
                      return _buildClassRoutineCard(context, ref, item, isDark);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _format12Hour(String timeStr) {
    if (timeStr.isEmpty) return timeStr;
    try {
      final parts = timeStr.trim().split(':');
      if (parts.length >= 2) {
        int hour = int.parse(parts[0]);
        final minute = parts[1].padLeft(2, '0');
        final period = hour >= 12 ? 'PM' : 'AM';
        if (hour == 0) {
          hour = 12;
        } else if (hour > 12) {
          hour -= 12;
        }
        return '${hour.toString().padLeft(2, '0')}:$minute $period';
      }
    } catch (_) {}
    return timeStr;
  }

  static String? _extractSmartDate(ScheduleModel item) {
    String? rawDate = item.deadline;
    if (rawDate == null || rawDate.isEmpty) {
      final match = RegExp(r'(?:Date|Event Date):\s*([0-9]{4}-[0-9]{2}-[0-9]{2})', caseSensitive: false).firstMatch(item.notes);
      if (match != null) {
        rawDate = match.group(1);
      }
    }
    if (rawDate == null || rawDate.isEmpty) return null;

    try {
      final targetDate = DateTime.parse(rawDate);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final targetDay = DateTime(targetDate.year, targetDate.month, targetDate.day);
      final diff = targetDay.difference(today).inDays;

      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final dateStr = '${weekdays[targetDate.weekday - 1]}, ${targetDate.day} ${months[targetDate.month - 1]}';

      if (diff == 0) {
        return 'Today ($dateStr)';
      } else if (diff == 1) {
        return 'Tomorrow ($dateStr)';
      } else if (diff == -1) {
        return 'Yesterday ($dateStr)';
      } else {
        return dateStr;
      }
    } catch (_) {
      return rawDate;
    }
  }

  static bool _isToday(ScheduleModel item) {
    String? rawDate = item.deadline;
    if (rawDate == null || rawDate.isEmpty) {
      final match = RegExp(r'(?:Date|Event Date):\s*([0-9]{4}-[0-9]{2}-[0-9]{2})', caseSensitive: false).firstMatch(item.notes);
      if (match != null) rawDate = match.group(1);
    }
    if (rawDate != null && rawDate.isNotEmpty) {
      try {
        final targetDate = DateTime.parse(rawDate);
        final now = DateTime.now();
        return targetDate.year == now.year && targetDate.month == now.month && targetDate.day == now.day;
      } catch (_) {}
    }
    return false;
  }

  static bool _isTomorrow(ScheduleModel item) {
    String? rawDate = item.deadline;
    if (rawDate == null || rawDate.isEmpty) {
      final match = RegExp(r'(?:Date|Event Date):\s*([0-9]{4}-[0-9]{2}-[0-9]{2})', caseSensitive: false).firstMatch(item.notes);
      if (match != null) rawDate = match.group(1);
    }
    if (rawDate != null && rawDate.isNotEmpty) {
      try {
        final targetDate = DateTime.parse(rawDate);
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        return targetDate.year == tomorrow.year && targetDate.month == tomorrow.month && targetDate.day == tomorrow.day;
      } catch (_) {}
    }
    return false;
  }

  Widget _buildEventCard(BuildContext context, WidgetRef ref, ScheduleModel item, bool isDark) {
    final cleanTitle = item.subject.replaceFirst(RegExp(r'^\[Event\]\s*'), '');
    final timeRange = '${_format12Hour(item.startTime)} – ${_format12Hour(item.endTime)}';
    final smartDate = _extractSmartDate(item);
    final isToday = _isToday(item);
    final isTomorrow = _isTomorrow(item);

    return GlassCard(
      borderColor: AppColors.accent.withValues(alpha: 0.5),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.accent, AppColors.flame],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.stars_rounded, color: Colors.white, size: 12),
                    SizedBox(width: 4),
                    Text(
                      'CAMPUS EVENT',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, color: AppColors.success, size: 12),
                    SizedBox(width: 4),
                    Text(
                      'Going',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _confirmDelete(context, ref, item),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            cleanTitle,
            style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (smartDate != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: isToday
                        ? AppColors.flame.withValues(alpha: 0.15)
                        : (isTomorrow
                            ? AppColors.accent.withValues(alpha: 0.15)
                            : (isDark ? AppColors.surfaceDarkSubtle : AppColors.surfaceLightSubtle)),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isToday
                          ? AppColors.flame
                          : (isTomorrow
                              ? AppColors.accent
                              : (isDark ? AppColors.borderDark : AppColors.borderLight)),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_month_rounded,
                        size: 12,
                        color: isToday
                            ? AppColors.flame
                            : (isTomorrow ? AppColors.accent : AppColors.primary),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        smartDate,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isToday
                              ? AppColors.flame
                              : (isTomorrow
                                  ? AppColors.accent
                                  : (isDark ? AppColors.textDark : AppColors.textLight)),
                        ),
                      ),
                    ],
                  ),
                ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.schedule_rounded, size: 14, color: AppColors.accent),
                  const SizedBox(width: 5),
                  Text(
                    timeRange,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.accent),
                  ),
                ],
              ),
            ],
          ),
          _buildEventDetailsView(context, item, isDark, cleanTitle),
        ],
      ),
    );
  }

  Widget _buildClassRoutineCard(BuildContext context, WidgetRef ref, ScheduleModel item, bool isDark) {
    final timeRange = '${_format12Hour(item.startTime)} – ${_format12Hour(item.endTime)}';
    final todayWeekday = const ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][DateTime.now().weekday % 7];
    final isClassToday = item.days.contains(todayWeekday);

    return GlassCard(
      borderColor: AppColors.primary.withValues(alpha: 0.3),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.school_rounded, color: AppColors.primary, size: 12),
                    SizedBox(width: 4),
                    Text(
                      'CLASS ROUTINE',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (isClassToday) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.success, width: 0.8),
                  ),
                  child: const Text(
                    'TODAY',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: AppColors.success,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _confirmDelete(context, ref, item),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            item.subject,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              const Icon(Icons.access_time_rounded, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                timeRange,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                ),
              ),
            ],
          ),
          if (item.days.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              children: item.days.map((d) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDarkSubtle : AppColors.surfaceLightSubtle,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    d.substring(0, 3),
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                );
              }).toList(),
            ),
          ],
          if (item.notes.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              item.notes,
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: isDark ? AppColors.textDarkSubtle : AppColors.textLightSubtle,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEventDetailsView(BuildContext context, ScheduleModel item, bool isDark, String cleanTitle) {
    if (item.notes.isEmpty) return const SizedBox.shrink();

    String? topic;
    String? location;
    String? host;
    String? details;
    final otherLines = <String>[];

    for (final line in item.notes.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      // Filter redundant "Campus Study Event (Going)" or "(Interested)" header
      if (trimmed.toLowerCase().startsWith('campus study event')) continue;

      if (trimmed.toLowerCase().startsWith('subject / topic:')) {
        topic = trimmed.substring('subject / topic:'.length).trim();
      } else if (trimmed.toLowerCase().startsWith('location:')) {
        location = trimmed.substring('location:'.length).trim();
      } else if (trimmed.toLowerCase().startsWith('host:')) {
        host = trimmed.substring('host:'.length).trim();
      } else if (trimmed.toLowerCase().startsWith('details:')) {
        details = trimmed.substring('details:'.length).trim();
      } else {
        otherLines.add(trimmed);
      }
    }

    if (details == null && otherLines.isNotEmpty) {
      details = otherLines.join('\n');
    } else if (details != null && otherLines.isNotEmpty) {
      details = '$details\n${otherLines.join('\n')}';
    }

    // Check if location or details contains a meeting URL
    String? meetingUrl;
    final urlRegex = RegExp(r'https?://[^\s]+|(?:meet\.google\.com|zoom\.us|teams\.microsoft\.com)/[^\s]+', caseSensitive: false);
    if (location != null && urlRegex.hasMatch(location)) {
      final match = urlRegex.firstMatch(location);
      if (match != null) meetingUrl = match.group(0);
    }
    if (meetingUrl == null && details != null && urlRegex.hasMatch(details)) {
      final match = urlRegex.firstMatch(details);
      if (match != null) meetingUrl = match.group(0);
    }

    final isOnline = meetingUrl != null || (location != null && (location.toLowerCase().contains('online') || location.toLowerCase().contains('meet') || location.toLowerCase().contains('zoom')));

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
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
          if (topic != null && topic.isNotEmpty && topic.toLowerCase() != cleanTitle.toLowerCase()) ...[
            _buildEventInfoRow(
              Icons.bookmark_outline_rounded,
              'Topic',
              topic,
              isDark,
              AppColors.primary,
            ),
            const SizedBox(height: 8),
          ],
          if (location != null && location.isNotEmpty) ...[
            _buildEventInfoRow(
              isOnline ? Icons.videocam_rounded : Icons.location_on_rounded,
              'Location',
              location,
              isDark,
              isOnline ? AppColors.accent : AppColors.primary,
            ),
            if (meetingUrl != null) ...[
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _launchMeetingUrl(context, meetingUrl!),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.open_in_new_rounded, size: 14, color: AppColors.accent),
                      SizedBox(width: 6),
                      Text(
                        'Join Online Meeting',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
          ],
          if (host != null && host.isNotEmpty) ...[
            _buildEventInfoRow(
              Icons.person_rounded,
              'Host',
              host,
              isDark,
              AppColors.textDarkMuted,
            ),
            const SizedBox(height: 8),
          ],
          if (details != null && details.isNotEmpty && details != 'No extra details provided.') ...[
            _buildEventInfoRow(
              Icons.notes_rounded,
              'Details',
              details,
              isDark,
              AppColors.textDarkSubtle,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEventInfoRow(
    IconData icon,
    String label,
    String value,
    bool isDark,
    Color iconColor,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: iconColor),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textDark : AppColors.textLight,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _launchMeetingUrl(BuildContext context, String urlStr) async {
    String finalUrl = urlStr.trim();
    if (!finalUrl.startsWith('http://') && !finalUrl.startsWith('https://')) {
      finalUrl = 'https://$finalUrl';
    }
    final uri = Uri.tryParse(finalUrl);
    if (uri != null) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      } catch (_) {}
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open link: $urlStr')),
      );
    }
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, ScheduleModel item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Routine?'),
        content: Text('Remove ${item.subject} from your schedule?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      ref.read(plannerProvider.notifier).deleteSchedule(item.id);
    }
  }
}
