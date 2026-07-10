import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../domain/entities/progress_entities.dart';
import '../../domain/repositories/progress_repository.dart';
import '../bloc/progress_bloc.dart';
import '../bloc/progress_event.dart';
import 'pool_selector_page.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';

class AwardDetailPage extends StatefulWidget {
  final AwardProgressEntity award;

  const AwardDetailPage({
    Key? key,
    required this.award,
  }) : super(key: key);

  @override
  State<AwardDetailPage> createState() => _AwardDetailPageState();
}

class _AwardDetailPageState extends State<AwardDetailPage> {
  bool _isSaving = false;
  bool _propagateToParents = true;

  AwardProgressEntity get award => widget.award;

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _markCompleted(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'SELECT AWARD COMPLETION DATE',
    );
    if (pickedDate == null || !mounted) return;

    setState(() => _isSaving = true);
    try {
      final repo = GetIt.instance<ProgressRepository>();
      final completedIds = await repo.completeAward(
        award.id,
        completedAt: pickedDate,
        propagateToParents: _propagateToParents,
      );
      if (!mounted) return;
      // Refresh progress in bloc
      context.read<ProgressBloc>().add(ProgressFetchRequested());
      final autoCount = completedIds.length - 1;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          autoCount > 0
              ? 'Award marked complete! Also auto-completed $autoCount prerequisite(s).'
              : 'Award marked as completed on ${_formatDate(pickedDate)}.',
        ),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
        backgroundColor: AppColors.error,
      ));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _editStartDate(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: award.startedAt ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'SET AWARD START DATE',
    );
    if (pickedDate == null || !mounted) return;

    setState(() => _isSaving = true);
    try {
      final repo = GetIt.instance<ProgressRepository>();
      await repo.updateAwardDates(award.id, startedAt: pickedDate);
      if (!mounted) return;
      context.read<ProgressBloc>().add(ProgressFetchRequested());
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Start date updated to ${_formatDate(pickedDate)}.'),
        backgroundColor: Colors.blue,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
        backgroundColor: AppColors.error,
      ));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _editCompletionDate(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: award.completedAt ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'SET AWARD COMPLETION DATE',
    );
    if (pickedDate == null || !mounted) return;

    setState(() => _isSaving = true);
    try {
      final repo = GetIt.instance<ProgressRepository>();
      await repo.updateAwardDates(award.id, completedAt: pickedDate);
      if (!mounted) return;
      context.read<ProgressBloc>().add(ProgressFetchRequested());
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Completion date updated to ${_formatDate(pickedDate)}.'),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
        backgroundColor: AppColors.error,
      ));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _toggleRequirementStatus(
    BuildContext context,
    RequirementProgressEntity req,
  ) async {
    if (!req.isEligible) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.lock, color: AppColors.error),
              SizedBox(width: 10),
              Text("Requirement Locked"),
            ],
          ),
          content: Text(
            req.reasonIneligible ??
                "You do not meet the age or service requirements to attempt this task.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
      return;
    }

    if (req.status == 'completed') {
      // Prompt to reset/delete the completion status
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.help_outline, color: Colors.blue),
              SizedBox(width: 10),
              Text("Reset Progress"),
            ],
          ),
          content: const Text("Would you like to clear the completion date and reset progress for this requirement?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.read<ProgressBloc>().add(RequirementReset(req.id));
              },
              child: const Text("Reset", style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
    } else {
      // Directly ask for completion date
      final pickedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime.now(),
        helpText: "SELECT COMPLETION DATE",
      );
      if (pickedDate != null && mounted) {
        context.read<ProgressBloc>().add(
              RequirementCompleted(req.id, completedAt: pickedDate),
            );
      }
    }
  }

  void _openPoolSelector(BuildContext context, RequirementGroupProgressEntity group) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PoolSelectorPage(group: group),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          award.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Award details card
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                      child: Icon(Icons.military_tech, color: theme.colorScheme.primary, size: 36),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            award.name,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${award.percentCompleted.toInt()}% Completed",
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (award.description != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    award.description!,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ─── Date & Progress Panel ──────────────────────────────────────
          GlassCard(
            borderColor: award.isCompleted
                ? Colors.green.withAlpha(64)
                : theme.colorScheme.primary.withAlpha(51),
            child: StatefulBuilder(
              builder: (context, setLocalState) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          award.isCompleted ? Icons.check_circle : Icons.event_note,
                          color: award.isCompleted ? Colors.green : theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Date & Progress',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Start date row
                    _DateRow(
                      label: 'Started On',
                      date: award.startedAt,
                      hint: award.startDateFollowsPrereq
                          ? 'Defaults to prerequisite completion date'
                          : 'No default — set freely',
                      icon: Icons.play_arrow_rounded,
                      color: Colors.blue,
                      onTap: () => _editStartDate(context),
                      isSaving: _isSaving,
                    ),
                    const SizedBox(height: 10),

                    // Completion date row
                    _DateRow(
                      label: 'Completed On',
                      date: award.completedAt,
                      hint: 'Not yet completed',
                      icon: Icons.flag_rounded,
                      color: Colors.green,
                      onTap: () => _editCompletionDate(context),
                      isSaving: _isSaving,
                    ),

                    if (!award.isCompleted) ...[
                      const Divider(height: 28),

                      // Propagate toggle
                      Row(
                        children: [
                          Switch(
                            value: _propagateToParents,
                            onChanged: (v) => setState(() => _propagateToParents = v),
                            activeColor: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Auto-complete prerequisite awards',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Mark Complete button
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _isSaving ? null : () => _markCompleted(context),
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.check_circle_outline),
                          label: const Text('Mark Award as Completed'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: award.groups.length,
            separatorBuilder: (context, index) => const SizedBox(height: 20),
            itemBuilder: (context, index) {
              final group = award.groups[index];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Group Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              group.name,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (group.isPool)
                              Text(
                                "Select and complete at least ${group.minSelect} electives",
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (group.isPool)
                        TextButton.icon(
                          onPressed: () => _openPoolSelector(context, group),
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text("Electives"),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Requirements Checklist
                  GlassCard(
                    padding: EdgeInsets.zero,
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: group.requirements.length,
                      separatorBuilder: (context, index) => Divider(
                        color: theme.brightness == Brightness.dark
                            ? Colors.grey[800]
                            : Colors.grey[200],
                        height: 1,
                      ),
                      itemBuilder: (context, index) {
                        final req = group.requirements[index];
                        final isDone = req.status == 'completed';

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: GestureDetector(
                            onTap: () => _toggleRequirementStatus(context, req),
                            child: _buildLeadingIcon(req, theme),
                          ),
                          title: Text(
                            req.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              decoration: isDone ? TextDecoration.lineThrough : null,
                              color: isDone
                                  ? Colors.grey
                                  : (req.isEligible ? null : Colors.grey[500]),
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (req.description != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    req.description!,
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ),
                              if (req.completedAt != null)
                                Text(
                                  "Completed: ${req.completedAt!.toLocal().toString().split(' ')[0]}",
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (req.status != 'completed' && req.earliestFinishDate != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2.0),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.alarm, size: 12, color: AppColors.secondary),
                                      const SizedBox(width: 4),
                                      Text(
                                        "Earliest Finish: ${req.earliestFinishDate!.toLocal().toString().split(' ')[0]}",
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.secondary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          trailing: req.isEligible
                              ? null
                              : const Icon(Icons.lock_outline, color: Colors.grey, size: 20),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLeadingIcon(RequirementProgressEntity req, ThemeData theme) {
    if (!req.isEligible) {
      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.lock, color: Colors.grey, size: 16),
      );
    }

    if (req.status == 'completed') {
      return const Icon(
        Icons.check_circle,
        color: Colors.green,
        size: 28,
      );
    }

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[400]!, width: 2),
        shape: BoxShape.circle,
      ),
    );
  }
}
class Circle extends StatelessWidget {
  final Color color;
  final double size;

  const Circle({Key? key, required this.color, this.size = 12.0}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// A tappable row displaying a date (or placeholder) with an edit icon.
class _DateRow extends StatelessWidget {
  final String label;
  final DateTime? date;
  final String hint;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isSaving;

  const _DateRow({
    required this.label,
    required this.date,
    required this.hint,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.isSaving,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = date != null
        ? '${date!.year}-${date!.month.toString().padLeft(2, '0')}-${date!.day.toString().padLeft(2, '0')}'
        : null;

    return InkWell(
      onTap: isSaving ? null : onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    dateStr ?? hint,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: dateStr != null ? FontWeight.bold : FontWeight.normal,
                      color: dateStr != null ? color : Colors.grey[500],
                      fontStyle: dateStr == null ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.edit_calendar_outlined,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}
