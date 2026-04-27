import 'package:flutter/material.dart';

import '../../../shared/models/waste_report.dart';
import '../../../shared/services/session_store.dart';
import '../data/report_service.dart';
import 'report_detail_page.dart';

class ReportListPage extends StatefulWidget {
  const ReportListPage({super.key});

  static const routeName = '/reports';

  @override
  State<ReportListPage> createState() => _ReportListPageState();
}

class _ReportListPageState extends State<ReportListPage> {
  final _reportService = ReportService();
  late Future<List<WasteReport>> _reportsFuture;

  @override
  void initState() {
    super.initState();
    _reportsFuture = _loadReports();
  }

  Future<List<WasteReport>> _loadReports() async {
    await SessionStore.instance.load();
    if (SessionStore.instance.accessToken == null) {
      return WasteReport.sampleReports();
    }

    return _reportService.fetchReports();
  }

  Future<void> _refresh() async {
    setState(() {
      _reportsFuture = _loadReports();
    });

    await _reportsFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: FutureBuilder<List<WasteReport>>(
        future: _reportsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Failed to load reports: ${snapshot.error}'));
          }

          final reports = snapshot.data ?? const [];

          if (reports.isEmpty) {
            return const Center(child: Text('No reports found yet.'));
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: reports.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final report = reports[index];

                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(20),
                    title: Text(report.description),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '${report.reporterUsername} · ${report.statusLabel} · ${report.latitude}, ${report.longitude}',
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.pushNamed(
                      context,
                      ReportDetailPage.routeName,
                      arguments: report,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
