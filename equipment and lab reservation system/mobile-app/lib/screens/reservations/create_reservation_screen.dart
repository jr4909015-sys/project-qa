import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/equipment_model.dart';
import '../../models/laboratory_model.dart';
import '../../services/equipment_service.dart';
import '../../services/laboratory_service.dart';
import '../../services/reservation_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/loading_widget.dart';

class CreateReservationScreen extends StatefulWidget {
  const CreateReservationScreen({super.key});

  @override
  State<CreateReservationScreen> createState() =>
      _CreateReservationScreenState();
}

class _CreateReservationScreenState extends State<CreateReservationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _purpose = TextEditingController();
  final _quantity = TextEditingController(text: '1');
  final _attendees = TextEditingController(text: '1');
  List<EquipmentModel> _equipment = [];
  List<LaboratoryModel> _laboratories = [];
  String _type = 'equipment';
  int? _equipmentId;
  int? _laboratoryId;
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  Map<String, dynamic>? _availability;
  bool _loadingAvailability = false;
  Timer? _availabilityTimer;
  int _availabilityRequest = 0;
  bool _busy = false;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadResources();
  }

  Future<void> _loadResources() async {
    try {
      final result = await Future.wait([
        EquipmentService().list(),
        LaboratoryService().list(),
      ]);
      if (!mounted) return;
      setState(() {
        _equipment = result[0] as List<EquipmentModel>;
        _laboratories = result[1] as List<LaboratoryModel>;
        _loading = false;
      });
      _loadAvailability();
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString();
          _loading = false;
        });
      }
    }
  }

  void _loadAvailability() {
    _availabilityTimer?.cancel();
    final request = ++_availabilityRequest;
    final id = _type == 'equipment' ? _equipmentId : _laboratoryId;
    if (id == null) {
      setState(() {
        _availability = null;
        _loadingAvailability = false;
      });
      return;
    }
    setState(() {
      _loadingAvailability = true;
      _availability = null;
      _error = null;
    });
    final resourceType = _type;
    final date = _date;
    final quantity = resourceType == 'equipment'
        ? int.tryParse(_quantity.text) ?? 1
        : 1;
    _availabilityTimer = Timer(const Duration(milliseconds: 250), () async {
      try {
        final availability = await ReservationService().availability(
          resourceType: resourceType,
          resourceId: id,
          date: date,
          quantity: quantity,
        );
        if (mounted && request == _availabilityRequest) {
          setState(() => _availability = availability);
        }
      } catch (error) {
        if (mounted && request == _availabilityRequest) {
          setState(() => _error = 'Could not check availability: $error');
        }
      } finally {
        if (mounted && request == _availabilityRequest) {
          setState(() => _loadingAvailability = false);
        }
      }
    });
  }

  bool _selectedRangeAvailable(DateTime start, DateTime end) {
    final slots = _availability?['slots'];
    if (slots is! List || !end.isAfter(start)) return false;
    var cursor = start;
    for (final item in slots.whereType<Map<String, dynamic>>()) {
      final slotStart = DateTime.parse(item['start_at'] as String).toLocal();
      final slotEnd = DateTime.parse(item['end_at'] as String).toLocal();
      if (!slotEnd.isAfter(cursor) || !slotStart.isBefore(end)) continue;
      if (slotStart.isAfter(cursor) || item['status'] != 'available') {
        return false;
      }
      cursor = slotEnd.isAfter(end) ? end : slotEnd;
      if (!cursor.isBefore(end)) return true;
    }
    return false;
  }

  @override
  void dispose() {
    _availabilityTimer?.cancel();
    _purpose.dispose();
    _quantity.dispose();
    _attendees.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final id = _type == 'equipment' ? _equipmentId : _laboratoryId;
    if (id == null) return;
    setState(() => _busy = true);
    final start = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _startTime.hour,
      _startTime.minute,
    );
    final end = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _endTime.hour,
      _endTime.minute,
    );
    if (!end.isAfter(start)) {
      setState(() {
        _busy = false;
        _error = 'End time must be after start time.';
      });
      return;
    }
    if (_availability != null && !_selectedRangeAvailable(start, end)) {
      setState(() {
        _busy = false;
        _error = 'That time conflicts with the availability calendar. Choose an available time.';
      });
      return;
    }
    try {
      await ReservationService().create({
        'equipment': _type == 'equipment' ? id : null,
        'laboratory': _type == 'laboratory' ? id : null,
        'start_at': start.toUtc().toIso8601String(),
        'end_at': end.toUtc().toIso8601String(),
        'purpose': _purpose.text.trim(),
        'quantity': _type == 'equipment'
            ? int.tryParse(_quantity.text) ?? 1
            : 1,
        'attendees': int.tryParse(_attendees.text) ?? 1,
      });
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) setState(() => _error = 'Could not submit request: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('New reservation')),
    body: _loading
        ? const LoadingWidget()
        : Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _type,
                  decoration: const InputDecoration(labelText: 'Resource type'),
                  items: const [
                    DropdownMenuItem(
                      value: 'equipment',
                      child: Text('Equipment'),
                    ),
                    DropdownMenuItem(
                      value: 'laboratory',
                      child: Text('Laboratory'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _type = value ?? 'equipment';
                      _equipmentId = null;
                      _laboratoryId = null;
                    });
                    _loadAvailability();
                  },
                ),
                const SizedBox(height: 12),
                if (_type == 'equipment')
                  DropdownButtonFormField<int>(
                    initialValue:
                        _equipment.any((item) => item.id == _equipmentId)
                        ? _equipmentId
                        : null,
                    decoration: const InputDecoration(labelText: 'Equipment'),
                    items: _equipment
                        .map(
                          (item) => DropdownMenuItem(
                            value: item.id,
                            enabled:
                                (item.availableQuantity ?? item.quantity) > 0,
                            child: Text(
                              '${item.name} · ${item.availableQuantity ?? item.quantity} available',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() => _equipmentId = value);
                      _loadAvailability();
                    },
                    validator: (value) =>
                        value == null ? 'Choose equipment' : null,
                  )
                else
                  DropdownButtonFormField<int>(
                    initialValue:
                        _laboratories.any((item) => item.id == _laboratoryId)
                        ? _laboratoryId
                        : null,
                    decoration: const InputDecoration(labelText: 'Laboratory'),
                    items: _laboratories
                        .map(
                          (room) => DropdownMenuItem(
                            value: room.id,
                            child: Text(
                              '${room.name} · ${room.capacity} seats',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() => _laboratoryId = value);
                      _loadAvailability();
                    },
                    validator: (value) =>
                        value == null ? 'Choose a laboratory' : null,
                  ),
                if (_type == 'equipment')
                  TextFormField(
                    controller: _quantity,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Quantity'),
                    onChanged: (_) => _loadAvailability(),
                    validator: (value) =>
                        int.tryParse(value ?? '') == null ||
                            int.parse(value!) < 1
                        ? 'Enter at least one unit'
                        : null,
                  ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Reservation date'),
                  subtitle: Text(
                    MaterialLocalizations.of(context).formatMediumDate(_date),
                  ),
                  trailing: const Icon(Icons.calendar_month_outlined),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() => _date = picked);
                      _loadAvailability();
                    }
                  },
                ),
                if (_loadingAvailability)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_availability != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Availability calendar',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Text(
                    '30-minute times. Select a green slot to start a reservation; final availability is verified when submitted.',
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: (_availability!['slots'] as List)
                        .whereType<Map<String, dynamic>>()
                        .map((slot) {
                          final slotStart = DateTime.parse(
                            slot['start_at'] as String,
                          ).toLocal();
                          final isAvailable = slot['status'] == 'available';
                          final isSelected =
                              slotStart.hour == _startTime.hour &&
                              slotStart.minute == _startTime.minute;
                          return ActionChip(
                            backgroundColor: isSelected
                                ? Theme.of(context).colorScheme.primaryContainer
                                : isAvailable
                                ? Colors.green.shade100
                                : Colors.red.shade100,
                            label: Text(
                              '${TimeOfDay.fromDateTime(slotStart).format(context)} · ${isAvailable ? 'Available' : slot['status']}',
                            ),
                            onPressed: isAvailable
                                ? () => setState(() {
                                    _startTime = TimeOfDay.fromDateTime(
                                      slotStart,
                                    );
                                    final next = slotStart.add(
                                      const Duration(minutes: 30),
                                    );
                                    _endTime = TimeOfDay.fromDateTime(next);
                                  })
                                : null,
                          );
                        })
                        .toList(),
                  ),
                ],
                ListTile(
                  title: const Text('Start time'),
                  subtitle: Text(_startTime.format(context)),
                  onTap: () async {
                    final value = await showTimePicker(
                      context: context,
                      initialTime: _startTime,
                    );
                    if (value != null) setState(() => _startTime = value);
                  },
                ),
                ListTile(
                  title: const Text('End time'),
                  subtitle: Text(_endTime.format(context)),
                  onTap: () async {
                    final value = await showTimePicker(
                      context: context,
                      initialTime: _endTime,
                    );
                    if (value != null) setState(() => _endTime = value);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _attendees,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Attendees'),
                  validator: (value) =>
                      int.tryParse(value ?? '') == null || int.parse(value!) < 1
                      ? 'Enter at least one attendee'
                      : null,
                ),
                TextFormField(
                  controller: _purpose,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Purpose'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Describe what you need the resource for'
                      : null,
                ),
                const SizedBox(height: 18),
                if (_error != null)
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                AppButton(
                  label: 'Submit request',
                  busy: _busy,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
  );
}
