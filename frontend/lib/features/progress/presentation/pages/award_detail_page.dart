import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/progress_entities.dart';
import '../bloc/progress_bloc.dart';
import '../bloc/progress_event.dart';
import 'pool_selector_page.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';

class AwardDetailPage extends StatelessWidget {
  final AwardProgressEntity award;

  const AwardDetailPage({
    Key? key,
    required this.award,
  }) : super(key: key);

  void _toggleRequirementStatus(
    BuildContext context,
    RequirementProgressEntity req,
  ) async {
    if (!req.isEligible) {
      // Show age-gate ineligibility alert dialog
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

    if (req.status == 'not_started') {
      final pickedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime.now(),
        helpText: "SELECT REQUIREMENT START DATE",
      );
      if (pickedDate != null) {
        context.read<ProgressBloc>().add(
              RequirementStarted(req.id, startedAt: pickedDate),
            );
      }
    } else if (req.status == 'in_progress') {
      final pickedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: req.startedAt ?? DateTime(2000),
        lastDate: DateTime.now(),
        helpText: "SELECT REQUIREMENT COMPLETION DATE",
      );
      if (pickedDate != null) {
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
          const SizedBox(height: 24),

          // Requirement Groups List
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
                        final isInProgress = req.status == 'in_progress';

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
                              const SizedBox(height: 4),
                              if (req.startedAt != null)
                                Text(
                                  "Started: ${req.startedAt!.toLocal().toString().split(' ')[0]}",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.blue[300],
                                    fontWeight: FontWeight.bold,
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

    if (req.status == 'in_progress') {
      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.secondary, width: 2),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              color: AppColors.secondary,
              shape: BoxShape.circle,
            ),
          ),
        ),
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
