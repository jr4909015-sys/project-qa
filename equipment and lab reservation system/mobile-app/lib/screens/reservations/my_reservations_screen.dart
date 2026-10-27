import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/reservation_model.dart';
import '../../providers/reservation_provider.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/reservation_card.dart';

class MyReservationsScreen extends StatefulWidget {
  const MyReservationsScreen({super.key});

  @override
  State<MyReservationsScreen> createState() => _MyReservationsScreenState();
}

class _MyReservationsScreenState extends State<MyReservationsScreen> {
  String _status = 'all';
  DateTimeRange? _dateRange;

  List<ReservationModel> _filter(List<ReservationModel> reservations) {
    return reservations.where((reservation) {
      final statusMatches = _status == 'all' || reservation.status == _status;
      final start = reservation.startAt.toLocal();
      final rangeMatches =
          _dateRange == null ||
          (!start.isBefore(_dateRange!.start) &&
              start.isBefore(_dateRange!.end.add(const Duration(days: 1))));
      return statusMatches && rangeMatches;
    }).toList();
  }

  Future<void> _pickDates() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      initialDateRange: _dateRange,
    );
    if (range != null) setState(() => _dateRange = range);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ReservationProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('My reservations')),
    body: Consumer<ReservationProvider>(
      builder: (context, state, _) {
        if (state.isLoading) return const LoadingWidget();
        if (state.error != null) {
          return Center(
            child: Text('Could not load reservations: ${state.error}'),
          );
        }
        final rows = _filter(state.reservations);
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _status,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: const [
                        DropdownMenuItem(
                          value: 'all',
                          child: Text('All statuses'),
                        ),
                        DropdownMenuItem(
                          value: 'pending',
                          child: Text('Submitted'),
                        ),
                        DropdownMenuItem(
                          value: 'approved',
                          child: Text('Approved'),
                        ),
                        DropdownMenuItem(
                          value: 'declined',
                          child: Text('Rejected'),
                        ),
                        DropdownMenuItem(
                          value: 'completed',
                          child: Text('Completed'),
                        ),
                        DropdownMenuItem(
                          value: 'cancelled',
                          child: Text('Cancelled'),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => _status = value ?? 'all'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: _dateRange == null
                        ? 'Filter by date'
                        : 'Change date filter',
                    onPressed: _pickDates,
                    icon: const Icon(Icons.date_range),
                  ),
                  if (_dateRange != null)
                    IconButton(
                      tooltip: 'Clear date filter',
                      onPressed: () => setState(() => _dateRange = null),
                      icon: const Icon(Icons.close),
                    ),
                ],
              ),
            ),
            if (_dateRange != null)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  '${MaterialLocalizations.of(context).formatMediumDate(_dateRange!.start)} – '
                  '${MaterialLocalizations.of(context).formatMediumDate(_dateRange!.end)}',
                ),
              ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: state.load,
                child: rows.isEmpty
                    ? ListView(
                        children: [
                          const SizedBox(height: 100),
                          Center(
                            child: Text(
                              state.reservations.isEmpty
                                  ? 'No reservations yet.'
                                  : 'No reservations match these filters.',
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: rows.length,
                        itemBuilder: (context, index) {
                          final reservation = rows[index];
                          final canCancel =
                              reservation.status == 'pending' ||
                              reservation.status == 'approved';
                          return ReservationCard(
                            reservation: reservation,
                            onTap: () => Navigator.pushNamed(
                              context,
                              '/reservations/${reservation.id}',
                            ),
                            onCancel: canCancel
                                ? () async {
                                    try {
                                      await state.cancel(reservation.id);
                                    } catch (error) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Cancellation failed: $error',
                                                ),
                                              ),
                                            );
                                      }
                                    }
                                  }
                                : null,
                          );
                        },
                      ),
              ),
            ),
          ],
        );
      },
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => Navigator.pushNamed(context, '/reservations/create'),
      icon: const Icon(Icons.add),
      label: const Text('Reserve'),
    ),
  );
}
