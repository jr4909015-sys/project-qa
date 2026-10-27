import 'package:flutter/material.dart';

import '../../core/config/api_config.dart';
import '../../models/equipment_model.dart';
import '../../services/equipment_service.dart';
import '../../widgets/loading_widget.dart';

class EquipmentListScreen extends StatefulWidget {
  const EquipmentListScreen({super.key});

  @override
  State<EquipmentListScreen> createState() => _EquipmentListScreenState();
}

class _EquipmentListScreenState extends State<EquipmentListScreen> {
  final _search = TextEditingController();
  final _category = TextEditingController();
  String? _condition;
  late Future<List<EquipmentModel>> _items;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _search.dispose();
    _category.dispose();
    super.dispose();
  }

  void _reload() {
    _items = EquipmentService().list(
      search: _search.text,
      condition: _condition,
      category: _category.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Equipment'),
      actions: [
        IconButton(
          tooltip: 'My borrowed equipment',
          onPressed: () => Navigator.pushNamed(context, '/loans'),
          icon: const Icon(Icons.assignment_return_outlined),
        ),
      ],
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: TextField(
            controller: _search,
            decoration: InputDecoration(
              labelText: 'Search equipment',
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
          child: TextField(
            controller: _category,
            decoration: InputDecoration(
              labelText: 'Category',
              suffixIcon: IconButton(
                icon: const Icon(Icons.filter_alt_outlined),
                onPressed: () => setState(_reload),
              ),
            ),
            onSubmitted: (_) => setState(_reload),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonFormField<String?>(
            initialValue: _condition,
            decoration: const InputDecoration(labelText: 'Condition'),
            items: const [
              DropdownMenuItem(value: null, child: Text('Any condition')),
              DropdownMenuItem(value: 'good', child: Text('Good')),
              DropdownMenuItem(value: 'fair', child: Text('Fair')),
              DropdownMenuItem(value: 'damaged', child: Text('Damaged')),
              DropdownMenuItem(
                value: 'maintenance',
                child: Text('Under maintenance'),
              ),
            ],
            onChanged: (value) => setState(() {
              _condition = value;
              _reload();
            }),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<EquipmentModel>>(
            future: _items,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingWidget();
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text('Could not load equipment: ${snapshot.error}'),
                );
              }
              final rows = snapshot.data ?? [];
              if (rows.isEmpty) {
                return const Center(child: Text('No equipment is listed yet.'));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: rows.length,
                itemBuilder: (context, index) {
                  final item = rows[index];
                  return ListTile(
                    leading: item.image == null
                        ? const Icon(Icons.inventory_2_outlined)
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              ApiConfig.mediaUri(item.image!).toString(),
                              width: 52,
                              height: 52,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  const Icon(Icons.inventory_2_outlined),
                            ),
                          ),
                    title: Text(item.name),
                    subtitle: Text(
                      '${item.category} · ${item.availableQuantity ?? item.quantity} available · ${item.condition}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () =>
                        Navigator.pushNamed(context, '/equipment/${item.id}'),
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
