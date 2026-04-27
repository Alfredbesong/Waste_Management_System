import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../shared/widgets/section_card.dart';
import '../../auth/presentation/login_page.dart';
import '../../auth/presentation/profile_page.dart';
import '../../auth/presentation/register_page.dart';
import '../../confirmation/presentation/confirmation_page.dart';
import '../../reports/presentation/report_form_page.dart';
import '../../reports/presentation/report_list_page.dart' show ReportListPage;

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.tertiary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.appName,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppStrings.appSubtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.92),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        FilledButton(
                          onPressed: () => Navigator.pushNamed(
                            context,
                            ReportFormPage.routeName,
                          ),
                          child: const Text('Report Waste'),
                        ),
                        FilledButton.tonal(
                          onPressed: () => Navigator.pushNamed(
                            context,
                            ReportListPage.routeName,
                          ),
                          child: const Text('View Reports'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text('Quick Actions', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              SectionCard(
                title: 'Create a report',
                subtitle: 'Submit photo, description, and location.',
                onTap: () =>
                    Navigator.pushNamed(context, ReportFormPage.routeName),
              ),
              SectionCard(
                title: 'Check report status',
                subtitle: 'Track reports from Reported to Resolved.',
                onTap: () =>
                    Navigator.pushNamed(context, ReportListPage.routeName),
              ),
              SectionCard(
                title: 'Confirm clearance',
                subtitle: 'Tell us if the waste has actually been cleared.',
                onTap: () =>
                    Navigator.pushNamed(context, ConfirmationPage.routeName),
              ),
              const SizedBox(height: 20),
              Text('Authentication', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              SectionCard(
                title: 'Login',
                subtitle: 'Citizen account access for report tracking.',
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(context, LoginPage.routeName),
              ),
              SectionCard(
                title: 'Register',
                subtitle: 'Create a new account before reporting waste.',
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    Navigator.pushNamed(context, RegisterPage.routeName),
              ),
              SectionCard(
                title: 'Profile',
                subtitle: 'View your info, logout, or delete your account.',
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(context, ProfilePage.routeName),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
