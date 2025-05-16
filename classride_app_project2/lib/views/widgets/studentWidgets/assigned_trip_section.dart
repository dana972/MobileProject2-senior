import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app_colors.dart';
import '../../../services/api_service.dart';
import './liveMapWidget.dart'; // ✅ Make sure this path matches your project structure

class AssignedTripSection extends StatefulWidget {
  const AssignedTripSection({super.key});

  @override
  State<AssignedTripSection> createState() => _AssignedTripSectionState();
}

class _AssignedTripSectionState extends State<AssignedTripSection> {
  List<dynamic> _assignedTrips = [];
  Map<String, dynamic>? _activeTrip;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAssignedTripsAndActiveTrip();
  }

  Future<void> _loadAssignedTripsAndActiveTrip() async {
    final trips = await ApiService.fetchAssignedTrips();
    final activeTrip = await ApiService.fetchActiveTrip();

    print("Assigned trips: $trips");
    print("Active trip: $activeTrip");

    setState(() {
      _assignedTrips = trips;
      _activeTrip = activeTrip;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final morningTrip = _assignedTrips.firstWhere(
          (t) => t['type'] == 'morning',
      orElse: () => null,
    );

    final returnTrip = _assignedTrips.firstWhere(
          (t) => t['type'] == 'return',
      orElse: () => null,
    );

    return SingleChildScrollView( // ✅ Wrap the Column here
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Assigned Trip", style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),

          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else ...[
            if (morningTrip != null)
              Card(
                elevation: 2,
                child: ListTile(
                  leading: const Icon(Icons.wb_sunny, color: Colors.orange),
                  title: const Text("Morning Trip"),
                  subtitle: Text(
                    "Pickup: ${morningTrip['pickup_time']} from Home\n"
                        "Destination: ${morningTrip['destination_name'] ?? 'Unknown'}\n"
                        "Date: ${formatDate(morningTrip['date'])}",
                  ),
                ),
              ),

            if (returnTrip != null) ...[
              const SizedBox(height: 10),
              Card(
                elevation: 2,
                child: ListTile(
                  leading: const Icon(Icons.nights_stay, color: Colors.black),
                  title: const Text("Return Trip"),
                  subtitle: Text(
                    "Pickup: ${returnTrip['pickup_time']} from University\n"
                        "Destination: Home\n"
                        "Date: ${formatDate(returnTrip['date'])}",
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),
            Text("Active Trip", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),

            if (_activeTrip != null) ...[
              Card(
                elevation: 2,
                child: ListTile(
                  leading: const Icon(Icons.directions_bus, color: Colors.black),
                  title: Text("Bus: ${_activeTrip!['bus_name'] ?? 'N/A'}"),
                  subtitle: Text(
                    "Capacity: ${_activeTrip!['capacity'] ?? 'N/A'}\n"
                        "Bus ID: ${_activeTrip!['bus_id'] ?? 'N/A'}",
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text("Live Tracking", style: TextStyle(fontWeight: FontWeight.bold)),
              LiveMapWidget(tripId: _activeTrip!['trip_id'].toString()),
            ] else
              const Card(
                elevation: 2,
                child: ListTile(
                  leading: Icon(Icons.info_outline, color: Colors.red),
                  title: Text("No Active Trip"),
                  subtitle: Text("Currently, there is no active trip."),
                ),
              ),
          ],
        ],
      ),
    );
  }


  String formatDate(String isoDate) {
    final parsedDate = DateTime.parse(isoDate);
    return DateFormat('yyyy-MM-dd').format(parsedDate);
  }
}
