import 'package:flutter/material.dart';

import '../../../shared/models/waste_report.dart';
import '../../../shared/services/session_store.dart';
import '../../reports/data/report_service.dart';
import '../data/confirmation_service.dart';

class ConfirmationPage extends StatefulWidget {
  const ConfirmationPage({super.key});

  static const routeName = '/confirmation';

  @override
  State<ConfirmationPage> createState() => _ConfirmationPageState();
}

class _ConfirmationPageState extends State<ConfirmationPage> {
  final _reportService = ReportService();
  final _confirmationService = ConfirmationService();

  List<WasteReport> _reports = const [];
  WasteReport? _selectedReport;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    await SessionStore.instance.load();
    if (!mounted) return;

    if (SessionStore.instance.accessToken == null) {
      setState(() {
        _reports = WasteReport.sampleReports();
        _selectedReport = _reports.first;
        _isLoading = false;
      });
      return;
    }

    try {
      final reports = await _reportService.fetchReports();
      if (!mounted) return;
      setState(() {
        _reports = reports;
        _selectedReport = reports.isNotEmpty ? reports.first : null;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _reports = WasteReport.sampleReports();
        _selectedReport = _reports.first;
        _isLoading = false;
      });
    }
  }

  Future<void> _confirm(bool isCleared) async {
    final report = _selectedReport;
    if (report == null) return;

    try {
      await _confirmationService.submitConfirmation(
        reportId: report.id,
        isCleared: isCleared,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isCleared ? 'Marked as cleared.' : 'Marked as not cleared.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Confirmation failed: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Clearance')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select a report and confirm whether the waste is cleared.'),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<WasteReport>(
                    initialValue: _selectedReport,
                    items: _reports
                        .map(
                          (report) => DropdownMenuItem(
                            value: report,
                            child: Text('#${report.id} - ${report.statusLabel}'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedReport = value;
                      });
                    },
                    decoration: const InputDecoration(labelText: 'Report'),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: _selectedReport == null ? null : () => _confirm(true),
                          child: const Text('YES'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.tonal(
                          onPressed: _selectedReport == null ? null : () => _confirm(false),
                          child: const Text('NO'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
