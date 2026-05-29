import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../shared/models/waste_report.dart';
import '../data/report_service.dart';

class ReportDetailPage extends StatefulWidget {
  const ReportDetailPage({super.key, required this.report});

  static const routeName = '/report-detail';

  final WasteReport report;

  @override
  State<ReportDetailPage> createState() => _ReportDetailPageState();
}

class _ReportDetailPageState extends State<ReportDetailPage> {
  final _reportService = ReportService();
  bool _isDeleting = false;

  Future<void> _deleteReport() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete report?'),
        content: Text('Delete report #${widget.report.id}? This action cannot be undone.'),
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

    if (confirmed != true) return;

    setState(() => _isDeleting = true);

    try {
      await _reportService.deleteReport(widget.report.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report deleted successfully.')),
      );
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      final message = error is ApiException ? error.message : error.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $message')),
      );
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Report #${widget.report.id}'),
        actions: [
          IconButton(
            onPressed: _isDeleting ? null : _deleteReport,
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete report',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.report.description, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text('Reporter: ${widget.report.reporterUsername}'),
            Text('Status: ${widget.report.statusLabel}'),
            Text('Location: ${widget.report.latitude}, ${widget.report.longitude}'),
            const SizedBox(height: 16),
            _ProgressCard(report: widget.report),
            const SizedBox(height: 16),
            if (widget.report.photoUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.network(
                  _reportService.resolveMediaUrl(widget.report.photoUrl),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const _EmptyPhotoCard(
                    message: 'The uploaded photo could not be loaded right now.',
                  ),
                ),
              )
            else
              const _EmptyPhotoCard(message: 'No photo was attached to this report.'),
          ],
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.report});

  final WasteReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final steps = ['Reported', 'In Progress', 'Resolved'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Report progress', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: report.progressPercent / 100,
              minHeight: 10,
              borderRadius: BorderRadius.circular(999),
            ),
            const SizedBox(height: 10),
            Text('${report.progressPercent}% complete'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(steps.length, (index) {
                final isDone = index < report.progressStep;
                return Chip(
                  label: Text(steps[index]),
                  backgroundColor: isDone
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surfaceContainerHighest,
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPhotoCard extends StatelessWidget {
  const _EmptyPhotoCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Text(message),
    );
  }
}
