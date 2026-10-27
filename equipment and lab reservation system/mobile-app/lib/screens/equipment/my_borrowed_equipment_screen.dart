import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/equipment_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/equipment_service.dart';

class MyBorrowedEquipmentScreen extends StatefulWidget {
  const MyBorrowedEquipmentScreen({super.key});

  @override
  State<MyBorrowedEquipmentScreen> createState() =>
      _MyBorrowedEquipmentScreenState();
}

class _MyBorrowedEquipmentScreenState extends State<MyBorrowedEquipmentScreen> {
  late Future<List<Map<String, dynamic>>> _loans;
  final _service = EquipmentService();

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _loans = _service.myLoans();
  }

  Future<void> _confirmReturn(Map<String, dynamic> loan) async {
    final condition = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Confirm equipment return'),
        children: [
          for (final value in ['good', 'fair', 'damaged', 'maintenance'])
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, value),
              child: Text(
                'Returned in ${_conditionLabel(value).toLowerCase()} condition',
              ),
            ),
        ],
      ),
    );
    if (condition == null) return;
    try {
      await _service.returnItem(loan['id'] as int, condition);
      if (mounted) setState(_reload);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Return could not be recorded: $error')),
        );
      }
    }
  }

  Future<void> _checkOut() async {
    List<EquipmentModel> equipment;
    List<Map<String, dynamic>> users;
    try {
      final results = await Future.wait([_service.list(), _service.users()]);
      equipment = (results[0] as List<EquipmentModel>)
          .where(
            (item) =>
                (item.availableQuantity ?? item.quantity) > 0 &&
                item.condition != 'damaged' &&
                item.condition != 'maintenance',
          )
          .toList();
      users = results[1] as List<Map<String, dynamic>>;
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load check-out options: $error')),
      );
      return;
    }

    if (!mounted) return;
    if (equipment.isEmpty || users.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            equipment.isEmpty
                ? 'No available equipment can be checked out.'
                : 'No active borrowers are available.',
          ),
        ),
      );
      return;
    }

    EquipmentModel selectedEquipment = equipment.first;
    Map<String, dynamic> selectedUser = users.first;
    DateTime dueAt = DateTime.now().add(const Duration(days: 1));
    final quantityController = TextEditingController(text: '1');
    final reservationController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var isSaving = false;
    String? error;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Check out equipment'),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<EquipmentModel>(
                      initialValue: selectedEquipment,
                      decoration: const InputDecoration(labelText: 'Equipment'),
                      items: equipment
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(
                                '${item.name} · ${item.availableQuantity ?? item.quantity} available',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: isSaving
                          ? null
                          : (value) {
                              if (value != null) {
                                setDialogState(() => selectedEquipment = value);
                              }
                            },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<Map<String, dynamic>>(
                      initialValue: selectedUser,
                      decoration: const InputDecoration(labelText: 'Borrower'),
                      items: users
                          .map(
                            (user) => DropdownMenuItem(
                              value: user,
                              child: Text(
                                '${user['username']} · ${user['role_name'] ?? 'student'}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: isSaving
                          ? null
                          : (value) {
                              if (value != null) {
                                setDialogState(() => selectedUser = value);
                              }
                            },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: quantityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Quantity'),
                      validator: (value) {
                        final quantity = int.tryParse(value ?? '');
                        final available =
                            selectedEquipment.availableQuantity ??
                            selectedEquipment.quantity;
                        if (quantity == null || quantity < 1) {
                          return 'Enter a quantity of at least one';
                        }
                        if (quantity > available) {
                          return 'Only $available units are available';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Due date and time'),
                      subtitle: Text(
                        MaterialLocalizations.of(context).formatFullDate(dueAt),
                      ),
                      trailing: const Icon(Icons.calendar_month_outlined),
                      onTap: isSaving
                          ? null
                          : () async {
                              final date = await showDatePicker(
                                context: dialogContext,
                                initialDate: dueAt,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365),
                                ),
                              );
                              if (date == null || !dialogContext.mounted) {
                                return;
                              }
                              final time = await showTimePicker(
                                context: dialogContext,
                                initialTime: TimeOfDay.fromDateTime(dueAt),
                              );
                              if (time == null) return;
                              setDialogState(() {
                                dueAt = DateTime(
                                  date.year,
                                  date.month,
                                  date.day,
                                  time.hour,
                                  time.minute,
                                );
                              });
                            },
                    ),
                    TextFormField(
                      controller: reservationController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Reservation ID (optional)',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return null;
                        return int.tryParse(value) == null
                            ? 'Enter a valid reservation ID'
                            : null;
                      },
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() {
                        isSaving = true;
                        error = null;
                      });
                      try {
                        final reservationId = int.tryParse(
                          reservationController.text,
                        );
                        await _service.checkOut({
                          'equipment': selectedEquipment.id,
                          'borrower': selectedUser['id'] as int,
                          'quantity': int.parse(quantityController.text),
                          'due_at': dueAt.toUtc().toIso8601String(),
                          'reservation': reservationId,
                        });
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }
                        if (mounted) setState(_reload);
                      } catch (exception) {
                        if (dialogContext.mounted) {
                          setDialogState(() {
                            isSaving = false;
                            error =
                                'Check-out could not be recorded: $exception';
                          });
                        }
                      }
                    },
              child: isSaving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Record check-out'),
            ),
          ],
        ),
      ),
    );
    quantityController.dispose();
    reservationController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().user?.role;
    final canManageLoans = role == 'staff' || role == 'admin';
    return Scaffold(
      appBar: AppBar(title: const Text('Borrowed equipment')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _loans,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Loan list could not be loaded.'));
          }
          final loans = snapshot.data ?? [];
          if (loans.isEmpty) {
            return const Center(child: Text('No equipment loans found.'));
          }
          return RefreshIndicator(
            onRefresh: () async => setState(_reload),
            child: ListView.builder(
              itemCount: loans.length,
              itemBuilder: (context, index) {
                final loan = loans[index];
                final returned = loan['returned_at'] != null;
                final isOverdue = loan['is_overdue'] == true;
                return ListTile(
                  title: Text(loan['equipment_name'] as String? ?? 'Equipment'),
                  subtitle: Text(
                    'Due ${DateTime.parse(loan['due_at'] as String).toLocal()} · Quantity ${loan['quantity']}'
                    '${loan['borrower_name'] == null ? '' : ' · ${loan['borrower_name']}'}',
                  ),
                  trailing: returned
                      ? Text(
                          'Returned: ${_conditionLabel(loan['return_condition'] as String? ?? '')}',
                        )
                      : canManageLoans
                      ? TextButton(
                          onPressed: () => _confirmReturn(loan),
                          child: const Text('Confirm return'),
                        )
                      : Text(isOverdue ? 'Overdue' : 'On loan'),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: canManageLoans
          ? FloatingActionButton.extended(
              onPressed: _checkOut,
              icon: const Icon(Icons.add),
              label: const Text('Check out'),
            )
          : null,
    );
  }

  String _conditionLabel(String condition) => switch (condition) {
    'good' => 'Good',
    'fair' => 'Fair',
    'damaged' => 'Damaged',
    'maintenance' => 'Under maintenance',
    _ => 'Unknown',
  };
}
