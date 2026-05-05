import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../configurations/theme/app_colors.dart';
import '../../../../configurations/theme/app_typography.dart';
import '../../../../models/enums/prediction_result.dart';
import '../../../../models/user_model.dart';
import '../../../../services/user_service.dart';
import '../../../../services/prediction_service.dart';
import '../../../../services/auth_service.dart';
import 'widgets/statistics_card.dart';
import 'widgets/recent_predictions_list.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use stream providers for reactive data
    final usersAsync = ref.watch(allUsersStreamProvider);
    final predictionsAsync = ref.watch(allPredictionsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authServiceProvider).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: usersAsync.when(
        data: (users) {
          return predictionsAsync.when(
            data: (predictions) {
              final totalUsers = users.length;
              final totalPredictions = predictions.length;
              final pneumoniaCases = predictions
                  .where((p) => p.result == PredictionResult.PNEUMONIA)
                  .length;

              // Simple mock accuracy logic for now, or could calculate from history
              const accuracy = "94%";

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Overview",
                      style: AppTypography.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 1.4,
                      children: [
                        StatisticsCard(
                          title: "Total Users",
                          value: totalUsers.toString(),
                          icon: Icons.people,
                          color: AppColors.primary,
                        ),
                        GestureDetector(
                          onTap: () => context.push('/admin_scans'),
                          child: StatisticsCard(
                            title: "Total Scans",
                            value: totalPredictions.toString(),
                            icon: Icons.analytics,
                            color: AppColors.accent,
                          ),
                        ),
                        StatisticsCard(
                          title: "Pneumonia Cases",
                          value: pneumoniaCases.toString(),
                          icon: Icons.sick,
                          color: AppColors.error,
                        ),
                        StatisticsCard(
                          title: "Accuracy",
                          value: accuracy,
                          icon: Icons.check_circle,
                          color: AppColors.secondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    GestureDetector(
                      onTap: () {
                        context.push('/user_management');
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.manage_accounts,
                                  color: AppColors.primary),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              "Manage Users",
                              style: AppTypography.textTheme.titleLarge,
                            ),
                            const Spacer(),
                            const Icon(Icons.arrow_forward_ios,
                                size: 16, color: AppColors.textSecondary),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    RecentPredictionsList(predictions: predictions),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Text("Error loading predictions: $error"),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text("Error loading users: $error"),
        ),
      ),
    );
  }
}
