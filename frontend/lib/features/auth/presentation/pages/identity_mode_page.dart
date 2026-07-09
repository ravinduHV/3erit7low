import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/gradient_button.dart';

class IdentityModePage extends StatefulWidget {
  final String email;
  final String password;

  const IdentityModePage({
    Key? key,
    required this.email,
    required this.password,
  }) : super(key: key);

  @override
  State<IdentityModePage> createState() => _IdentityModePageState();
}

class _IdentityModePageState extends State<IdentityModePage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  bool _isAnonymous = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_isAnonymous && (_fullNameController.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter your full name for Known User mode."),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    context.read<AuthBloc>().add(
          SignUpSubmitted(
            email: widget.email,
            password: widget.password,
            isAnonymous: _isAnonymous,
            fullName: _isAnonymous ? null : _fullNameController.text.trim(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
            context.go('/dashboard');
          } else if (state is OnboardingRequired) {
            context.go('/onboarding');
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

          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header
                        Center(
                          child: Column(
                            children: [
                              const Icon(
                                Icons.security,
                                color: AppColors.secondary,
                                size: 64,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "Privacy Options",
                                style: theme.textTheme.displaySmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "Step 2 of 3: How should we identify you?",
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Toggle Mode Options
                        Row(
                          children: [
                            // Known User choice card
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _isAnonymous = false),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: !_isAnonymous
                                        ? AppColors.secondary.withOpacity(0.15)
                                        : Colors.white.withOpacity(0.04),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: !_isAnonymous
                                          ? AppColors.secondary
                                          : Colors.white.withOpacity(0.1),
                                      width: 2,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.face,
                                        color: !_isAnonymous ? AppColors.secondary : Colors.white60,
                                        size: 40,
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        "Known Scout",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Show name & troop details",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.white.withOpacity(0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Anonymous User choice card
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _isAnonymous = true),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: _isAnonymous
                                        ? AppColors.secondary.withOpacity(0.15)
                                        : Colors.white.withOpacity(0.04),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: _isAnonymous
                                          ? AppColors.secondary
                                          : Colors.white.withOpacity(0.1),
                                      width: 2,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.visibility_off,
                                        color: _isAnonymous ? AppColors.secondary : Colors.white60,
                                        size: 40,
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        "Anonymous",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Hide name, school & troop",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.white.withOpacity(0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Form Detail Card
                        GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (!_isAnonymous) ...[
                                Text(
                                  "Tell us about yourself",
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _fullNameController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    labelText: "Full Name",
                                    labelStyle: TextStyle(color: Colors.white70),
                                    prefixIcon: Icon(Icons.person, color: Colors.white70),
                                  ),
                                  validator: (value) {
                                    if (!_isAnonymous && (value == null || value.trim().isEmpty)) {
                                      return "Please enter your name";
                                    }
                                    return null;
                                  },
                                ),
                              ] else ...[
                                Row(
                                  children: [
                                    const Icon(Icons.privacy_tip, color: AppColors.secondary, size: 28),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        "Anonymous Mode Enabled",
                                        style: theme.textTheme.titleLarge?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  "Your personal details (name, school, district, troop number) will NOT be stored. You will be displayed to leaders and others under a randomized display name (e.g. Scout #A3F2).\n\nYou can change this setting at any time from your profile settings.",
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.white.withOpacity(0.7),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 28),

                              // Register Submit Button
                              GradientButton(
                                text: "Register & Next",
                                isLoading: isLoading,
                                onPressed: _submit,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Back to step 1
                        TextButton(
                          onPressed: () => context.pop(),
                          child: const Text(
                            "Back to Step 1",
                            style: TextStyle(
                              color: Colors.white70,
                              decoration: TextDecoration.underline,
                            ),
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
