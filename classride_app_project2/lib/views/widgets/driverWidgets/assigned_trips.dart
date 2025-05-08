import 'package:flutter/material.dart';

class AssignedTripsToday extends StatelessWidget {
  final List<String> trips; // You can later replace String with a Trip model

  const AssignedTripsToday({super.key, required this.trips});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: trips.isEmpty
          ? const Center(child: Text('No trips assigned today.'))
          : ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: trips.length,
        itemBuilder: (context, index) {
          return Card(
            elevation: 3,
            margin: const EdgeInsets.symmetric(vertical: 10),
            child: ListTile(
              leading: const Icon(Icons.location_on),
              title: Text(trips[index]),
              subtitle: const Text("Scheduled Today"),
            ),
          );
        },
      ),
    );
  }
}
