import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';

class AdminSyllabusPage extends StatefulWidget {
  const AdminSyllabusPage({Key? key}) : super(key: key);

  @override
  State<AdminSyllabusPage> createState() => _AdminSyllabusPageState();
}

class _AdminSyllabusPageState extends State<AdminSyllabusPage> {
  final _dio = GetIt.instance<Dio>();
  
  List<dynamic> _sections = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSyllabus();
  }

  Future<void> _loadSyllabus() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      
      final response = await _dio.get('${AppConstants.apiBaseUrl}/v1/admin/sections');
      setState(() {
        _sections = response.data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Error loading syllabus sections: ${e.toString()}";
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteSection(String id) async {
    try {
      await _dio.delete('${AppConstants.apiBaseUrl}/v1/admin/sections/$id');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Section deleted successfully")),
      );
      _loadSyllabus();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Delete failed: ${e.toString()}")),
      );
    }
  }

  Future<void> _showAddSectionDialog() async {
    final idController = TextEditingController();
    final nameController = TextEditingController();
    final slugController = TextEditingController();
    final colorController = TextEditingController(text: "#1B4332");
    final minAgeController = TextEditingController();
    final maxAgeController = TextEditingController();
    String? selectedLinkedSectionId = "none";

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Add New Section"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: idController,
                  decoration: const InputDecoration(labelText: "Section ID (e.g. rover)"),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Section Name (e.g. Rover Scout)"),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: slugController,
                  decoration: const InputDecoration(labelText: "Slug"),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: colorController,
                  decoration: const InputDecoration(labelText: "Color Hex Code"),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: minAgeController,
                  decoration: const InputDecoration(labelText: "Minimum Age"),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: maxAgeController,
                  decoration: const InputDecoration(labelText: "Maximum Age"),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedLinkedSectionId,
                  decoration: const InputDecoration(
                    labelText: "Linked Predecessor Section",
                    helperText: "Carries forward member's service credit",
                  ),
                  items: [
                    const DropdownMenuItem(value: "none", child: Text("None")),
                    ..._sections.map((s) => DropdownMenuItem(
                          value: s['id'] as String,
                          child: Text(s['name'] as String),
                        )),
                  ],
                  onChanged: (val) {
                    setDialogState(() => selectedLinkedSectionId = val);
                  },
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
                  await _dio.post(
                    '${AppConstants.apiBaseUrl}/v1/admin/sections',
                    data: {
                      'id': idController.text.trim(),
                      'name': nameController.text.trim(),
                      'slug': slugController.text.trim(),
                      'color_hex': colorController.text.trim(),
                      'min_age': double.tryParse(minAgeController.text),
                      'max_age': double.tryParse(maxAgeController.text),
                      'role_type': 'scout',
                      'linked_section_id': selectedLinkedSectionId == "none" ? null : selectedLinkedSectionId,
                    },
                  );
                  Navigator.pop(context);
                  _loadSyllabus();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error creating section: ${e.toString()}")),
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

  Future<void> _showEditSectionDialog(dynamic sec) async {
    final nameController = TextEditingController(text: sec['name']);
    final slugController = TextEditingController(text: sec['slug']);
    final colorController = TextEditingController(text: sec['color_hex']);
    final minAgeController = TextEditingController(text: sec['min_age']?.toString() ?? '');
    final maxAgeController = TextEditingController(text: sec['max_age']?.toString() ?? '');
    String? selectedLinkedSectionId = sec['linked_section_id'] as String? ?? "none";

    // Filter out the current section so a section can't link to itself
    final otherSections = _sections.where((s) => s['id'] != sec['id']).toList();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text("Edit Section: ${sec['id']}"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Section Name"),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: slugController,
                  decoration: const InputDecoration(labelText: "Slug"),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: colorController,
                  decoration: const InputDecoration(labelText: "Color Hex Code"),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: minAgeController,
                  decoration: const InputDecoration(labelText: "Minimum Age"),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: maxAgeController,
                  decoration: const InputDecoration(labelText: "Maximum Age"),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedLinkedSectionId,
                  decoration: const InputDecoration(
                    labelText: "Linked Predecessor Section",
                    helperText: "Carries forward member's service credit",
                  ),
                  items: [
                    const DropdownMenuItem(value: "none", child: Text("None")),
                    ...otherSections.map((s) => DropdownMenuItem(
                          value: s['id'] as String,
                          child: Text(s['name'] as String),
                        )),
                  ],
                  onChanged: (val) {
                    setDialogState(() => selectedLinkedSectionId = val);
                  },
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
                    '${AppConstants.apiBaseUrl}/v1/admin/sections/${sec['id']}',
                    data: {
                      'name': nameController.text.trim(),
                      'slug': slugController.text.trim(),
                      'color_hex': colorController.text.trim(),
                      'min_age': double.tryParse(minAgeController.text),
                      'max_age': double.tryParse(maxAgeController.text),
                      'linked_section_id': selectedLinkedSectionId == "none" ? null : selectedLinkedSectionId,
                    },
                  );
                  Navigator.pop(context);
                  _loadSyllabus();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error updating section: ${e.toString()}")),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Admin Syllabus Control",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddSectionDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSyllabus,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 600;

                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isWide ? 3 : 1,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.4,
                      ),
                      itemCount: _sections.length,
                      itemBuilder: (context, index) {
                        final sec = _sections[index];
                        final color = AppColors.getSectionColor(sec['id']);

                        return GlassCard(
                          borderColor: color.withOpacity(0.3),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      sec['name'],
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        color: color,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blueGrey),
                                        onPressed: () => _showEditSectionDialog(sec),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: AppColors.error),
                                        onPressed: () => _deleteSection(sec['id']),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text("ID: ${sec['id']}"),
                              Text("Slug: ${sec['slug']}"),
                              Text(
                                "Age limit: ${sec['min_age'] ?? 'Any'} - ${sec['max_age'] ?? 'Any'}",
                              ),
                              const Spacer(),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: color),
                                onPressed: () => context.push(
                                  '/admin-section-awards',
                                  extra: {
                                    'sectionId': sec['id'],
                                    'sectionName': sec['name'],
                                  },
                                ),
                                child: const Text("Configure Awards"),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}
