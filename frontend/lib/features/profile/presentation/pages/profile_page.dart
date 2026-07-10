import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/gradient_button.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "My Profile",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Unauthenticated) {
            context.go('/login');
          }
        },
        builder: (context, state) {
          final user = state is Authenticated ? state.user : null;
          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final sectionColor = AppColors.getSectionColor(user.sectionId);

          return ListView(
            padding: const EdgeInsets.all(20.0),
            children: [
              // User Avatar & Name
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 46,
                      backgroundColor: sectionColor.withOpacity(0.15),
                      child: Icon(Icons.person, color: sectionColor, size: 52),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user.displayName ?? 'Scout',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: user.isAnonymous ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        user.isAnonymous ? "Anonymous Mode" : "Known Scout Mode",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: user.isAnonymous ? Colors.red : Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Profile data fields
              Text(
                "Account Details",
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              GlassCard(
                child: Column(
                  children: [
                    _buildDetailRow("Scout Role", user.role.toUpperCase(), theme),
                    _buildDivider(theme),
                    _buildDetailRow(
                      "Date of Birth",
                      user.dateOfBirth != null
                          ? DateFormat('yyyy-MM-dd').format(user.dateOfBirth!)
                          : "Not set",
                      theme,
                    ),
                    _buildDivider(theme),
                    _buildDetailRow(
                      "Joined Section",
                      user.joinedSectionAt != null
                          ? DateFormat('yyyy-MM-dd').format(user.joinedSectionAt!)
                          : "Not set",
                      theme,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (!user.isAnonymous) ...[
                Text(
                  "Syllabus & Troop Info",
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                GlassCard(
                  child: Column(
                    children: [
                      _buildDetailRow("School", user.schoolName ?? "Not set", theme),
                      _buildDivider(theme),
                      _buildDetailRow("Troop", user.troopNumber ?? "Not set", theme),
                      _buildDivider(theme),
                      _buildDetailRow("District", user.district ?? "Not set", theme),
                      _buildDivider(theme),
                      _buildDetailRow("Province", user.province ?? "Not set", theme),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Admin Controls (Only visible to admin users)
              if (user.role == 'admin') ...[
                Text(
                  "Admin Panel",
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                GlassCard(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.admin_panel_settings, color: AppColors.secondary),
                    title: const Text(
                      "Manage Syllabus",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text("Edit sections, awards, and requirements"),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => context.push('/admin-syllabus'),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Privacy Controls
              Text(
                "Privacy Settings",
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              GlassCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.security, color: AppColors.secondary),
                  title: const Text(
                    "Switch Anonymity Mode",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text("Clear or add personal identifiers anytime"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => context.push('/privacy-settings'),
                ),
              ),
              const SizedBox(height: 36),

              // Logout Button
              GradientButton(
                text: "Sign Out",
                colors: [Colors.red, Colors.red[800]!],
                onPressed: () {
                  context.read<AuthBloc>().add(SignOutPressed());
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Divider(
      color: theme.brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[200],
      height: 1,
    );
  }
}
