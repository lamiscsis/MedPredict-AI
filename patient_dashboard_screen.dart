import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../configurations/theme/app_colors.dart';
import '../../../../configurations/theme/app_typography.dart';
import '../../../../services/auth_service.dart';
import 'widgets/health_summary_card.dart';
import 'widgets/quick_action_buttons.dart';
import 'widgets/health_tips_carousel.dart';

class PatientDashboardScreen extends ConsumerWidget {
  const PatientDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final displayName = authState.whenOrNull(
      data: (user) => user?.displayName,
    );
    final greeting = (displayName != null && displayName.isNotEmpty)
        ? displayName.split(' ').first
        : 'there';

    return Scaffold(
      appBar: AppBar(
        title: const Text("MedPredict AI"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false, // Hide back button on dashboard
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              context.push('/profile');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Welcome, $greeting",
              style: AppTypography.textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              "How are you feeling today?",
              style: AppTypography.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            const HealthSummaryCard(),
            const SizedBox(height: 24),
            const QuickActionButtons(),
            const SizedBox(height: 24),
            const HealthTipsCarousel(),
          ],
        ),
      ),
    );
  }
}
