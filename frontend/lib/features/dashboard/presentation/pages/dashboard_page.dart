import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../progress/presentation/bloc/progress_bloc.dart';
import '../../../progress/presentation/bloc/progress_event.dart';
import '../../../progress/presentation/bloc/progress_state.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/progress_ring.dart';
import '../../../../core/widgets/section_chip.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<dynamic> _suggestions = [];
  bool _isLoadingSuggestions = true;

  @override
  void initState() {
    super.initState();
    // Refresh session data on load
    context.read<AuthBloc>().add(AuthCheckRequested());
    // Refresh progress data
    context.read<ProgressBloc>().add(ProgressFetchRequested());
    _fetchSuggestions();
  }

  Future<void> _fetchSuggestions() async {
    try {
      final dio = GetIt.instance<Dio>();
      final response = await dio.get('${AppConstants.apiBaseUrl}/v1/assistant/suggestions');
      setState(() {
        _suggestions = response.data['suggestions'];
        _isLoadingSuggestions = false;
      });
    } catch (_) {
      setState(() {
        _isLoadingSuggestions = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          final user = authState is Authenticated ? authState.user : null;
          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final sectionColor = AppColors.getSectionColor(user.sectionId);

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  sectionColor.withOpacity(0.08),
                  theme.brightness == Brightness.dark
                      ? AppColors.backgroundDark
                      : AppColors.backgroundLight,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(20.0),
                children: [
                  // Profile & Welcome Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Hello, ${user.displayName ?? 'Scout'}",
                            style: theme.textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (user.sectionId != null)
                            SectionChip(
                              sectionName: user.sectionId!.toUpperCase(),
                              sectionId: user.sectionId!,
                            ),
                        ],
                      ),
                      // Profile settings link button
                      GestureDetector(
                        onTap: () => context.push('/profile'),
                        child: CircleAvatar(
                          radius: 26,
                          backgroundColor: sectionColor.withOpacity(0.15),
                          child: Icon(Icons.person, color: sectionColor, size: 28),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Progress Summary Ring Card
                  BlocBuilder<ProgressBloc, ProgressState>(
                    builder: (context, progressState) {
                      double overallPercent = 0.0;
                      int totalAwards = 0;
                      int completedAwards = 0;

                      if (progressState is ProgressLoaded) {
                        final awards = progressState.summary.awards;
                        totalAwards = awards.length;
                        completedAwards = awards.where((a) => a.isCompleted).length;
                        
                        if (totalAwards > 0) {
                          overallPercent = (completedAwards / totalAwards) * 100;
                        }
                      }

                      return GlassCard(
                        borderColor: sectionColor.withOpacity(0.2),
                        child: Row(
                          children: [
                            ProgressRing(
                              percent: overallPercent,
                              size: 80,
                              strokeWidth: 8,
                              color: sectionColor,
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Overall Section Progress",
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Earned $completedAwards of $totalAwards progressive awards.",
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  // Syallbus navigation link
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: const Size(double.infinity, 38),
                                      backgroundColor: sectionColor,
                                    ),
                                    onPressed: () => context.push('/awards-list'),
                                    child: const Text("View Syllabus"),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 28),

                  // Rule-based personal assistant suggestions section
                  Row(
                    children: [
                      const Icon(Icons.assistant, color: AppColors.secondary, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        "Assistant Recommendations",
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_isLoadingSuggestions)
                    const Center(child: CircularProgressIndicator())
                  else if (_suggestions.isEmpty)
                    const GlassCard(
                      child: Center(
                        child: Text("You are completely up to date! Keep exploring."),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _suggestions.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final suggest = _suggestions[index];
                        final type = suggest['type'] as String;
                        final priority = suggest['priority'] as int;

                        IconData icon;
                        Color color;

                        switch (type) {
                          case 'milestone':
                            icon = Icons.star;
                            color = Colors.amber;
                            break;
                          case 'reminder':
                            icon = Icons.alarm;
                            color = Colors.orange;
                            break;
                          case 'next_step':
                            icon = Icons.arrow_forward_ios;
                            color = sectionColor;
                            break;
                          default:
                            icon = Icons.info_outline;
                            color = Colors.blue;
                        }

                        return GestureDetector(
                          onTap: () {
                            if (suggest['action'] == 'open_award' && suggest['target_id'] != null) {
                              context.push('/awards-list');
                            }
                          },
                          child: GlassCard(
                            borderColor: color.withOpacity(0.2),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: color.withOpacity(0.12),
                                  child: Icon(icon, color: color, size: 24),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        suggest['title'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        suggest['message'],
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          height: 1.3,
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
