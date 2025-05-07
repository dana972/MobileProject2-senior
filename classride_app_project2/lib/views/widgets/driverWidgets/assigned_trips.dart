import 'package:flutter/material.dart';

class AssignedTripsToday extends StatelessWidget {
  final List<String> trips; // You can later replace String with a Trip model

  const AssignedTripsToday({super.key, required this.trips});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF121435),
        title: const Text(
          'Assigned Trips Today',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: _buildDrawer(context), // Reuse same drawer
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: trips.isEmpty
            ? const Center(child: Text('No trips assigned today.'))
            : ListView.builder(
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
      ),
    );
  }

  Drawer _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFFEDEBCA),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFF121435)),
            child: Row(
              children: [
                Icon(Icons.directions_bus, color: Color(0xFFFF5722), size: 32),
                SizedBox(width: 10),
                Text('Driver Panel', style: TextStyle(color: Colors.white, fontSize: 24)),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/driverDashboard');
            },
          ),
          ListTile(
            selected: true,
            selectedTileColor: const Color(0xFFDAD7B5),
            leading: const Icon(Icons.assignment),
            title: const Text('Assigned Trips'),
            onTap: () {
              Navigator.pop(context); // Already on this page
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            },
          ),
        ],
      ),
    );
  }
}
