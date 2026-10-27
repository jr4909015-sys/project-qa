class ReservationModel {
  const ReservationModel({
    required this.id,
    required this.startAt,
    required this.endAt,
    required this.status,
    required this.purpose,
    this.equipmentId,
    this.laboratoryId,
    this.equipmentName = '',
    this.laboratoryName = '',
    this.remarks = '',
    this.quantity = 1,
    this.attendees = 1,
    this.createdAt,
    this.reviewedAt,
    this.completedAt,
    this.cancelledAt,
    this.proposedStartAt,
    this.proposedEndAt,
    this.rescheduleStatus = '',
    this.rescheduleRemarks = '',
    this.rescheduleRequestedAt,
  });

  final int id;
  final DateTime startAt;
  final DateTime endAt;
  final String status;
  final String purpose;
  final int? equipmentId;
  final int? laboratoryId;
  final String equipmentName;
  final String laboratoryName;
  final String remarks;
  final int quantity;
  final int attendees;
  final DateTime? createdAt;
  final DateTime? reviewedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final DateTime? proposedStartAt;
  final DateTime? proposedEndAt;
  final String rescheduleStatus;
  final String rescheduleRemarks;
  final DateTime? rescheduleRequestedAt;

  String get confirmationNumber => 'RSV-${id.toString().padLeft(6, '0')}';
  String get resourceName => equipmentName.isNotEmpty
      ? equipmentName
      : laboratoryName.isNotEmpty
      ? laboratoryName
      : 'Reservation';

  factory ReservationModel.fromJson(Map<String, dynamic> json) =>
      ReservationModel(
        id: json['id'] as int,
        startAt: DateTime.parse(json['start_at'] as String),
        endAt: DateTime.parse(json['end_at'] as String),
        status: json['status'] as String? ?? 'pending',
        purpose: json['purpose'] as String? ?? '',
        equipmentId: json['equipment'] as int?,
        laboratoryId: json['laboratory'] as int?,
        equipmentName: json['equipment_name'] as String? ?? '',
        laboratoryName: json['laboratory_name'] as String? ?? '',
        remarks: json['remarks'] as String? ?? '',
        quantity: json['quantity'] as int? ?? 1,
        attendees: json['attendees'] as int? ?? 1,
        createdAt: _parseDate(json['created_at']),
        reviewedAt: _parseDate(json['reviewed_at']),
        completedAt: _parseDate(json['completed_at']),
        cancelledAt: _parseDate(json['cancelled_at']),
        proposedStartAt: _parseDate(json['proposed_start_at']),
        proposedEndAt: _parseDate(json['proposed_end_at']),
        rescheduleStatus: json['reschedule_status'] as String? ?? '',
        rescheduleRemarks: json['reschedule_remarks'] as String? ?? '',
        rescheduleRequestedAt: _parseDate(json['reschedule_requested_at']),
      );

  static DateTime? _parseDate(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;
}
