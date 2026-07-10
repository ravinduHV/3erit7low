import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';

class AdminSectionAwardsPage extends StatefulWidget {
  final String sectionId;
  final String sectionName;

  const AdminSectionAwardsPage({
    Key? key,
    required this.sectionId,
    required this.sectionName,
  }) : super(key: key);

  @override
  State<AdminSectionAwardsPage> createState() => _AdminSectionAwardsPageState();
}

class _AdminSectionAwardsPageState extends State<AdminSectionAwardsPage> {
  final _dio = GetIt.instance<Dio>();
  List<dynamic> _awards = [];
  bool _isLoading = true;
  String? _error;

  // Track expanded awards/groups for dynamic loading
  final Map<String, List<dynamic>> _groupsCache = {};
  final Map<String, List<dynamic>> _requirementsCache = {};
  final Map<String, bool> _loadingGroups = {};
  final Map<String, bool> _loadingRequirements = {};

  @override
  void initState() {
    super.initState();
    _loadAwards();
  }

  Future<void> _loadAwards() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final response = await _dio.get(
        '${AppConstants.apiBaseUrl}/v1/admin/sections/${widget.sectionId}/awards',
      );
      setState(() {
        _awards = response.data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Error loading awards: ${e.toString()}";
        _isLoading = false;
      });
    }
  }

  // ─── GROUPS DATA LOADING ──────────────────────────────────────────────────
  Future<void> _loadGroups(String awardId) async {
    if (_loadingGroups[awardId] == true) return;
    try {
      setState(() => _loadingGroups[awardId] = true);
      final response = await _dio.get(
        '${AppConstants.apiBaseUrl}/v1/admin/awards/$awardId/groups',
      );
      setState(() {
        _groupsCache[awardId] = response.data;
        _loadingGroups[awardId] = false;
      });
    } catch (e) {
      setState(() => _loadingGroups[awardId] = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading groups: ${e.toString()}")),
      );
    }
  }

  // ─── REQUIREMENTS DATA LOADING ────────────────────────────────────────────
  Future<void> _loadRequirements(String groupId) async {
    if (_loadingRequirements[groupId] == true) return;
    try {
      setState(() => _loadingRequirements[groupId] = true);
      final response = await _dio.get(
        '${AppConstants.apiBaseUrl}/v1/admin/groups/$groupId/requirements',
      );
      setState(() {
        _requirementsCache[groupId] = response.data;
        _loadingRequirements[groupId] = false;
      });
    } catch (e) {
      setState(() => _loadingRequirements[groupId] = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading requirements: ${e.toString()}")),
      );
    }
  }

  // ─── AWARDS CRUD ──────────────────────────────────────────────────────────
  Future<void> _deleteAward(String id) async {
    try {
      await _dio.delete('${AppConstants.apiBaseUrl}/v1/admin/awards/$id');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Award deleted successfully")),
      );
      _loadAwards();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Delete failed: ${e.toString()}")),
      );
    }
  }

  Future<void> _showAddAwardDialog() async {
    final idController = TextEditingController();
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final imageController = TextEditingController(text: "assets/badges/default.png");
    final minAgeController = TextEditingController();
    final maxAgeController = TextEditingController();
    final minServiceController = TextEditingController();
    final displayOrderController = TextEditingController(text: "1");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Progressive Award"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: idController,
                decoration: const InputDecoration(labelText: "Award ID (e.g. jr_membership)"),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Award Name"),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: "Description"),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: imageController,
                decoration: const InputDecoration(labelText: "Badge Asset Image Path"),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: minAgeController,
                decoration: const InputDecoration(labelText: "Minimum Age Gate"),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: maxAgeController,
                decoration: const InputDecoration(labelText: "Maximum Age Gate"),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: minServiceController,
                decoration: const InputDecoration(labelText: "Min Service Period (Months)"),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: displayOrderController,
                decoration: const InputDecoration(labelText: "Display Order"),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (idController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Award ID cannot be empty")),
                );
                return;
              }
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Award Name cannot be empty")),
                );
                return;
              }
              try {
                await _dio.post(
                  '${AppConstants.apiBaseUrl}/v1/admin/awards',
                  data: {
                    'id': idController.text.trim(),
                    'section_id': widget.sectionId,
                    'name': nameController.text.trim(),
                    'description': descriptionController.text.trim(),
                    'badge_image_url': imageController.text.trim(),
                    'min_age': double.tryParse(minAgeController.text),
                    'max_age': double.tryParse(maxAgeController.text),
                    'min_service_months': int.tryParse(minServiceController.text),
                    'display_order': int.tryParse(displayOrderController.text) ?? 1,
                  },
                );
                Navigator.pop(context);
                _loadAwards();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error creating award: ${e.toString()}")),
                );
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditAwardDialog(dynamic award) async {
    final awardId = award['id'] as String;
    final nameController = TextEditingController(text: award['name']);
    final descriptionController = TextEditingController(text: award['description'] ?? '');
    final imageController = TextEditingController(text: award['badge_image_url'] ?? '');
    final minAgeController = TextEditingController(text: award['min_age']?.toString() ?? '');
    final maxAgeController = TextEditingController(text: award['max_age']?.toString() ?? '');
    final minServiceController = TextEditingController(text: award['min_service_months']?.toString() ?? '');
    final displayOrderController = TextEditingController(text: award['display_order']?.toString() ?? '1');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit Award: $awardId"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Award Name"),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: "Description"),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: imageController,
                decoration: const InputDecoration(labelText: "Badge Asset Image Path"),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: minAgeController,
                decoration: const InputDecoration(labelText: "Minimum Age Gate"),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: maxAgeController,
                decoration: const InputDecoration(labelText: "Maximum Age Gate"),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: minServiceController,
                decoration: const InputDecoration(labelText: "Min Service Period (Months)"),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: displayOrderController,
                decoration: const InputDecoration(labelText: "Display Order"),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _dio.patch(
                  '${AppConstants.apiBaseUrl}/v1/admin/awards/$awardId',
                  data: {
                    'name': nameController.text.trim(),
                    'description': descriptionController.text.trim(),
                    'badge_image_url': imageController.text.trim(),
                    'min_age': double.tryParse(minAgeController.text),
                    'max_age': double.tryParse(maxAgeController.text),
                    'min_service_months': int.tryParse(minServiceController.text),
                    'display_order': int.tryParse(displayOrderController.text) ?? 1,
                  },
                );
                Navigator.pop(context);
                _loadAwards();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error updating award: ${e.toString()}")),
                );
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  // ─── REQUIREMENT GROUPS CRUD ──────────────────────────────────────────────
  Future<void> _deleteGroup(String awardId, String id) async {
    try {
      await _dio.delete('${AppConstants.apiBaseUrl}/v1/admin/groups/$id');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Group deleted successfully")),
      );
      _loadGroups(awardId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Delete failed: ${e.toString()}")),
      );
    }
  }

  Future<void> _showAddGroupDialog(String awardId) async {
    final idController = TextEditingController();
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final minSelectController = TextEditingController(text: "1");
    final maxSelectController = TextEditingController(text: "1");
    final displayOrderController = TextEditingController(text: "1");
    bool isPool = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Add Requirement Group"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: idController,
                  decoration: const InputDecoration(labelText: "Group ID (e.g. jr_mem_core)"),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Group Name"),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: "Description"),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text("Is Electives Pool?"),
                    Checkbox(
                      value: isPool,
                      onChanged: (val) {
                        setDialogState(() => isPool = val ?? false);
                      },
                    ),
                  ],
                ),
                if (isPool) ...[
                  TextField(
                    controller: minSelectController,
                    decoration: const InputDecoration(labelText: "Min Select Requirements"),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: maxSelectController,
                    decoration: const InputDecoration(labelText: "Max Select Requirements"),
                    keyboardType: TextInputType.number,
                  ),
                ],
                const SizedBox(height: 8),
                TextField(
                  controller: displayOrderController,
                  decoration: const InputDecoration(labelText: "Display Order"),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (idController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Group ID cannot be empty")),
                  );
                  return;
                }
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Group Name cannot be empty")),
                  );
                  return;
                }
                try {
                  await _dio.post(
                    '${AppConstants.apiBaseUrl}/v1/admin/groups',
                    data: {
                      'id': idController.text.trim(),
                      'award_id': awardId,
                      'name': nameController.text.trim(),
                      'description': descriptionController.text.trim(),
                      'is_pool': isPool,
                      'min_select': isPool ? int.tryParse(minSelectController.text) : 1,
                      'max_select': isPool ? int.tryParse(maxSelectController.text) : 1,
                      'display_order': int.tryParse(displayOrderController.text) ?? 1,
                    },
                  );
                  Navigator.pop(context);
                  _loadGroups(awardId);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error creating group: ${e.toString()}")),
                  );
                }
              },
              child: const Text("Add"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditGroupDialog(String awardId, dynamic group) async {
    final groupId = group['id'] as String;
    final nameController = TextEditingController(text: group['name']);
    final descriptionController = TextEditingController(text: group['description'] ?? '');
    final minSelectController = TextEditingController(text: group['min_select']?.toString() ?? '1');
    final maxSelectController = TextEditingController(text: group['max_select']?.toString() ?? '1');
    final displayOrderController = TextEditingController(text: group['display_order']?.toString() ?? '1');
    bool isPool = group['is_pool'] ?? false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text("Edit Group: $groupId"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Group Name"),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: "Description"),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text("Is Electives Pool?"),
                    Checkbox(
                      value: isPool,
                      onChanged: (val) {
                        setDialogState(() => isPool = val ?? false);
                      },
                    ),
                  ],
                ),
                if (isPool) ...[
                  TextField(
                    controller: minSelectController,
                    decoration: const InputDecoration(labelText: "Min Select Requirements"),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: maxSelectController,
                    decoration: const InputDecoration(labelText: "Max Select Requirements"),
                    keyboardType: TextInputType.number,
                  ),
                ],
                const SizedBox(height: 8),
                TextField(
                  controller: displayOrderController,
                  decoration: const InputDecoration(labelText: "Display Order"),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _dio.patch(
                    '${AppConstants.apiBaseUrl}/v1/admin/groups/$groupId',
                    data: {
                      'name': nameController.text.trim(),
                      'description': descriptionController.text.trim(),
                      'is_pool': isPool,
                      'min_select': isPool ? int.tryParse(minSelectController.text) : 1,
                      'max_select': isPool ? int.tryParse(maxSelectController.text) : 1,
                      'display_order': int.tryParse(displayOrderController.text) ?? 1,
                    },
                  );
                  Navigator.pop(context);
                  _loadGroups(awardId);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error updating group: ${e.toString()}")),
                  );
                }
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  // ─── REQUIREMENTS CRUD ────────────────────────────────────────────────────
  Future<void> _deleteRequirement(String groupId, String id) async {
    try {
      await _dio.delete('${AppConstants.apiBaseUrl}/v1/admin/requirements/$id');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Requirement deleted successfully")),
      );
      _loadRequirements(groupId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Delete failed: ${e.toString()}")),
      );
    }
  }

  Future<void> _showAddRequirementDialog(String groupId) async {
    final idController = TextEditingController();
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final minAgeController = TextEditingController();
    final maxAgeController = TextEditingController();
    final minServiceController = TextEditingController();
    final displayOrderController = TextEditingController(text: "1");
    bool isMandatory = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Add Requirement Task"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: idController,
                  decoration: const InputDecoration(labelText: "Requirement ID"),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Task Name"),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: "Detailed Description"),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text("Is Mandatory?"),
                    Checkbox(
                      value: isMandatory,
                      onChanged: (val) {
                        setDialogState(() => isMandatory = val ?? true);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: minAgeController,
                  decoration: const InputDecoration(labelText: "Minimum Age Gate"),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: maxAgeController,
                  decoration: const InputDecoration(labelText: "Maximum Age Gate"),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: minServiceController,
                  decoration: const InputDecoration(labelText: "Min Service Months Gate"),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: displayOrderController,
                  decoration: const InputDecoration(labelText: "Display Order"),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (idController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Requirement ID cannot be empty")),
                  );
                  return;
                }
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Requirement Name cannot be empty")),
                  );
                  return;
                }
                try {
                  await _dio.post(
                    '${AppConstants.apiBaseUrl}/v1/admin/requirements',
                    data: {
                      'id': idController.text.trim(),
                      'group_id': groupId,
                      'name': nameController.text.trim(),
                      'description': descriptionController.text.trim(),
                      'is_mandatory': isMandatory,
                      'min_age': double.tryParse(minAgeController.text),
                      'max_age': double.tryParse(maxAgeController.text),
                      'min_service_months': int.tryParse(minServiceController.text),
                      'display_order': int.tryParse(displayOrderController.text) ?? 1,
                    },
                  );
                  Navigator.pop(context);
                  _loadRequirements(groupId);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error creating task: ${e.toString()}")),
                  );
                }
              },
              child: const Text("Add"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditRequirementDialog(String groupId, dynamic req) async {
    final reqId = req['id'] as String;
    final nameController = TextEditingController(text: req['name']);
    final descriptionController = TextEditingController(text: req['description'] ?? '');
    final minAgeController = TextEditingController(text: req['min_age']?.toString() ?? '');
    final maxAgeController = TextEditingController(text: req['max_age']?.toString() ?? '');
    final minServiceController = TextEditingController(text: req['min_service_months']?.toString() ?? '');
    final displayOrderController = TextEditingController(text: req['display_order']?.toString() ?? '1');
    bool isMandatory = req['is_mandatory'] ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text("Edit Task: $reqId"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Task Name"),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: "Detailed Description"),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text("Is Mandatory?"),
                    Checkbox(
                      value: isMandatory,
                      onChanged: (val) {
                        setDialogState(() => isMandatory = val ?? true);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: minAgeController,
                  decoration: const InputDecoration(labelText: "Minimum Age Gate"),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: maxAgeController,
                  decoration: const InputDecoration(labelText: "Maximum Age Gate"),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: minServiceController,
                  decoration: const InputDecoration(labelText: "Min Service Months Gate"),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: displayOrderController,
                  decoration: const InputDecoration(labelText: "Display Order"),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _dio.patch(
                    '${AppConstants.apiBaseUrl}/v1/admin/requirements/$reqId',
                    data: {
                      'name': nameController.text.trim(),
                      'description': descriptionController.text.trim(),
                      'is_mandatory': isMandatory,
                      'min_age': double.tryParse(minAgeController.text),
                      'max_age': double.tryParse(maxAgeController.text),
                      'min_service_months': int.tryParse(minServiceController.text),
                      'display_order': int.tryParse(displayOrderController.text) ?? 1,
                    },
                  );
                  Navigator.pop(context);
                  _loadRequirements(groupId);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error updating task: ${e.toString()}")),
                  );
                }
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  // ─── RENDERING HIERARCHY ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sectionColor = AppColors.getSectionColor(widget.sectionId);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "${widget.sectionName} Awards",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: "Add Award",
            onPressed: _showAddAwardDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAwards,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _awards.isEmpty
                  ? Center(
                      child: Text(
                        "No awards configured for this section yet.",
                        style: theme.textTheme.titleMedium,
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _awards.length,
                      itemBuilder: (context, index) {
                        final award = _awards[index];
                        final awardId = award['id'] as String;
                        final groups = _groupsCache[awardId] ?? [];
                        final groupsLoading = _loadingGroups[awardId] == true;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ExpansionTile(
                            leading: CircleAvatar(
                              backgroundColor: sectionColor.withOpacity(0.1),
                              child: Icon(Icons.military_tech, color: sectionColor),
                            ),
                            title: Text(
                              award['name'],
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              "ID: $awardId | Age: ${award['min_age'] ?? 'Any'}-${award['max_age'] ?? 'Any'} | Service: ${award['min_service_months'] ?? '0'}m",
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
                                  tooltip: "Add Group",
                                  onPressed: () => _showAddGroupDialog(awardId),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blueGrey),
                                  tooltip: "Edit Award",
                                  onPressed: () => _showEditAwardDialog(award),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: AppColors.error),
                                  tooltip: "Delete Award",
                                  onPressed: () => _deleteAward(awardId),
                                ),
                              ],
                            ),
                            onExpansionChanged: (expanded) {
                              if (expanded && _groupsCache[awardId] == null) {
                                _loadGroups(awardId);
                              }
                            },
                            children: [
                              if (groupsLoading)
                                const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Center(child: CircularProgressIndicator()),
                                )
                              else if (groups.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Text("No requirement groups configured for this award."),
                                )
                              else
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: groups.length,
                                  itemBuilder: (context, gIndex) {
                                    final group = groups[gIndex];
                                    final groupId = group['id'] as String;
                                    final requirements = _requirementsCache[groupId] ?? [];
                                    final reqsLoading = _loadingRequirements[groupId] == true;

                                    return ExpansionTile(
                                      title: Text(
                                        group['name'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blueGrey,
                                        ),
                                      ),
                                      subtitle: Text(
                                        "ID: $groupId | Pool: ${group['is_pool']} | Order: ${group['display_order']}",
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.playlist_add, color: Colors.green),
                                            tooltip: "Add Task",
                                            onPressed: () => _showAddRequirementDialog(groupId),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.edit, color: Colors.blueGrey),
                                            tooltip: "Edit Group",
                                            onPressed: () => _showEditGroupDialog(awardId, group),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                                            tooltip: "Delete Group",
                                            onPressed: () => _deleteGroup(awardId, groupId),
                                          ),
                                        ],
                                      ),
                                      onExpansionChanged: (expanded) {
                                        if (expanded && _requirementsCache[groupId] == null) {
                                          _loadRequirements(groupId);
                                        }
                                      },
                                      children: [
                                        if (reqsLoading)
                                          const Padding(
                                            padding: EdgeInsets.all(12.0),
                                            child: Center(child: CircularProgressIndicator()),
                                          )
                                        else if (requirements.isEmpty)
                                          const Padding(
                                            padding: EdgeInsets.all(12.0),
                                            child: Text("No task requirements configured."),
                                          )
                                        else
                                          ListView.builder(
                                            shrinkWrap: true,
                                            physics: const NeverScrollableScrollPhysics(),
                                            itemCount: requirements.length,
                                            itemBuilder: (context, rIndex) {
                                              final req = requirements[rIndex];
                                              final reqId = req['id'] as String;

                                              return ListTile(
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                                                title: Text(
                                                  req['name'],
                                                  style: const TextStyle(fontSize: 14),
                                                ),
                                                subtitle: Text(
                                                  "ID: $reqId | Mand: ${req['is_mandatory']} | Age: ${req['min_age'] ?? 'Any'}-${req['max_age'] ?? 'Any'} | Service: ${req['min_service_months'] ?? '0'}m",
                                                  style: const TextStyle(fontSize: 11),
                                                ),
                                                trailing: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    IconButton(
                                                      icon: const Icon(Icons.edit_outlined, color: Colors.blueGrey, size: 20),
                                                      tooltip: "Edit Task",
                                                      onPressed: () => _showEditRequirementDialog(groupId, req),
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
                                                      tooltip: "Delete Task",
                                                      onPressed: () => _deleteRequirement(groupId, reqId),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                      ],
                                    );
                                  },
                                ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}
