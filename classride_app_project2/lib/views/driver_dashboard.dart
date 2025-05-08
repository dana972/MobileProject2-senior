import 'package:flutter/material.dart';
import './widgets/driverWidgets/assigned_trips.dart';

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({super.key});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _licenseController = TextEditingController();

  int completedTrips = 17;
  int _selectedSection = 1; // 0 = Notifications, 1 = Dashboard, 2 = Assigned Trips, etc.

  void _saveChanges() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Information updated successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF121435),
        title: const Text(
          'Driver Dashboard',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: Drawer(
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
                  Text(
                    'Driver Panel',
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(Icons.notifications, 'Notifications', 0),
            _buildDrawerItem(Icons.person, 'Dashboard', 1),
            _buildDrawerItem(Icons.assignment, 'Assigned Trips', 2),
            _buildDrawerItem(Icons.history, 'Trip History', 3),
            _buildDrawerItem(Icons.chat, 'Chats', 4),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.pushNamed(context, '/');
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
      ),
      body: _buildSectionContent(),
    );
  }

  ListTile _buildDrawerItem(IconData icon, String title, int index) {
    return ListTile(
      selected: _selectedSection == index,
      selectedTileColor: const Color(0xFFDAD7B5),
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        setState(() {
          _selectedSection = index;
        });
        Navigator.pop(context);
      },
    );
  }

  Widget _buildSectionContent() {
    switch (_selectedSection) {
      case 0:
        return const Center(child: Text('🔔 Notifications will appear here'));
      case 1:
        return _buildDashboardSection();
      case 2:
        return const AssignedTripsToday(trips: ['Trip to School', 'Trip to Campus']);
      case 3:
        return const Center(child: Text('🕒 Trip History will be shown here'));
      case 4:
        return const Center(child: Text('💬 Chat messages will be displayed here'));
      default:
        return const Center(child: Text('Invalid section'));
    }
  }

  Widget _buildDashboardSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dashboard Overview',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF121435),
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Completed Trips',
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        completedTrips.toString(),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF121435),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          const Text(
            'Edit Driver Info',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF121435),
            ),
          ),
          const SizedBox(height: 20),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value!.isEmpty ? 'Enter your name' : null,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) => value!.isEmpty ? 'Enter your phone number' : null,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _licenseController,
                  decoration: const InputDecoration(
                    labelText: 'License Number',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value!.isEmpty ? 'Enter license number' : null,
                ),
                const SizedBox(height: 25),
                Center(
                  child: ElevatedButton(
                    onPressed: _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF121435),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    ),
                    child: const Text('Save Changes'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
