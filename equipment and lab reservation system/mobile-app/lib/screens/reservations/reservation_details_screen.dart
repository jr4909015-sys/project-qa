import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../models/reservation_model.dart';
import '../../services/reservation_service.dart';
import '../../widgets/loading_widget.dart';

class ReservationDetailsScreen extends StatefulWidget {
  const ReservationDetailsScreen({super.key, required this.id});

  final int id;

  @override
  State<ReservationDetailsScreen> createState() =>
      _ReservationDetailsScreenState();
}

class _ReservationDetailsScreenState extends State<ReservationDetailsScreen> {
  final _service = ReservationService();
  late Future<ReservationModel?> _reservation;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => _reservation = _service.get(widget.id);

  String _dateTime(DateTime? value) => value == null
      ? 'Waiting for review'
      : value.toLocal().toString().substring(0, 16);

  String _statusLabel(String status) {
    switch (status) {
      case 'declined':
        return 'Rejected';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status.isEmpty
            ? 'Awaiting decision'
            : '${status[0].toUpperCase()}${status.substring(1)}';
    }
  }

  Future<void> _requestReschedule(ReservationModel reservation) async {
    final date = await showDatePicker(
      context: context,
      initialDate: reservation.startAt.toLocal().isAfter(DateTime.now())
          ? reservation.startAt.toLocal()
          : DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final startTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(reservation.startAt.toLocal()),
    );
    if (startTime == null || !mounted) return;
    final endTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(reservation.endAt.toLocal()),
    );
    if (endTime == null || !mounted) return;
    final startAt = DateTime(
      date.year,
      date.month,
      date.day,
      startTime.hour,
      startTime.minute,
    );
    final endAt = DateTime(
      date.year,
      date.month,
      date.day,
      endTime.hour,
      endTime.minute,
    );
    if (!endAt.isAfter(startAt)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time.')),
      );
      return;
    }
    try {
      await _service.requestReschedule(
        reservation.id,
        startAt: startAt,
        endAt: endAt,
      );
      if (!mounted) return;
      setState(_reload);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Schedule change submitted for staff approval.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Schedule change was not submitted: $error')),
      );
    }
  }

  Future<void> _copyConfirmation(ReservationModel reservation) async {
    final confirmation = [
      'Campus Reserve confirmation',
      'Reservation: ${reservation.confirmationNumber}',
      'Resource: ${reservation.resourceName}',
      'Schedule: ${_dateTime(reservation.startAt)} – ${_dateTime(reservation.endAt)}',
      'Purpose: ${reservation.purpose}',
      'Status: ${_statusLabel(reservation.status)}',
      if (reservation.remarks.isNotEmpty)
        'Review remarks: ${reservation.remarks}',
    ].join('\n');
    await Clipboard.setData(ClipboardData(text: confirmation));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Confirmation copied. You can print it from another app.',
          ),
        ),
      );
    }
  }

  Future<void> _printConfirmation(ReservationModel reservation) async {
    final document = pw.Document();
    document.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Campus Reserve confirmation',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 20),
            pw.Text('Reservation: ${reservation.confirmationNumber}'),
            pw.Text('Resource: ${reservation.resourceName}'),
            pw.Text(
              'Schedule: ${_dateTime(reservation.startAt)} - ${_dateTime(reservation.endAt)}',
            ),
            pw.Text('Purpose: ${reservation.purpose}'),
            pw.Text('Status: ${_statusLabel(reservation.status)}'),
            if (reservation.remarks.isNotEmpty)
              pw.Text('Review remarks: ${reservation.remarks}'),
          ],
        ),
      ),
    );
    await Printing.layoutPdf(onLayout: (_) => document.save());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Reservation details')),
    body: FutureBuilder<ReservationModel?>(
      future: _reservation,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingWidget();
        }
        if (snapshot.hasError || snapshot.data == null) {
          return const Center(
            child: Text('Reservation details are unavailable.'),
          );
        }
        final reservation = snapshot.data!;
        final canReschedule =
            (reservation.status == 'pending' ||
                reservation.status == 'approved') &&
            reservation.rescheduleStatus != 'pending';
        final timeline = <(String, DateTime?, bool)>[
          ('Submitted', reservation.createdAt, true),
          (
            'Under review',
            reservation.reviewedAt,
            reservation.reviewedAt != null || reservation.status == 'pending',
          ),
          (
            reservation.status == 'declined'
                ? 'Rejected'
                : reservation.status == 'cancelled'
                ? 'Cancelled'
                : 'Approved',
            reservation.reviewedAt ?? reservation.cancelledAt,
            reservation.status == 'approved' ||
                reservation.status == 'declined' ||
                reservation.status == 'completed' ||
                reservation.status == 'cancelled',
          ),
          (
            'Completed',
            reservation.completedAt,
            reservation.completedAt != null,
          ),
        ];
        return ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Text(
              reservation.resourceName,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            SelectableText(
              'Confirmation ${reservation.confirmationNumber}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text('Current status: ${_statusLabel(reservation.status)}'),
            const SizedBox(height: 12),
            const Text('Reservation progress'),
            for (final (label, date, reached) in timeline)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  reached ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: reached ? Theme.of(context).colorScheme.primary : null,
                ),
                title: Text(label),
                subtitle: date == null ? null : Text(_dateTime(date)),
              ),
            if (reservation.status == 'declined' &&
                reservation.remarks.isNotEmpty)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Reason for rejection'),
                subtitle: Text(reservation.remarks),
              ),
            const Divider(),
            Text(
              'Schedule: ${_dateTime(reservation.startAt)} – ${_dateTime(reservation.endAt)}',
            ),
            Text(
              'Quantity ${reservation.quantity} · Attendees ${reservation.attendees}',
            ),
            Text('Purpose: ${reservation.purpose}'),
            if (reservation.remarks.isNotEmpty &&
                reservation.status != 'declined')
              Text('Review remarks: ${reservation.remarks}'),
            if (reservation.rescheduleStatus == 'pending') ...[
              const SizedBox(height: 12),
              Text(
                'Schedule change awaiting staff approval: '
                '${_dateTime(reservation.proposedStartAt)} – '
                '${_dateTime(reservation.proposedEndAt)}',
              ),
            ],
            if (reservation.rescheduleStatus == 'declined' &&
                reservation.rescheduleRemarks.isNotEmpty)
              Text(
                'Schedule change rejected: ${reservation.rescheduleRemarks}',
              ),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: () => _printConfirmation(reservation),
              icon: const Icon(Icons.print_outlined),
              label: const Text('Print / save confirmation'),
            ),
            OutlinedButton.icon(
              onPressed: () => _copyConfirmation(reservation),
              icon: const Icon(Icons.copy_outlined),
              label: const Text('Copy confirmation details'),
            ),
            if (canReschedule)
              FilledButton.tonalIcon(
                onPressed: () => _requestReschedule(reservation),
                icon: const Icon(Icons.edit_calendar_outlined),
                label: const Text('Request schedule change'),
              ),
          ],
        );
      },
    ),
  );
}
