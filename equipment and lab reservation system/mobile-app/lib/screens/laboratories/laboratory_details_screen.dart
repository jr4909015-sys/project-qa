import 'package:flutter/material.dart';
import '../../models/laboratory_model.dart';
import '../../services/laboratory_service.dart';
import '../../widgets/loading_widget.dart';

class LaboratoryDetailsScreen extends StatelessWidget {
  const LaboratoryDetailsScreen({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Laboratory details')),
        body: FutureBuilder<LaboratoryModel>(
          future: LaboratoryService().get(id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const LoadingWidget();
            if (snapshot.hasError || !snapshot.hasData) return const Center(child: Text('Laboratory details unavailable.'));
            final room = snapshot.data!;
            return ListView(padding: const EdgeInsets.all(18), children: [
              Text(room.name, style: Theme.of(context).textTheme.headlineSmall),
              Text('${room.building} · ${room.roomNumber} · Capacity ${room.capacity}'),
              Text(room.description),
              Text('Facilities: ${room.facilities.join(', ')}'),
              Text('Operating hours: ${room.openingTime ?? 'not set'} - ${room.closingTime ?? 'not set'}'),
              const SizedBox(height: 16),
              FilledButton.icon(onPressed: () => Navigator.pushNamed(context, '/reservations/create'), icon: const Icon(Icons.event_available), label: const Text('Request a time')),
            ]);
          },
        ),
      );
}