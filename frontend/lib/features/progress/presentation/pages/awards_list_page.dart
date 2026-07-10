import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/progress_bloc.dart';
import '../bloc/progress_event.dart';
import '../bloc/progress_state.dart';
import '../../../../core/widgets/badge_card.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/theme/app_colors.dart';

class AwardsListPage extends StatefulWidget {
  const AwardsListPage({Key? key}) : super(key: key);

  @override
  State<AwardsListPage> createState() => _AwardsListPageState();
}

class _AwardsListPageState extends State<AwardsListPage> {
  @override
  void initState() {
    super.initState();
    // Fetch latest progress info on page load
    context.read<ProgressBloc>().add(ProgressFetchRequested());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Syllabus & Awards",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                context.read<ProgressBloc>().add(ProgressFetchRequested()),
          ),
        ],
      ),
      body: BlocBuilder<ProgressBloc, ProgressState>(
        builder: (context, state) {
          if (state is ProgressLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ProgressError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context
                          .read<ProgressBloc>()
                          .add(ProgressFetchRequested()),
                      child: const Text("Retry"),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is ProgressLoaded) {
            final summary = state.summary;
            final sectionColor = AppColors.getSectionColor(summary.id);

            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Section Summary Header Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [sectionColor, sectionColor.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: sectionColor.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              summary.name,
                              style: theme.textTheme.displaySmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            summary.id == 'leader'
                                ? Icons.supervisor_account
                                : Icons.military_tech,
                            color: Colors.white,
                            size: 36,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Track your awards, complete requirements, and earn badges to advance your rank.",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  "Progressive Awards",
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                // Awards List
                if (summary.awards.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text("No awards configured for this section yet."),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: summary.awards.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final award = summary.awards[index];

                      return BadgeCard(
                        title: award.name,
                        subtitle: award.description,
                        imageUrl: award.badgeImageUrl,
                        percent: award.percentCompleted,
                        isCompleted: award.isCompleted,
                        onTap: () {
                          // Navigate to details page
                          context.push('/award-detail', extra: award);
                        },
                      );
                    },
                  ),
              ],
            );
          }

          return const Center(child: Text("No progress summary loaded."));
        },
      ),
    );
  }
}
