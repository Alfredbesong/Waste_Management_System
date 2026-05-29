import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../shared/models/waste_report.dart';
import '../../../shared/services/session_store.dart';
import '../../auth/presentation/login_page.dart';
import '../../auth/presentation/register_page.dart';
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
  bool _hasSession = true;

  @override
  void initState() {
    super.initState();
    _reportsFuture = _loadReports();
  }

  Future<List<WasteReport>> _loadReports() async {
    await SessionStore.instance.load();
    if (SessionStore.instance.accessToken == null) {
      _hasSession = false;
      return const [];
    }

    _hasSession = true;
    return _reportService.fetchReports();
  }

  Future<void> _refresh() async {
    setState(() {
      _reportsFuture = _loadReports();
    });

    await _reportsFuture;
  }

  Future<bool> _confirmDelete(WasteReport report) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete report?'),
        content: Text('Delete report #${report.id}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) {
      return false;
    }

    try {
      await _reportService.deleteReport(report.id);
      if (!mounted) return false;

      setState(() {
        _reportsFuture = _loadReports();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report deleted successfully.')),
      );
      return true;
    } catch (error) {
      if (!mounted) return false;
      final message = error is ApiException ? error.message : error.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $message')),
      );
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: FutureBuilder<List<WasteReport>>(
        future: _reportsFuture,
        builder: (context, snapshot) {
          if (!_hasSession) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_outline, size: 72),
                    const SizedBox(height: 16),
                    Text(
                      'Login required',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Sign in to view your real report progress and status updates.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => Navigator.pushNamed(context, LoginPage.routeName),
                      child: const Text('Login'),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.tonal(
                      onPressed: () => Navigator.pushNamed(context, RegisterPage.routeName),
                      child: const Text('Register'),
                    ),
                  ],
                ),
              ),
            );
          }

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
              separatorBuilder: (_, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final report = reports[index];

                return Dismissible(
                  key: ValueKey(report.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.delete_outline,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                  confirmDismiss: (_) => _confirmDelete(report),
                  child: Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(20),
                      title: Text(report.description),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${report.reporterUsername} - ${report.statusLabel} - ${report.latitude}, ${report.longitude}',
                            ),
                            const SizedBox(height: 10),
                            LinearProgressIndicator(
                              value: report.progressPercent / 100,
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            const SizedBox(height: 6),
                            Text('Progress: ${report.progressPercent}%'),
                          ],
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        final deleted = await Navigator.pushNamed(
                          context,
                          ReportDetailPage.routeName,
                          arguments: report,
                        );
                        if (deleted == true && mounted) {
                          await _refresh();
                        }
                      },
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
