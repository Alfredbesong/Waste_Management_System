import 'package:flutter/material.dart';

import 'package:wastemanagement/core/theme/app_theme.dart';
import 'package:wastemanagement/features/auth/presentation/login_page.dart';
import 'package:wastemanagement/features/auth/presentation/profile_page.dart';
import 'package:wastemanagement/features/auth/presentation/register_page.dart';
import 'package:wastemanagement/features/confirmation/presentation/confirmation_page.dart';
import 'package:wastemanagement/features/home/presentation/home_page.dart';
import 'package:wastemanagement/features/reports/presentation/report_detail_page.dart';
import 'package:wastemanagement/features/reports/presentation/report_form_page.dart';
import 'package:wastemanagement/features/reports/presentation/report_list_page.dart' show ReportListPage;
import 'package:wastemanagement/shared/models/waste_report.dart';
import 'package:wastemanagement/shared/services/theme_store.dart';

class WasteManagementApp extends StatelessWidget {
  const WasteManagementApp({super.key, required this.navigatorKey});

  final GlobalKey<NavigatorState> navigatorKey;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeStore.instance.mode,
      builder: (context, themeMode, _) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'Smart Waste Management',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          home: const HomePage(),
          routes: <String, WidgetBuilder>{
            LoginPage.routeName: (_) => const LoginPage(),
            ProfilePage.routeName: (_) => const ProfilePage(),
            RegisterPage.routeName: (_) => const RegisterPage(),
            ReportFormPage.routeName: (_) => const ReportFormPage(),
            ReportListPage.routeName: (_) => const ReportListPage(),
            ConfirmationPage.routeName: (_) => const ConfirmationPage(),
          },
          onGenerateRoute: (RouteSettings settings) {
            final arguments = settings.arguments;
            if (settings.name == ReportDetailPage.routeName &&
                arguments is WasteReport) {
              return MaterialPageRoute(
                builder: (_) => ReportDetailPage(report: arguments),
              );
            }

            return null;
          },
        );
      },
    );
  }
}
