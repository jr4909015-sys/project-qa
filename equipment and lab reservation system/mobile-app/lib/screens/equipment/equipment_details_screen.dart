import 'package:flutter/material.dart';

import '../../core/config/api_config.dart';
import '../../models/equipment_model.dart';
import '../../services/equipment_service.dart';
import '../../widgets/loading_widget.dart';

class EquipmentDetailsScreen extends StatelessWidget {
  const EquipmentDetailsScreen({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Equipment details')),
    body: FutureBuilder<EquipmentModel>(
      future: EquipmentService().get(id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingWidget();
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const Center(child: Text('Equipment details unavailable.'));
        }
        final item = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.all(18),
          children: [
            if (item.image != null)
              Image.network(
                ApiConfig.mediaUri(item.image!).toString(),
                height: 180,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
              ),
            Text(item.name, style: Theme.of(context).textTheme.headlineSmall),
            Text('${item.category} · ${item.assetTag}'),
            Text(item.description),
            Text('Condition: ${item.condition}'),
            Text(
              'Available: ${item.availableQuantity ?? item.quantity} of ${item.quantity}',
            ),
            Text('Location: ${item.location}'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, '/reservations/create'),
              icon: const Icon(Icons.event_available),
              label: const Text('Request reservation'),
            ),
          ],
        );
      },
    ),
  );
}
