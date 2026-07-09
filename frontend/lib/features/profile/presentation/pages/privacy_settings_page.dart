import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/gradient_button.dart';

class PrivacySettingsPage extends StatefulWidget {
  const PrivacySettingsPage({Key? key}) : super(key: key);

  @override
  State<PrivacySettingsPage> createState() => _PrivacySettingsPageState();
}

class _PrivacySettingsPageState extends State<PrivacySettingsPage> {
  final _formKey = GlobalKey<FormState>();
  
  late bool _isAnonymous;
  final _fullNameController = TextEditingController();
  final _schoolController = TextEditingController();
  final _troopController = TextEditingController();
  final _districtController = TextEditingController();
  final _provinceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      final user = authState.user;
      _isAnonymous = user.isAnonymous;
      _fullNameController.text = user.fullName ?? '';
      _schoolController.text = user.schoolName ?? '';
      _troopController.text = user.troopNumber ?? '';
      _districtController.text = user.district ?? '';
      _provinceController.text = user.province ?? '';
    } else {
      _isAnonymous = false;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _schoolController.dispose();
    _troopController.dispose();
    _districtController.dispose();
    _provinceController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_isAnonymous && (_fullNameController.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Full name is required for Known Scout mode."),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    context.read<AuthBloc>().add(
          IdentityModeToggled(
            isAnonymous: _isAnonymous,
            fullName: _isAnonymous ? null : _fullNameController.text.trim(),
            schoolName: _isAnonymous ? null : _schoolController.text.trim(),
            troopNumber: _isAnonymous ? null : _troopController.text.trim(),
            district: _isAnonymous ? null : _districtController.text.trim(),
            province: _isAnonymous ? null : _provinceController.text.trim(),
          ),
        );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Privacy settings updated successfully."),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Privacy & Identity",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20.0),
              children: [
                // Warning Card
                GlassCard(
                  borderColor: AppColors.secondary.withOpacity(0.3),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.secondary, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Switching to Anonymous mode deletes your name, school, district, and troop number from the server immediately. You will only be identified by a temporary display name.",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Switch Row
                SwitchListTile(
                  title: const Text(
                    "Anonymous Scout Mode",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text("Hide all identifiers from leaders"),
                  value: _isAnonymous,
                  activeColor: AppColors.secondary,
                  onChanged: (val) {
                    setState(() {
                      _isAnonymous = val;
                    });
                  },
                ),
                const SizedBox(height: 20),

                // Known fields (Only visible if NOT anonymous)
                if (!_isAnonymous) ...[
                  Text(
                    "Syllabus Profile Identifiers",
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  GlassCard(
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _fullNameController,
                          decoration: const InputDecoration(labelText: "Full Name *"),
                          validator: (value) =>
                              (!_isAnonymous && (value == null || value.trim().isEmpty)) ? "Full name is required" : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _schoolController,
                          decoration: const InputDecoration(labelText: "School Name *"),
                          validator: (value) =>
                              (!_isAnonymous && (value == null || value.trim().isEmpty)) ? "School is required" : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _troopController,
                          decoration: const InputDecoration(labelText: "Troop Number *"),
                          validator: (value) =>
                              (!_isAnonymous && (value == null || value.trim().isEmpty)) ? "Troop is required" : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _districtController,
                          decoration: const InputDecoration(labelText: "District *"),
                          validator: (value) =>
                              (!_isAnonymous && (value == null || value.trim().isEmpty)) ? "District is required" : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _provinceController,
                          decoration: const InputDecoration(labelText: "Province"),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                ],

                // Save button
                GradientButton(
                  text: "Save Settings",
                  isLoading: isLoading,
                  onPressed: _save,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
