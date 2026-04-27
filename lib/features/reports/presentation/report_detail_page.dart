import 'package:flutter/material.dart';

import '../../../shared/models/waste_report.dart';

class ReportDetailPage extends StatelessWidget {
  const ReportDetailPage({super.key, required this.report});

  static const routeName = '/report-detail';

  final WasteReport report;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Report #${report.id}')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(report.description, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text('Reporter: ${report.reporterUsername}'),
            Text('Status: ${report.statusLabel}'),
            Text('Location: ${report.latitude}, ${report.longitude}'),
            const SizedBox(height: 16),
            const Text('A real dashboard can show the uploaded photo and admin actions here.'),
          ],
        ),
      ),
    );
  }
}
