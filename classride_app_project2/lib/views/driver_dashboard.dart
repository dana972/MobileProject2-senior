import 'package:flutter/material.dart';
import 'package:classride_app_project2/views/widgets/driverWidgets/completed_Trips.dart';
import 'package:classride_app_project2/views/widgets/driverWidgets/assigned_trips.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:classride_app_project2/views/widgets/chat_list_screen.dart';
import './app_colors.dart'; // ✅ Import your custom colors

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({super.key});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  String _activeSection = 'dashboard';
  int completedTrips = 25;
  int assignedTrips = 10;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _hometownController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _hometownController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Driver Dashboard")),
      drawer: _buildDrawer(context),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    switch (_activeSection) {
      case 'dashboard':
        return _buildDashboardContent();
      case 'assignedTrips':
        return _buildAssignedTripsContent();
      case 'tripHistory':
        return const TripHistory();
      case 'chat':
        return const ChatListScreen(isDriver: true);
      default:
        return const Center(child: Text("Section not found"));
    }
  }

  Widget _buildDashboardContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatCard("Completed Trips", completedTrips, Colors.green),
              const SizedBox(width: 20),
              _buildStatCard("Assigned Trips", assignedTrips, Colors.orange),
            ],
          ),
          const SizedBox(height: 40),
          const Text("Edit Info", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          TextField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _hometownController,
            decoration: const InputDecoration(
              labelText: 'Home Town',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text("License Image: ", style: TextStyle(fontSize: 16)),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.upload),
                label: const Text("Upload"),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {},
            child: const Text("Save Changes"),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignedTripsContent() {
    return const AssignedTripsSection();
  }

  Drawer _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.lightBeige,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: AppColors.deepGreen),
            child: Row(
              children: [
                Icon(Icons.directions_bus, color: AppColors.orange, size: 32),
                SizedBox(width: 10),
                Text('ClassRide', style: TextStyle(color: Colors.white, fontSize: 24)),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            selected: _activeSection == 'dashboard',
            onTap: () {
              setState(() => _activeSection = 'dashboard');
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.assignment),
            title: const Text('Assigned Trips'),
            selected: _activeSection == 'assignedTrips',
            onTap: () {
              setState(() => _activeSection = 'assignedTrips');
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Trip History'),
            selected: _activeSection == 'tripHistory',
            onTap: () {
              setState(() => _activeSection = 'tripHistory');
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.chat),
            title: const Text('Chat'),
            selected: _activeSection == 'chat',
            onTap: () {
              setState(() => _activeSection = 'chat');
              Navigator.pop(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, int count, Color color) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        elevation: 6,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 150,
          width: 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.9),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('$count', style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(title, style: const TextStyle(fontSize: 14, color: Colors.white)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTripDetailsDialog(BuildContext context, Map<String, dynamic> trip) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Trip #${trip['id']} on ${trip['date']}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            ListTile(
              title: Text("Dana Amasha"),
              trailing: Icon(Icons.check_circle, color: Colors.green),
            ),
            ListTile(
              title: Text("Ahmad Zaid"),
              trailing: Icon(Icons.cancel, color: Colors.red),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close"))
        ],
      ),
    );
  }
}
