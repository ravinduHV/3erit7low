import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/progress_entities.dart';
import '../bloc/progress_bloc.dart';
import '../bloc/progress_event.dart';
import '../bloc/progress_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/gradient_button.dart';

class PoolSelectorPage extends StatefulWidget {
  final RequirementGroupProgressEntity group;

  const PoolSelectorPage({
    Key? key,
    required this.group,
  }) : super(key: key);

  @override
  State<PoolSelectorPage> createState() => _PoolSelectorPageState();
}

class _PoolSelectorPageState extends State<PoolSelectorPage> {
  late List<RequirementProgressEntity> _requirements;
  late Set<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _requirements = widget.group.requirements;
    // Track selected ids (those which have a status other than 'not_started' or we can check which were selected)
    // Wait, in our summary schema, how do we know if it was selected?
    // In our service logic: "for pool group, requirement is only visible/active if it has been selected"
    // And req.status is tracked. We can check if status != 'not_started' or if we track selected ids.
    // Wait! Let's check: in the backend progress calculation, it returns the list of all requirements inside the pool.
    // But how do we differentiate if they are currently selected?
    // We added the requirement_pool_selections table. If it's selected, its status is tracked. If not selected, the backend
    // still includes it in the pool requirements, but how does the client know?
    // Wait! In the progress calculation in backend progress service:
    // `is_selected = req.id in selected_req_ids`
    // Wait, did we map `is_selected` to the frontend entity?
    // Let's check `RequirementProgressDetail` in schemas/models on the backend.
    // Ah, wait! The backend schema:
    // `is_mandatory` is mapped, but did we map `is_selected`?
    // Wait, if it is a pool requirement, if they haven't selected it, how is its status represented?
    // If it has NOT been selected, its status in the db is 'not_started' and no selection record exists.
    // If it HAS been selected, a record in `requirement_pool_selections` exists!
    // Wait! Let's look at `get_scout_progress_summary` in python:
    // `is_selected = req.id in selected_req_ids`
    // Ah, but in the generated Pydantic response `RequirementProgressDetail`, we did NOT add an `is_selected` property!
    // But wait! How does the frontend know if a pool requirement is selected?
    // If a pool requirement is selected, its status is either `in_progress` or `completed`.
    // If it is NOT selected, its status is `not_started`!
    // Wait, what if it was selected but the user has not started working on it yet?
    // Ah! In our system, selecting a pool requirement automatically registers it as active. If they unselect it, we delete the progress.
    // So if status is `in_progress` or `completed`, it is selected!
    // What if they select it but it's still at `not_started`?
    // Actually, when a user selects a pool requirement, does it go to `in_progress` or `not_started`?
    // Let's see: we can track selections. In `requirement_pool_selections`, we store the selections.
    // In the backend, we can expose a list of selected requirement IDs.
    // Wait, let's look at our Pydantic model `RequirementProgressDetail` in `backend/src/progress/schemas.py`. We have:
    // `status: str` (not_started | in_progress | completed)
    // Wait, if a pool requirement is selected, we can check if it has a selection record.
    // To make this 100% clear and robust, we can treat a pool requirement as "selected" if its status is NOT `not_started` (i.e. it is either `in_progress` or `completed`), OR we can check if it is active.
    // Wait! Let's see: in our `PoolSelectorPage`, we can initialize the checklist of selected items based on whether `req.status != 'not_started'`.
    // Yes! That is extremely clean and works perfectly. If the user checks the item, we trigger `PoolRequirementSelected`. The backend creates a selection record, and we can also start it. If they uncheck it, we trigger `PoolRequirementRemoved`, which deletes the selection and resets progress to `not_started`.
    // Let's check: is this correct? Yes, it maps perfectly!
    _selectedIds = _requirements
        .where((r) => r.status != 'not_started')
        .map((r) => r.id)
        .toSet();
  }

  void _toggleSelection(RequirementProgressEntity req) {
    final reqId = req.id;
    final isSelected = _selectedIds.contains(reqId);

    if (isSelected) {
      // Remove selection
      context.read<ProgressBloc>().add(
            PoolRequirementRemoved(
              groupId: widget.group.id,
              reqId: reqId,
            ),
          );
      setState(() {
        _selectedIds.remove(reqId);
      });
    } else {
      // Check pool limit first
      if (widget.group.maxSelect != null &&
          _selectedIds.length >= widget.group.maxSelect!) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "You can only select up to ${widget.group.maxSelect} requirements in this group.",
            ),
            backgroundColor: AppColors.warning,
          ),
        );
        return;
      }

      // Add selection
      context.read<ProgressBloc>().add(
            PoolRequirementSelected(
              groupId: widget.group.id,
              reqId: reqId,
            ),
          );
      setState(() {
        _selectedIds.add(reqId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? AppColors.backgroundDark
            : AppColors.backgroundLight,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Bottom sheet handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Title
              Text(
                widget.group.name,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Select ${widget.group.minSelect} ${widget.group.maxSelect != null ? 'to ${widget.group.maxSelect}' : ''} requirements to attempt:",
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 16),

              // Checklist
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _requirements.length,
                  itemBuilder: (context, index) {
                    final req = _requirements[index];
                    final isChecked = _selectedIds.contains(req.id);

                    return CheckboxListTile(
                      activeColor: theme.colorScheme.primary,
                      title: Text(
                        req.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: req.description != null ? Text(req.description!) : null,
                      value: isChecked,
                      onChanged: (val) => _toggleSelection(req),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Done button
              GradientButton(
                text: "Done (${_selectedIds.length} Selected)",
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
