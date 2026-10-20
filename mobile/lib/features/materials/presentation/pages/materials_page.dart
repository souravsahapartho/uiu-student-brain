import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/data/courses_catalog.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_card.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/responsive.dart';
import '../../../../core/widgets/student_brain_loader.dart';
import '../providers/materials_provider.dart';

class MaterialsPage extends ConsumerStatefulWidget {
  const MaterialsPage({super.key});

  static const List<String> categories = [
    'All',
    'Bookmarked',
    'Lecture Note',
    'Cheat Sheet',
    'Textbook Chapter',
    'Lab Report',
  ];

  @override
  ConsumerState<MaterialsPage> createState() => _MaterialsPageState();
}

class _MaterialsPageState extends ConsumerState<MaterialsPage> with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.02),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matState = ref.watch(materialsProvider);
    final notifier = ref.read(materialsProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Materials & Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => notifier.loadMaterialsData(),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: RefreshIndicator(
            onRefresh: () => notifier.loadMaterialsData(),
            color: AppColors.primary,
            child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: Responsive.padding(context),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: Responsive.maxContentWidth(context)),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Search Bar
                  TextField(
                    onChanged: (val) => notifier.setSearchQuery(val),
                    decoration: InputDecoration(
                      hintText: 'Search lecture notes, topics, formulas...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: matState.searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () => notifier.setSearchQuery(''),
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(9999),
                        borderSide: BorderSide(
                          color: isDark ? AppColors.borderDark : AppColors.borderLight,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 2. Category Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: MaterialsPage.categories.map((cat) {
                        final isSelected = matState.selectedCategory == cat;
                        final isBookmarkCat = cat == 'Bookmarked';
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: FilterChip(
                            avatar: isBookmarkCat
                                ? Icon(
                                    Icons.bookmark_rounded,
                                    size: 14,
                                    color: isSelected ? AppColors.primary : Colors.amber[600],
                                  )
                                : null,
                            label: Text(
                              isBookmarkCat ? (matState.materials.where((m) => matState.bookmarkedIds.contains(m.id.toString())).isNotEmpty ? 'Bookmarked (${matState.materials.where((m) => matState.bookmarkedIds.contains(m.id.toString())).length})' : 'Bookmarked') : cat,
                            ),
                            selected: isSelected,
                            onSelected: (_) => notifier.selectCategory(cat),
                            selectedColor: AppColors.primary.withValues(alpha: 0.2),
                            checkmarkColor: AppColors.primary,
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected
                                  ? AppColors.primary
                                  : (isDark ? AppColors.textDarkMuted : AppColors.textLightMuted),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 3. Trimesters & Enrolled Courses Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Trimester Courses & AI Copilots',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton.icon(
                            onPressed: () => _showAddSemesterDialog(context, ref),
                            icon: const Icon(Icons.add_rounded, size: 16),
                            label: const Text('Trimester', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => _showAddCourseDialog(context, ref, matState.semesters),
                            icon: const Icon(Icons.add_rounded, size: 16),
                            label: const Text('Course', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.accent,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Trimester Pills Filter (Compact, Modern, Responsive)
                  if (matState.semesters.isNotEmpty)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          InkWell(
                            onTap: () => notifier.selectSemester(null),
                            borderRadius: BorderRadius.circular(10),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                              decoration: BoxDecoration(
                                color: matState.selectedSemesterId == null
                                    ? AppColors.primary.withValues(alpha: 0.16)
                                    : (isDark ? AppColors.surfaceDarkSubtle : AppColors.surfaceLightSubtle),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: matState.selectedSemesterId == null
                                      ? AppColors.primary
                                      : (isDark ? AppColors.borderDark : AppColors.borderLight),
                                  width: matState.selectedSemesterId == null ? 1.4 : 1.0,
                                ),
                              ),
                              child: Text(
                                'All Terms',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: matState.selectedSemesterId == null ? FontWeight.w800 : FontWeight.w600,
                                  color: matState.selectedSemesterId == null
                                      ? AppColors.primary
                                      : (isDark ? AppColors.textDarkMuted : AppColors.textLightMuted),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          ...matState.semesters.map((sem) {
                            final semId = sem['id'] as int?;
                            final semName = sem['name']?.toString() ?? 'Term';
                            final isCurrent = sem['is_current'] == true;
                            final isSelected = matState.selectedSemesterId == semId;

                            return Container(
                              margin: const EdgeInsets.only(right: 6),
                              child: InkWell(
                                onTap: () => notifier.selectSemester(semId),
                                borderRadius: BorderRadius.circular(10),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.only(left: 9, right: 3, top: 4, bottom: 4),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary.withValues(alpha: 0.16)
                                        : (isDark ? AppColors.surfaceDarkSubtle : AppColors.surfaceLightSubtle),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primary
                                          : (isDark ? AppColors.borderDark : AppColors.borderLight),
                                      width: isSelected ? 1.4 : 1.0,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (isCurrent) ...[
                                        const Icon(Icons.star_rounded, size: 13, color: AppColors.warning),
                                        const SizedBox(width: 3),
                                      ],
                                      Text(
                                        semName,
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                          color: isSelected
                                              ? AppColors.primary
                                              : (isDark ? AppColors.textDark : AppColors.textLight),
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: PopupMenuButton<String>(
                                          icon: Icon(
                                            Icons.more_vert_rounded,
                                            size: 13.5,
                                            color: isSelected
                                                ? AppColors.primary
                                                : (isDark ? AppColors.textDarkMuted : AppColors.textLightMuted),
                                          ),
                                          padding: EdgeInsets.zero,
                                          splashRadius: 10,
                                          constraints: const BoxConstraints(),
                                          onSelected: (val) {
                                            if (val == 'edit') {
                                              _showEditSemesterDialog(context, ref, sem);
                                            } else if (val == 'toggle') {
                                              ref.read(materialsProvider.notifier).updateSemester(semId!, isCurrent: !isCurrent);
                                            } else if (val == 'delete') {
                                              _confirmDeleteSemester(context, ref, sem);
                                            }
                                          },
                                          itemBuilder: (ctx) => [
                                            const PopupMenuItem(
                                              value: 'edit',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.edit_outlined, size: 16),
                                                  SizedBox(width: 8),
                                                  Text('Edit Trimester', style: TextStyle(fontSize: 13)),
                                                ],
                                              ),
                                            ),
                                            PopupMenuItem(
                                              value: 'toggle',
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    isCurrent ? Icons.star_border_rounded : Icons.star_rounded,
                                                    size: 16,
                                                    color: AppColors.warning,
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    isCurrent ? 'Unmark Active' : 'Set as Active',
                                                    style: const TextStyle(fontSize: 13),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const PopupMenuItem(
                                              value: 'delete',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.error),
                                                  SizedBox(width: 8),
                                                  Text('Delete Trimester', style: TextStyle(fontSize: 13, color: AppColors.error)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  const SizedBox(height: 10),

                  if (matState.semesterCourses.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDarkSubtle : AppColors.surfaceLightSubtle,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? AppColors.borderDark : AppColors.borderLight,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.school_outlined, size: 28, color: AppColors.primary),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'No Courses in this Trimester',
                            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Add your enrolled courses to link lecture notes, cheat sheets, and AI copilots.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                            ),
                          ),
                          const SizedBox(height: 14),
                          ElevatedButton.icon(
                            onPressed: () => _showAddCourseDialog(
                              context,
                              ref,
                              matState.semesters,
                              initialSemesterId: matState.selectedSemesterId,
                            ),
                            icon: const Icon(Icons.add_rounded, size: 16),
                            label: const Text('Add Course', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (matState.semesterCourses.length == 1)
                    _buildCourseCard(
                      context,
                      ref,
                      matState.semesterCourses.first,
                      matState,
                      notifier,
                      isDark,
                      isFullWidth: true,
                    )
                  else
                    SizedBox(
                      height: 122,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: matState.semesterCourses.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          return _buildCourseCard(
                            context,
                            ref,
                            matState.semesterCourses[index],
                            matState,
                            notifier,
                            isDark,
                            isFullWidth: false,
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 12),

                  // 4. Materials List Header with Filter Clear Option & Upload Material Button
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.menu_book_rounded, size: 16, color: AppColors.primary),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Course Documents & Cheat Sheets',
                          style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.upload_file_rounded, size: 13),
                        label: const Text('Upload', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        onPressed: () => _showUploadMaterialDialog(context, ref),
                      ),
                      if (matState.selectedCourseId != null) ...[
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () => notifier.selectCourse(null),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.close_rounded, size: 11, color: AppColors.error),
                                SizedBox(width: 3),
                                Text(
                                  'Clear',
                                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.error),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (matState.isLoading && matState.materials.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 36),
                      child: StudentBrainLoader(
                        message: 'Loading UIU study materials & notes...',
                      ),
                    )
                  else if (matState.error != null)
                    ErrorCard(
                      message: matState.error!,
                      onRetry: () => notifier.loadMaterialsData(),
                    )
                  else if (matState.filteredMaterials.isEmpty)
                    EmptyState(
                      icon: matState.selectedCategory == 'Bookmarked'
                          ? Icons.bookmark_border_rounded
                          : Icons.folder_open_outlined,
                      title: matState.selectedCategory == 'Bookmarked'
                          ? 'No Bookmarked Materials Yet'
                          : 'No Materials Found',
                      subtitle: matState.selectedCategory == 'Bookmarked'
                          ? 'Tap the bookmark icon on any course material or syllabus note to save it here for quick exam revision.'
                          : 'Try changing your search keywords or filter category.',
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: matState.filteredMaterials.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = matState.filteredMaterials[index];
                        final isBookmarked = matState.bookmarkedIds.contains(item.id.toString());

                        return GlassCard(
                          onTap: () {
                            context.push('/materials/${item.id}');
                          },
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.description_outlined,
                                        color: AppColors.primary,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.title,
                                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  '${item.category} • ${item.difficultyLevel} • ${item.estimatedReadingTime}m read',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          constraints: const BoxConstraints(),
                                          padding: const EdgeInsets.all(5),
                                          icon: Icon(
                                            isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                                            size: 19,
                                            color: isBookmarked ? AppColors.accent : (isDark ? AppColors.textDarkMuted : AppColors.textLightMuted),
                                          ),
                                          tooltip: isBookmarked ? 'Remove Bookmark' : 'Save Bookmark',
                                          onPressed: () async {
                                            final nowBookmarked = await notifier.toggleBookmark(item.id);
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    nowBookmarked
                                                        ? 'Saved "${item.title}" to Bookmarks'
                                                        : 'Removed from Bookmarks',
                                                  ),
                                                  duration: const Duration(seconds: 1),
                                                  behavior: SnackBarBehavior.floating,
                                                ),
                                              );
                                            }
                                          },
                                        ),
                                        const SizedBox(width: 2),
                                        IconButton(
                                          constraints: const BoxConstraints(),
                                          padding: const EdgeInsets.all(5),
                                          icon: Icon(
                                            Icons.delete_outline_rounded,
                                            size: 18,
                                            color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                                          ),
                                          tooltip: 'Delete Material',
                                          onPressed: () => _confirmDeleteMaterial(context, ref, item),
                                        ),
                                        const SizedBox(width: 2),
                                        const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.primary),
                                      ],
                                    ),
                                  ],
                                ),
                              if (item.summary.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Text(
                                  item.summary,
                                  style: TextStyle(
                                    fontSize: 12,
                                    height: 1.35,
                                    color: isDark ? AppColors.textDarkSubtle : AppColors.textLightSubtle,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
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
      ),
    ),
  ),
);
  }

  void _showAddSemesterDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController(text: 'Fall ${DateTime.now().year}');
    bool isCurrent = true;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 22),
                SizedBox(width: 8),
                Text('Add Academic Trimester', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Trimester / Semester Name *',
                      hintText: 'e.g. Fall 2026, Spring 2027',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Current Active Trimester', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    subtitle: const Text('Set as your primary enrolled term', style: TextStyle(fontSize: 11)),
                    value: isCurrent,
                    contentPadding: EdgeInsets.zero,
                    activeTrackColor: AppColors.primary,
                    onChanged: (val) => setDialogState(() => isCurrent = val),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final name = nameCtrl.text.trim();
                        if (name.isEmpty) return;

                        setDialogState(() => isSubmitting = true);
                        final success = await ref
                            .read(materialsProvider.notifier)
                            .createSemester(name, isCurrent);

                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(success ? 'Trimester created successfully!' : 'Failed to create trimester'),
                              backgroundColor: success ? AppColors.success : AppColors.error,
                            ),
                          );
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Create Trimester', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddCourseDialog(BuildContext context, WidgetRef ref, List<Map<String, dynamic>> semesters, {int? initialSemesterId}) {
    if (semesters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please create a Trimester / Semester first!'),
          backgroundColor: AppColors.accent,
        ),
      );
      _showAddSemesterDialog(context, ref);
      return;
    }

    int selectedSemesterId = initialSemesterId ?? (semesters.first['id'] as int? ?? 1);
    if (!semesters.any((s) => s['id'] == selectedSemesterId)) {
      selectedSemesterId = semesters.first['id'] as int? ?? 1;
    }
    final codeCtrl = TextEditingController();
    final titleCtrl = TextEditingController();
    String selectedColor = '#2563eb';
    bool isSubmitting = false;
    List<CatalogCourse> courseSuggestions = [];

    final colorOptions = [
      {'hex': '#2563eb', 'name': 'Blue'},
      {'hex': '#10b981', 'name': 'Green'},
      {'hex': '#8b5cf6', 'name': 'Purple'},
      {'hex': '#f59e0b', 'name': 'Amber'},
      {'hex': '#ef4444', 'name': 'Crimson'},
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.85,
                maxWidth: 500,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Pinned Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 16, 14),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.school_rounded, color: AppColors.primary, size: 22),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Add Course to Trimester',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, thickness: 1),
                  // Scrollable Body
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          DropdownButtonFormField<int>(
                            initialValue: selectedSemesterId,
                            decoration: InputDecoration(
                              labelText: 'Select Trimester',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            items: semesters.map((s) {
                              final id = s['id'] as int;
                              final name = s['name']?.toString() ?? 'Semester';
                              final isCur = s['is_current'] == true;
                              return DropdownMenuItem(
                                value: id,
                                child: Text(isCur ? '$name (Current)' : name),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setDialogState(() => selectedSemesterId = val);
                            },
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: codeCtrl,
                            decoration: InputDecoration(
                              labelText: 'Course Code *',
                              hintText: 'e.g. CSE 4123, MATH 2183',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onChanged: (val) {
                              setDialogState(() {
                                courseSuggestions = searchCoursesCatalog(val);
                              });
                            },
                          ),
                          if (courseSuggestions.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: courseSuggestions.take(4).map((c) {
                                return ActionChip(
                                  avatar: const Icon(Icons.school, size: 14, color: AppColors.primary),
                                  label: Text('${c.code} (${c.title})', style: const TextStyle(fontSize: 11)),
                                  onPressed: () {
                                    setDialogState(() {
                                      codeCtrl.text = c.code;
                                      titleCtrl.text = c.title;
                                      courseSuggestions = [];
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                          const SizedBox(height: 12),
                          TextField(
                            controller: titleCtrl,
                            decoration: InputDecoration(
                              labelText: 'Course Title *',
                              hintText: 'e.g. Distributed Computing',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text('Course Theme Color', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: colorOptions.map((opt) {
                              final hex = opt['hex']!;
                              final color = Color(int.parse(hex.replaceFirst('#', '0xFF')));
                              final isSelected = selectedColor == hex;

                              return GestureDetector(
                                onTap: () => setDialogState(() => selectedColor = hex),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected ? Colors.white : Colors.transparent,
                                      width: 2.5,
                                    ),
                                  ),
                                  child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 1, thickness: 1),
                  // Pinned Bottom Action Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: isSubmitting
                                ? null
                                : () async {
                                    final code = codeCtrl.text.trim();
                                    final title = titleCtrl.text.trim();
                                    if (code.isEmpty || title.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Course code and title are required')),
                                      );
                                      return;
                                    }

                                    setDialogState(() => isSubmitting = true);
                                    final success = await ref.read(materialsProvider.notifier).createCourse(
                                          semesterId: selectedSemesterId,
                                          title: title,
                                          code: code,
                                          color: selectedColor,
                                        );

                                    if (ctx.mounted) {
                                      Navigator.pop(ctx);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(success ? 'Course added successfully!' : 'Failed to add course'),
                                          backgroundColor: success ? AppColors.success : AppColors.error,
                                        ),
                                      );
                                    }
                                  },
                            child: isSubmitting
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Add Course', style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCourseCard(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> c,
    MaterialsState matState,
    MaterialsNotifier notifier,
    bool isDark, {
    required bool isFullWidth,
  }) {
    final courseId = c['id'] as int? ?? 1;
    final code = c['code']?.toString() ?? 'CSE';
    final title = c['title']?.toString() ?? 'Course';
    final semName = c['semester_name']?.toString();
    final isSelected = matState.selectedCourseId == courseId;

    return InkWell(
      onTap: () => notifier.selectCourse(courseId),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: isFullWidth ? double.infinity : 240,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.08)
              : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: isFullWidth ? MainAxisSize.min : MainAxisSize.max,
          mainAxisAlignment: isFullWidth ? MainAxisAlignment.start : MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        code,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: isSelected ? Colors.white : AppColors.primary,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_rounded, size: 10, color: AppColors.primary),
                                SizedBox(width: 3),
                                Text(
                                  'Filtered',
                                  style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: AppColors.primary),
                                ),
                              ],
                            ),
                          )
                        else if (semName != null && semName.isNotEmpty)
                          Text(
                            semName,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(width: 4),
                        PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_vert_rounded,
                            size: 16,
                            color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined, size: 16),
                                  SizedBox(width: 8),
                                  Text('Edit Course', style: TextStyle(fontSize: 13)),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.error),
                                  SizedBox(width: 8),
                                  Text('Delete Course', style: TextStyle(fontSize: 13, color: AppColors.error)),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (val) {
                            if (val == 'edit') {
                              _showEditCourseDialog(context, ref, c);
                            } else if (val == 'delete') {
                              _confirmDeleteCourse(context, ref, c);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            if (isFullWidth) const SizedBox(height: 10),
            Row(
              children: [
                InkWell(
                  onTap: () => _showUploadMaterialDialog(context, ref, initialCourseId: courseId),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded, size: 12, color: AppColors.primary),
                        SizedBox(width: 3),
                        Text(
                          'Material',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    context.push('/ai/chat/$courseId?title=$code - $title');
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome_rounded, size: 12, color: AppColors.primary),
                        SizedBox(width: 4),
                        Text(
                          'Course AI',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditSemesterDialog(BuildContext context, WidgetRef ref, Map<String, dynamic> sem) {
    final semId = sem['id'] as int;
    final nameCtrl = TextEditingController(text: sem['name']?.toString() ?? '');
    bool isCurrent = sem['is_current'] == true;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('Edit Trimester', style: TextStyle(fontWeight: FontWeight.w800)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Trimester Name',
                  hintText: 'e.g. Fall 2027, Spring 2028',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Set as Active / Current', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                value: isCurrent,
                onChanged: (val) => setDialogState(() => isCurrent = val),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final name = nameCtrl.text.trim();
                      if (name.isEmpty) return;
                      setDialogState(() => isSubmitting = true);
                      final success = await ref.read(materialsProvider.notifier).updateSemester(
                            semId,
                            name: name,
                            isCurrent: isCurrent,
                          );
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success ? 'Trimester updated' : 'Failed to update trimester'),
                            backgroundColor: success ? AppColors.success : AppColors.error,
                          ),
                        );
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteSemester(BuildContext context, WidgetRef ref, Map<String, dynamic> sem) {
    final semId = sem['id'] as int;
    final semName = sem['name']?.toString() ?? 'Trimester';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Trimester'),
        content: Text('Are you sure you want to delete "$semName"? All associated courses and study materials will also be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ref.read(materialsProvider.notifier).deleteSemester(semId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Trimester deleted' : 'Failed to delete trimester'),
                    backgroundColor: success ? AppColors.success : AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showEditCourseDialog(BuildContext context, WidgetRef ref, Map<String, dynamic> course) {
    final courseId = course['id'] as int;
    final codeCtrl = TextEditingController(text: course['code']?.toString() ?? '');
    final titleCtrl = TextEditingController(text: course['title']?.toString() ?? '');
    final descCtrl = TextEditingController(text: course['description']?.toString() ?? '');
    String selectedColor = course['color']?.toString() ?? '#2563eb';
    bool isSubmitting = false;

    final colorOptions = [
      {'hex': '#2563eb', 'name': 'Blue'},
      {'hex': '#7c3aed', 'name': 'Purple'},
      {'hex': '#059669', 'name': 'Emerald'},
      {'hex': '#d97706', 'name': 'Amber'},
      {'hex': '#dc2626', 'name': 'Red'},
      {'hex': '#0891b2', 'name': 'Cyan'},
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('Edit Course', style: TextStyle(fontWeight: FontWeight.w800)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: codeCtrl,
                  decoration: InputDecoration(
                    labelText: 'Course Code *',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    labelText: 'Course Title *',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: InputDecoration(
                    labelText: 'Description (Optional)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Course Theme Color', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: colorOptions.map((opt) {
                    final hex = opt['hex']!;
                    final color = Color(int.parse(hex.replaceFirst('#', '0xFF')));
                    final isSelected = selectedColor == hex;

                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedColor = hex),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.transparent,
                            width: 2.5,
                          ),
                        ),
                        child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final code = codeCtrl.text.trim();
                      final title = titleCtrl.text.trim();
                      if (code.isEmpty || title.isEmpty) return;

                      setDialogState(() => isSubmitting = true);
                      final success = await ref.read(materialsProvider.notifier).updateCourse(
                            courseId,
                            title: title,
                            code: code,
                            color: selectedColor,
                            description: descCtrl.text.trim(),
                          );
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success ? 'Course updated' : 'Failed to update course'),
                            backgroundColor: success ? AppColors.success : AppColors.error,
                          ),
                        );
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteCourse(BuildContext context, WidgetRef ref, Map<String, dynamic> course) {
    final courseId = course['id'] as int;
    final courseTitle = course['title']?.toString() ?? 'Course';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Course'),
        content: Text('Are you sure you want to delete "$courseTitle"? All study materials inside this course will also be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ref.read(materialsProvider.notifier).deleteCourse(courseId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Course deleted' : 'Failed to delete course'),
                    backgroundColor: success ? AppColors.success : AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteMaterial(BuildContext context, WidgetRef ref, dynamic item) {
    final materialId = item.id as int;
    final title = item.title as String;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Material'),
        content: Text('Delete "$title"? This document will be removed from your device library.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ref.read(materialsProvider.notifier).deleteMaterial(materialId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Document removed from library' : 'Failed to delete document'),
                    backgroundColor: success ? AppColors.success : AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showUploadMaterialDialog(BuildContext context, WidgetRef ref, {int? initialCourseId}) {
    final matState = ref.read(materialsProvider);
    final semesters = matState.semesters;

    int? selectedCourseId = initialCourseId;
    int? selectedSemesterId;

    if (initialCourseId != null) {
      final foundCourse = matState.courses.firstWhere(
        (c) => c['id'] == initialCourseId,
        orElse: () => <String, dynamic>{},
      );
      if (foundCourse.isNotEmpty) {
        selectedSemesterId = foundCourse['semester'] as int? ?? foundCourse['semester_id'] as int?;
      }
    }

    selectedSemesterId ??= matState.selectedSemesterId ?? (semesters.isNotEmpty ? semesters.first['id'] as int? : null);

    List<Map<String, dynamic>> availableCourses = selectedSemesterId != null
        ? matState.courses.where((c) => c['semester'] == selectedSemesterId || c['semester_id'] == selectedSemesterId).toList()
        : matState.courses;

    if (selectedCourseId == null || !availableCourses.any((c) => c['id'] == selectedCourseId)) {
      selectedCourseId = availableCourses.isNotEmpty ? (availableCourses.first['id'] as int?) : null;
    }

    final titleCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String category = 'Lecture Note';
    PlatformFile? pickedFile;
    bool isSubmitting = false;
    List<CatalogCourse> courseSuggestions = [];

    const categoriesList = [
      'Lecture Note',
      'Cheat Sheet',
      'Textbook Chapter',
      'Lab Report',
      'Other',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.85,
                maxWidth: 500,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Pinned Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 16, 14),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.cloud_upload_rounded, color: AppColors.primary, size: 22),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Upload Study Document',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, thickness: 1),
                  // Scrollable Body
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Trimester selector
                          DropdownButtonFormField<int>(
                            initialValue: selectedSemesterId,
                            decoration: InputDecoration(
                              labelText: 'Select Trimester *',
                              prefixIcon: const Icon(Icons.calendar_today_rounded, size: 18),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            items: semesters.map((s) {
                              final id = s['id'] as int;
                              final name = s['name']?.toString() ?? 'Trimester $id';
                              final isCur = s['is_current'] == true;
                              return DropdownMenuItem(
                                value: id,
                                child: Text(isCur ? '$name (Active)' : name),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setDialogState(() {
                                  selectedSemesterId = val;
                                  availableCourses = matState.courses
                                      .where((c) => c['semester'] == val || c['semester_id'] == val)
                                      .toList();
                                  selectedCourseId = availableCourses.isNotEmpty ? (availableCourses.first['id'] as int) : null;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 12),

                          // Course Selector (Strictly filtered by selected trimester)
                          DropdownButtonFormField<int?>(
                            initialValue: selectedCourseId,
                            decoration: InputDecoration(
                              labelText: 'Select Course *',
                              prefixIcon: const Icon(Icons.school_outlined, size: 18),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            items: availableCourses.isEmpty
                                ? [
                                    const DropdownMenuItem<int?>(
                                      value: null,
                                      enabled: false,
                                      child: Text('No courses in this trimester (Add Course first)', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                    ),
                                  ]
                                : availableCourses.map((c) {
                                    final id = c['id'] as int;
                                    final code = c['code']?.toString() ?? '';
                                    final title = c['title']?.toString() ?? 'Course';
                                    return DropdownMenuItem<int?>(
                                      value: id,
                                      child: Text('[$code] $title', style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                                    );
                                  }).toList(),
                            onChanged: availableCourses.isEmpty
                                ? null
                                : (val) {
                                    if (val != null) setDialogState(() => selectedCourseId = val);
                                  },
                          ),
                          const SizedBox(height: 12),

                          // Material Title with Autocomplete from catalog
                          TextField(
                            controller: titleCtrl,
                            decoration: InputDecoration(
                              labelText: 'Document Title *',
                              hintText: 'e.g. Midterm Cheat Sheet & Formulas',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            onChanged: (val) {
                              setDialogState(() {
                                courseSuggestions = searchCoursesCatalog(val);
                              });
                            },
                          ),
                          if (courseSuggestions.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: courseSuggestions.take(4).map((c) {
                                return ActionChip(
                                  avatar: const Icon(Icons.school, size: 14, color: AppColors.primary),
                                  label: Text('${c.code} (${c.title})', style: const TextStyle(fontSize: 11)),
                                  onPressed: () {
                                    setDialogState(() {
                                      titleCtrl.text = '${c.code} - ${c.title} Lecture Notes';
                                      courseSuggestions = [];
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                          const SizedBox(height: 12),

                          // Category Selector
                          DropdownButtonFormField<String>(
                            initialValue: category,
                            decoration: InputDecoration(
                              labelText: 'Document Category',
                              prefixIcon: const Icon(Icons.category_outlined, size: 18),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            items: categoriesList.map((cat) => DropdownMenuItem(value: cat, child: Text(cat, style: const TextStyle(fontSize: 13)))).toList(),
                            onChanged: (val) {
                              if (val != null) setDialogState(() => category = val);
                            },
                          ),
                          const SizedBox(height: 14),

                          // File Picker Area
                          const Text('Attach File (PDF, CSV, Image, TXT, DOCX)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          if (pickedFile == null)
                            InkWell(
                              onTap: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                try {
                                  final result = await FilePicker.platform.pickFiles(
                                    type: FileType.any,
                                    allowMultiple: false,
                                  );
                                  if (result != null && result.files.isNotEmpty) {
                                    setDialogState(() {
                                      pickedFile = result.files.first;
                                      if (titleCtrl.text.isEmpty) {
                                        final nameWithoutExt = pickedFile!.name.split('.').first;
                                        titleCtrl.text = nameWithoutExt.replaceAll(RegExp(r'[_\-]'), ' ');
                                      }
                                    });
                                  }
                                } catch (e) {
                                  messenger.showSnackBar(
                                    SnackBar(content: Text('File picker error: $e')),
                                  );
                                }
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.surfaceDarkSubtle : AppColors.surfaceLightSubtle,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.primary.withValues(alpha: 0.35),
                                    style: BorderStyle.solid,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    const Icon(Icons.cloud_upload_outlined, color: AppColors.primary, size: 30),
                                    const SizedBox(height: 6),
                                    const Text(
                                      'Tap to select document from device',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'PDF, CSV, Image, TXT, DOCX supported',
                                      style: TextStyle(fontSize: 10.5, color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.insert_drive_file_rounded, color: AppColors.primary, size: 24),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          pickedFile!.name,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          '${(pickedFile!.size / 1024).toStringAsFixed(1)} KB',
                                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close_rounded, size: 18),
                                    onPressed: () => setDialogState(() => pickedFile = null),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 12),

                          // Notes / Description
                          TextField(
                            controller: notesCtrl,
                            maxLines: 3,
                            decoration: InputDecoration(
                              labelText: 'Notes / Topic Overview (Optional)',
                              hintText: 'Chapters, formulas, or key insights covered...',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.all(12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 1, thickness: 1),
                  // Pinned Bottom Action Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: isSubmitting
                                ? null
                                : () async {
                                    if (selectedCourseId == null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Please select or add a course first')),
                                      );
                                      return;
                                    }
                                    if (titleCtrl.text.trim().isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Please enter a document title')),
                                      );
                                      return;
                                    }

                                    setDialogState(() => isSubmitting = true);
                                    final messenger = ScaffoldMessenger.of(context);

                                    final success = await ref.read(materialsProvider.notifier).createMaterial(
                                          courseId: selectedCourseId!,
                                          title: titleCtrl.text.trim(),
                                          category: category,
                                          filePath: pickedFile?.path,
                                          fileName: pickedFile?.name,
                                          contentText: notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null,
                                        );

                                    if (ctx.mounted) {
                                      Navigator.pop(ctx);
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(success
                                              ? 'Study document uploaded and saved locally to device!'
                                              : 'Could not upload document'),
                                          backgroundColor: success ? AppColors.success : AppColors.error,
                                        ),
                                      );
                                    }
                                  },
                            child: isSubmitting
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Save Material', style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
