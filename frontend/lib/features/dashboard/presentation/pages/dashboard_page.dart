import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../progress/presentation/bloc/progress_bloc.dart';
import '../../../progress/presentation/bloc/progress_event.dart';
import '../../../progress/presentation/bloc/progress_state.dart';
import '../../../progress/domain/entities/progress_entities.dart';
import '../../../progress/domain/repositories/progress_repository.dart';
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
  PredictionEntity? _prediction;
  bool _isLoadingPrediction = true;

  @override
  void initState() {
    super.initState();
    // Refresh session data on load
    context.read<AuthBloc>().add(AuthCheckRequested());
    // Refresh progress data
    context.read<ProgressBloc>().add(ProgressFetchRequested());
    _fetchPrediction();
  }

  Future<void> _fetchPrediction() async {
    try {
      setState(() => _isLoadingPrediction = true);
      final repo = GetIt.instance<ProgressRepository>();
      final prediction = await repo.getPredictions();
      setState(() {
        _prediction = prediction;
        _isLoadingPrediction = false;
      });
    } catch (_) {
      setState(() {
        _isLoadingPrediction = false;
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Hello, ${user.displayName ?? 'Scout'}",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                      ),
                      const SizedBox(width: 12),
                      // Header Actions Row (Admin Panel + Profile settings)
                      Row(
                        children: [
                          if (user.role == 'admin') ...[
                            IconButton(
                              icon: const Icon(Icons.admin_panel_settings, color: AppColors.secondary, size: 30),
                              tooltip: "Manage Syllabus",
                              onPressed: () => context.push('/admin-syllabus'),
                            ),
                            const SizedBox(width: 8),
                          ],
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
                   const SizedBox(height: 20),

                   // ─── Progress Forecast Card ───────────────────
                   if (_isLoadingPrediction)
                     const Center(child: CircularProgressIndicator())
                   else if (_prediction != null) ...[
                     GlassCard(
                       borderColor: sectionColor.withOpacity(0.3),
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Row(
                             children: [
                               Icon(Icons.online_prediction, color: sectionColor, size: 26),
                               const SizedBox(width: 8),
                               Text(
                                 "Progress Forecast",
                                 style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                               ),
                             ],
                           ),
                           const SizedBox(height: 14),
                           Row(
                             children: [
                               Expanded(
                                 child: Column(
                                   crossAxisAlignment: CrossAxisAlignment.start,
                                   children: [
                                     Text(
                                       "Highest Achievable Award",
                                       style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                                     ),
                                     const SizedBox(height: 4),
                                     Text(
                                       _prediction!.highestAchievableAwardName ?? "None predicted",
                                       style: theme.textTheme.titleMedium?.copyWith(
                                         fontWeight: FontWeight.bold,
                                         color: sectionColor,
                                       ),
                                     ),
                                   ],
                                 ),
                               ),
                               Column(
                                 crossAxisAlignment: CrossAxisAlignment.end,
                                 children: [
                                   Text(
                                     "Time Remaining",
                                     style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                                   ),
                                   const SizedBox(height: 4),
                                   Text(
                                     _prediction!.remainingDaysInSection > 365
                                         ? "${(_prediction!.remainingDaysInSection / 365.25).toStringAsFixed(1)} yrs"
                                         : "${(_prediction!.remainingDaysInSection / 30.44).toStringAsFixed(0)} months",
                                     style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                   ),
                                 ],
                               ),
                             ],
                           ),
                           if (_prediction!.isAgingOutWarning) ...[
                             const SizedBox(height: 12),
                             Container(
                               padding: const EdgeInsets.all(10),
                               decoration: BoxDecoration(
                                 color: Colors.orange.withOpacity(0.12),
                                 borderRadius: BorderRadius.circular(8),
                                 border: Border.all(color: Colors.orange.withOpacity(0.4)),
                               ),
                               child: Row(
                                 children: [
                                   const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                                   const SizedBox(width: 8),
                                   Expanded(
                                     child: Text(
                                       "Aging Out Warning! Less than 6 months remain in this section.",
                                       style: theme.textTheme.bodySmall?.copyWith(color: Colors.orange[800]),
                                     ),
                                   ),
                                 ],
                               ),
                             ),
                           ],
                         ],
                       ),
                     ),
                   ],
                   const SizedBox(height: 28),

                   // ─── AI Pathway Suggestions ────────────────────
                   Row(
                     children: [
                       const Icon(Icons.psychology, color: AppColors.secondary, size: 28),
                       const SizedBox(width: 8),
                       Text(
                         "AI Pathway Suggestions",
                         style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                       ),
                     ],
                   ),
                   const SizedBox(height: 12),

                   if (_isLoadingPrediction)
                     const Center(child: CircularProgressIndicator())
                   else if (_prediction == null || _prediction!.recommendations.isEmpty)
                     const GlassCard(
                       child: Center(
                         child: Padding(
                           padding: EdgeInsets.all(12.0),
                           child: Text("No recommendations available. Ensure your section is configured."),
                         ),
                       ),
                     )
                   else
                     ListView.separated(
                       shrinkWrap: true,
                       physics: const NeverScrollableScrollPhysics(),
                       itemCount: _prediction!.recommendations.length,
                       separatorBuilder: (_, __) => const SizedBox(height: 12),
                       itemBuilder: (context, index) {
                         final rec = _prediction!.recommendations[index];

                         IconData icon;
                         Color color;
                         String statusLabel;

                         switch (rec.status) {
                           case 'completed':
                             icon = Icons.check_circle;
                             color = Colors.green;
                             statusLabel = "Completed";
                             break;
                           case 'recommended':
                             icon = Icons.star;
                             color = sectionColor;
                             statusLabel = "Recommended";
                             break;
                           case 'locked_prerequisite':
                             icon = Icons.lock_outline;
                             color = Colors.grey;
                             statusLabel = "Prerequisites";
                             break;
                           case 'locked_service':
                             icon = Icons.lock_clock;
                             color = Colors.orange;
                             statusLabel = "Service Period";
                             break;
                           case 'locked_age':
                             icon = Icons.lock_person;
                             color = Colors.red;
                             statusLabel = "Age Gate";
                             break;
                           default:
                             icon = Icons.help_outline;
                             color = Colors.blue;
                             statusLabel = "Info";
                         }

                         return GlassCard(
                           borderColor: color.withOpacity(0.25),
                           child: Row(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               CircleAvatar(
                                 radius: 22,
                                 backgroundColor: color.withOpacity(0.12),
                                 child: Icon(icon, color: color, size: 22),
                               ),
                               const SizedBox(width: 14),
                               Expanded(
                                 child: Column(
                                   crossAxisAlignment: CrossAxisAlignment.start,
                                   children: [
                                     Row(
                                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                       children: [
                                         Expanded(
                                           child: Text(
                                             rec.awardName,
                                             style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                             overflow: TextOverflow.ellipsis,
                                           ),
                                         ),
                                         Container(
                                           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                           decoration: BoxDecoration(
                                             color: color.withOpacity(0.12),
                                             borderRadius: BorderRadius.circular(12),
                                           ),
                                           child: Text(
                                             statusLabel,
                                             style: TextStyle(
                                               color: color,
                                               fontWeight: FontWeight.bold,
                                               fontSize: 11,
                                             ),
                                           ),
                                         ),
                                       ],
                                     ),
                                     const SizedBox(height: 6),
                                     Text(
                                       rec.reason,
                                       style: theme.textTheme.bodyMedium?.copyWith(
                                         color: Colors.grey[700],
                                         height: 1.3,
                                       ),
                                     ),
                                     if (rec.targetCompletionDate != null && rec.status != 'completed') ...[
                                       const SizedBox(height: 6),
                                       Row(
                                         children: [
                                           Icon(Icons.calendar_today, size: 12, color: Colors.grey[500]),
                                           const SizedBox(width: 4),
                                           Text(
                                             "Target: ${rec.targetCompletionDate!.year}-${rec.targetCompletionDate!.month.toString().padLeft(2, '0')}-${rec.targetCompletionDate!.day.toString().padLeft(2, '0')}",
                                             style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
                                           ),
                                         ],
                                       ),
                                     ],
                                   ],
                                 ),
                               ),
                             ],
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
