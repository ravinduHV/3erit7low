import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/gradient_button.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({Key? key}) : super(key: key);

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Input fields controllers
  final _dobController = TextEditingController();
  final _joinedController = TextEditingController();
  final _schoolController = TextEditingController();
  final _troopController = TextEditingController();
  final _districtController = TextEditingController();
  final _provinceController = TextEditingController();

  DateTime? _selectedDob;
  DateTime? _selectedJoinedDate;
  String? _selectedSectionId;
  String _selectedGender = 'Male';

  List<dynamic> _sections = [];
  bool _isLoadingSections = true;
  String? _sectionsError;

  @override
  void initState() {
    super.initState();
    _fetchSections();
  }

  @override
  void dispose() {
    _dobController.dispose();
    _joinedController.dispose();
    _schoolController.dispose();
    _troopController.dispose();
    _districtController.dispose();
    _provinceController.dispose();
    super.dispose();
  }

  Future<void> _fetchSections() async {
    try {
      final dio = Dio();
      final response = await dio.get('${AppConstants.apiBaseUrl}/v1/admin/sections');
      setState(() {
        _sections = response.data;
        _isLoadingSections = false;
      });
    } catch (e) {
      setState(() {
        _sectionsError = "Failed to load scout sections. Please check connection.";
        _isLoadingSections = false;
        // Fallback default scout sections
        _sections = [
          {'id': 'singithi', 'name': 'Singithi Scout', 'min_age': 5.0, 'max_age': 7.0, 'color_hex': '#FCD34D', 'icon_name': 'child_care'},
          {'id': 'cub', 'name': 'Cub Scout', 'min_age': 7.0, 'max_age': 10.5, 'color_hex': '#FB923C', 'icon_name': 'pets'},
          {'id': 'junior', 'name': 'Junior Scout', 'min_age': 10.5, 'max_age': 14.5, 'color_hex': '#3B82F6', 'icon_name': 'directions_run'},
          {'id': 'senior', 'name': 'Senior Scout', 'min_age': 14.5, 'max_age': 18.0, 'color_hex': '#16A34A', 'icon_name': 'terrain'},
          {'id': 'rover', 'name': 'Rover Scout', 'min_age': 18.0, 'max_age': 26.0, 'color_hex': '#7C3AED', 'icon_name': 'explore'},
          {'id': 'leader', 'name': 'Scout Leader', 'min_age': 18.0, 'max_age': null, 'color_hex': '#9F1239', 'icon_name': 'supervisor_account'},
        ];
      });
    }
  }

  void _selectDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 12)),
      firstDate: DateTime(1960),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDob = picked;
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _selectJoinedDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedJoinedDate = picked;
        _joinedController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _submit(bool isAnonymous) {
    if (_selectedSectionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select your scouting section."),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      // First save general profile onboarding setup details
      context.read<AuthBloc>().add(
            ProfileSetupCompleted(
              dateOfBirth: _selectedDob!,
              gender: _selectedGender,
              sectionId: _selectedSectionId!,
              joinedSectionAt: _selectedJoinedDate ?? DateTime.now(),
            ),
          );
          
      // Next, if known user, update identity details
      if (!isAnonymous) {
        context.read<AuthBloc>().add(
              IdentityModeToggled(
                isAnonymous: false,
                fullName: (context.read<AuthBloc>().state as OnboardingRequired).user.fullName,
                schoolName: _schoolController.text.trim(),
                troopNumber: _troopController.text.trim(),
                district: _districtController.text.trim(),
                province: _provinceController.text.trim(),
              ),
            );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
            context.go('/dashboard');
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;
          final user = state is OnboardingRequired ? state.user : null;
          final isAnon = user?.isAnonymous ?? false;

          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, Color(0xFF0F172A)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: _isLoadingSections
                  ? const Center(child: CircularProgressIndicator())
                  : Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Step Header
                              Center(
                                child: Column(
                                  children: [
                                    const Icon(
                                      Icons.person_add,
                                      color: AppColors.secondary,
                                      size: 56,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "Onboarding",
                                      style: theme.textTheme.displaySmall?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      "Step 3 of 3: Scouting Profile Setup",
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: AppColors.secondary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Form Card
                              GlassCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      "1. Select Scout Section",
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    
                                    // Section selection grid
                                    GridView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        crossAxisSpacing: 10,
                                        mainAxisSpacing: 10,
                                        childAspectRatio: 2.2,
                                      ),
                                      itemCount: _sections.length,
                                      itemBuilder: (context, index) {
                                        final sec = _sections[index];
                                        final isSelected = _selectedSectionId == sec['id'];
                                        final color = AppColors.getSectionColor(sec['id']);

                                        return GestureDetector(
                                          onTap: () => setState(() => _selectedSectionId = sec['id']),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? color.withOpacity(0.2)
                                                  : Colors.white.withOpacity(0.04),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: isSelected ? color : Colors.white.withOpacity(0.1),
                                                width: 2,
                                              ),
                                            ),
                                            child: Center(
                                              child: Text(
                                                sec['name'],
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: isSelected ? color : Colors.white,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 20),

                                    Text(
                                      "2. General Information",
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 12),

                                    // Date of birth
                                    TextFormField(
                                      controller: _dobController,
                                      readOnly: true,
                                      onTap: _selectDob,
                                      style: const TextStyle(color: Colors.white),
                                      decoration: const InputDecoration(
                                        labelText: "Date of Birth *",
                                        labelStyle: TextStyle(color: Colors.white70),
                                        prefixIcon: Icon(Icons.calendar_month, color: Colors.white70),
                                      ),
                                      validator: (value) =>
                                          (value == null || value.isEmpty) ? "Date of birth is required" : null,
                                    ),
                                    const SizedBox(height: 12),

                                    // Joined section date
                                    TextFormField(
                                      controller: _joinedController,
                                      readOnly: true,
                                      onTap: _selectJoinedDate,
                                      style: const TextStyle(color: Colors.white),
                                      decoration: const InputDecoration(
                                        labelText: "Date Joined Section *",
                                        labelStyle: TextStyle(color: Colors.white70),
                                        prefixIcon: Icon(Icons.history, color: Colors.white70),
                                      ),
                                      validator: (value) =>
                                          (value == null || value.isEmpty) ? "Date joined is required" : null,
                                    ),
                                    const SizedBox(height: 12),

                                    // Gender Selection dropdown
                                    DropdownButtonFormField<String>(
                                      value: _selectedGender,
                                      style: const TextStyle(color: Colors.white),
                                      dropdownColor: AppColors.backgroundDark,
                                      decoration: const InputDecoration(
                                        labelText: "Gender *",
                                        labelStyle: TextStyle(color: Colors.white70),
                                        prefixIcon: Icon(Icons.group, color: Colors.white70),
                                      ),
                                      items: const [
                                        DropdownMenuItem(value: "Male", child: Text("Male")),
                                        DropdownMenuItem(value: "Female", child: Text("Female")),
                                        DropdownMenuItem(value: "Other", child: Text("Other")),
                                      ],
                                      onChanged: (val) => setState(() => _selectedGender = val ?? "Male"),
                                    ),

                                    // 3. Known user details section (Only if NOT anonymous)
                                    if (!isAnon) ...[
                                      const SizedBox(height: 20),
                                      Text(
                                        "3. School & Location",
                                        style: theme.textTheme.titleLarge?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: _schoolController,
                                        style: const TextStyle(color: Colors.white),
                                        decoration: const InputDecoration(
                                          labelText: "School Name *",
                                          labelStyle: TextStyle(color: Colors.white70),
                                        ),
                                        validator: (value) =>
                                            (!isAnon && (value == null || value.trim().isEmpty)) ? "School name is required" : null,
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextFormField(
                                              controller: _troopController,
                                              style: const TextStyle(color: Colors.white),
                                              decoration: const InputDecoration(
                                                labelText: "Troop No. *",
                                                labelStyle: TextStyle(color: Colors.white70),
                                              ),
                                              validator: (value) =>
                                                  (!isAnon && (value == null || value.trim().isEmpty)) ? "Troop is required" : null,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: TextFormField(
                                              controller: _districtController,
                                              style: const TextStyle(color: Colors.white),
                                              decoration: const InputDecoration(
                                                labelText: "District *",
                                                labelStyle: TextStyle(color: Colors.white70),
                                              ),
                                              validator: (value) =>
                                                  (!isAnon && (value == null || value.trim().isEmpty)) ? "District is required" : null,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: _provinceController,
                                        style: const TextStyle(color: Colors.white),
                                        decoration: const InputDecoration(
                                          labelText: "Province",
                                          labelStyle: TextStyle(color: Colors.white70),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 28),

                                    // Get started button
                                    GradientButton(
                                      text: "Get Started",
                                      isLoading: isLoading,
                                      onPressed: () => _submit(isAnon),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }
}
