class WasteReportStatus {
  static const reported = 'reported';
  static const inProgress = 'in_progress';
  static const resolved = 'resolved';
}

class WasteReport {
  const WasteReport({
    required this.id,
    required this.reporterUsername,
    required this.description,
    required this.photoUrl,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.statusLabel,
    required this.progressPercent,
    required this.progressStep,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String reporterUsername;
  final String description;
  final String photoUrl;
  final double latitude;
  final double longitude;
  final String status;
  final String statusLabel;
  final int progressPercent;
  final int progressStep;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory WasteReport.fromJson(Map<String, dynamic> json) {
    final status = json['status'] as String? ?? WasteReportStatus.reported;

    return WasteReport(
      id: json['id'] as int,
      reporterUsername: json['reporter_username'] as String? ?? 'Unknown',
      description: json['description'] as String? ?? '',
      photoUrl: json['photo'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      status: status,
      statusLabel: json['status_label'] as String? ?? _labelForStatus(status),
      progressPercent: (json['progress_percent'] as num?)?.toInt() ?? _progressForStatus(status),
      progressStep: (json['progress_step'] as num?)?.toInt() ?? _stepForStatus(status),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  static String _labelForStatus(String status) {
    switch (status) {
      case WasteReportStatus.inProgress:
        return 'In Progress';
      case WasteReportStatus.resolved:
        return 'Resolved';
      default:
        return 'Reported';
    }
  }

  static int _progressForStatus(String status) {
    switch (status) {
      case WasteReportStatus.inProgress:
        return 60;
      case WasteReportStatus.resolved:
        return 100;
      default:
        return 20;
    }
  }

  static int _stepForStatus(String status) {
    switch (status) {
      case WasteReportStatus.inProgress:
        return 2;
      case WasteReportStatus.resolved:
        return 3;
      default:
        return 1;
    }
  }

  static List<WasteReport> sampleReports() {
    final now = DateTime.now();

    return [
      WasteReport(
        id: 1,
        reporterUsername: 'demo_user',
        description: 'Waste bags are blocking the road shoulder.',
        photoUrl: '',
        latitude: 4.156,
        longitude: 9.266,
        status: WasteReportStatus.reported,
        statusLabel: 'Reported',
        progressPercent: 20,
        progressStep: 1,
        createdAt: now,
        updatedAt: now,
      ),
      WasteReport(
        id: 2,
        reporterUsername: 'demo_user',
        description: 'Drainage area needs clearing.',
        photoUrl: '',
        latitude: 4.152,
        longitude: 9.261,
        status: WasteReportStatus.inProgress,
        statusLabel: 'In Progress',
        progressPercent: 60,
        progressStep: 2,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }
}
