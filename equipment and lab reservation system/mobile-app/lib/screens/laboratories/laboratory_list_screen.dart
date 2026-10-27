import 'package:flutter/material.dart';

import '../../models/laboratory_model.dart';
import '../../services/laboratory_service.dart';
import '../../widgets/loading_widget.dart';

class LaboratoryListScreen extends StatefulWidget {
  const LaboratoryListScreen({super.key});

  @override
  State<LaboratoryListScreen> createState() => _LaboratoryListScreenState();
}

class _LaboratoryListScreenState extends State<LaboratoryListScreen> {
  final _search = TextEditingController();
  final _building = TextEditingController();
  final _capacity = TextEditingController();
  late Future<List<LaboratoryModel>> _rooms;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _search.dispose();
    _building.dispose();
    _capacity.dispose();
    super.dispose();
  }

  void _reload() => _rooms = LaboratoryService().list(
    search: _search.text,
    building: _building.text.trim(),
    minimumCapacity: int.tryParse(_capacity.text),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Laboratories')),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _search,
            decoration: InputDecoration(
              labelText: 'Search laboratories',
              suffixIcon: IconButton(
                icon: const Icon(Icons.search),
                onPressed: () => setState(_reload),
              ),
            ),
            onSubmitted: (_) => setState(_reload),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _building,
                  decoration: const InputDecoration(labelText: 'Building'),
                  onSubmitted: (_) => setState(_reload),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _capacity,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Minimum seats'),
                  onSubmitted: (_) => setState(_reload),
                ),
              ),
              IconButton(
                tooltip: 'Apply filters',
                onPressed: () => setState(_reload),
                icon: const Icon(Icons.filter_alt_outlined),
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<LaboratoryModel>>(
            future: _rooms,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingWidget();
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text('Could not load laboratories: ${snapshot.error}'),
                );
              }
              final rows = snapshot.data ?? [];
              if (rows.isEmpty) {
                return const Center(
                  child: Text('No laboratories are listed yet.'),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: rows.length,
                itemBuilder: (context, index) {
                  final room = rows[index];
                  return ListTile(
                    leading: const Icon(Icons.science_outlined),
                    title: Text(room.name),
                    subtitle: Text(
                      '${room.building} · ${room.roomNumber} · ${room.capacity} seats · ${room.facilities.join(', ')}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/laboratories/${room.id}',
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    ),
  );
}
