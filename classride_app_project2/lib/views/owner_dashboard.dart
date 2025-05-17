import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:classride_app_project2/views/app_colors.dart';
import 'widgets/ownerWidget/assigned_trip.dart';

class OwnerDashboard extends StatefulWidget {
  const OwnerDashboard({super.key});

  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> {
  String _activeSection = 'dashboard';

  List<Map<String, dynamic>> _buses = [
    {'name': 'Bus A', 'capacity': 40},
    {'name': 'Bus B', 'capacity': 30},
  ];

  List<Map<String, String>> _destinations = [
    {'name': 'School A', 'location': 'Downtown'},
    {'name': 'School B', 'location': 'Uptown'},
  ];

  List<Map<String, String>> _drivers = [
    {'name': 'John Doe', 'phone': '1234567890', 'hometown': 'City A'},
    {'name': 'Jane Smith', 'phone': '9876543210', 'hometown': 'City B'},
  ];
  List<Map<String, dynamic>> _students = [
    {
      'name': 'Alice Johnson',
      'phone': '5551234567',
      'destination': 'School A',
      'schedule': [
        {'date': '2025-05-16', 'morning': true, 'return': false},
        {'date': '2025-05-17', 'morning': true, 'return': true},
      ]
    },
    {
      'name': 'Bob Williams',
      'phone': '5559876543',
      'destination': 'School B',
      'schedule': [
        {'date': '2025-05-16', 'morning': false, 'return': true},
        {'date': '2025-05-17', 'morning': true, 'return': false},
      ]
    },
  ];


  final TextEditingController _busNameController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();
  final TextEditingController _destinationNameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _driverNameController = TextEditingController();
  final TextEditingController _driverPhoneController = TextEditingController();
  final TextEditingController _driverHometownController = TextEditingController();

  int _hoveredIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Owner Dashboard")),
      drawer: _buildDrawer(context),
      body: _getSectionContent(), // ✅ dynamic based on _activeSection

    );
  }
  Widget _getSectionContent() {
    switch (_activeSection) {
      case 'dashboard':
        return _buildDashboardContent();
      case 'trips':
        return const AssignedTripsSection();
      default:
        return const Center(child: Text("Section not found"));
    }
  }




  Widget _buildDashboardContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("👋 Hello, Dana Amasha!", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildCircle("Current\nStudents", "2", showButton: false, index: 0),
              _buildCircle("Students\nRequests", "1", showButton: true, index: 1),
              _buildCircle("Drivers\nRequests", "56", showButton: true, index: 2),
              _buildCircle("Current\nDrivers", "2", showButton: false, index: 3),
            ],
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMetricCard("Metric A", "Value", 4),
              _buildMetricCard("Metric B", "Value", 5),
              _buildMetricCard("Metric C", "Value", 6),
            ],
          ),
          const SizedBox(height: 40),
          const Text("🚌 Buses Management", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          _buildDataTable(
            columns: const [
              DataColumn(label: Text("Bus Name")),
              DataColumn(label: Text("Capacity")),
              DataColumn(label: Text("Action")),
            ],
            rows: _buses.map((bus) {
              return DataRow(cells: [
                DataCell(Text(bus['name'])),
                DataCell(Text(bus['capacity'].toString())),
                DataCell(TextButton(
                  onPressed: () => setState(() => _buses.remove(bus)),
                  child: const Text("Remove", style: TextStyle(color: Colors.red)),
                )),
              ]);
            }).toList(),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: _showAddBusDialog,
            icon: const Icon(Icons.add),
            label: const Text("Add More"),
          ),
          const SizedBox(height: 30),
          const Text("📍 Destination Management", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          _buildDataTable(
            columns: const [
              DataColumn(label: Text("Destination Name")),
              DataColumn(label: Text("Location")),
              DataColumn(label: Text("Action")),
            ],
            rows: _destinations.map((dest) {
              return DataRow(cells: [
                DataCell(Text(dest['name']!)),
                DataCell(Text(dest['location']!)),
                DataCell(TextButton(
                  onPressed: () => setState(() => _destinations.remove(dest)),
                  child: const Text("Remove", style: TextStyle(color: Colors.red)),
                )),
              ]);
            }).toList(),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: _showAddDestinationDialog,
            icon: const Icon(Icons.add),
            label: const Text("Add More"),
          ),
          const SizedBox(height: 30),
          const Text("🧑‍✈️ Driver Management", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          _buildDataTable(
            columns: const [
              DataColumn(label: Text("Name")),
              DataColumn(label: Text("Phone")),
              DataColumn(label: Text("Hometown")),
              DataColumn(label: Text("Action")),
            ],
            rows: _drivers.map((driver) {
              return DataRow(cells: [
                DataCell(Text(driver['name']!)),
                DataCell(Text(driver['phone']!)),
                DataCell(Text(driver['hometown']!)),
                DataCell(TextButton(
                  onPressed: () => setState(() => _drivers.remove(driver)),
                  child: const Text("Remove", style: TextStyle(color: Colors.red)),
                )),
              ]);
            }).toList(),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: _showAddDriverDialog,
            icon: const Icon(Icons.add),
            label: const Text("Add More"),
          ),
          const SizedBox(height: 30),
          const Text("👨‍🎓 Student Management", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          _buildDataTable(
            columns: const [
              DataColumn(label: Text("Name")),
              DataColumn(label: Text("Phone")),
              DataColumn(label: Text("Destination")),
              DataColumn(label: Text("Action")),
            ],
            rows: _students.map((student) {
              return DataRow(cells: [
                DataCell(Text(student['name'])),
                DataCell(Text(student['phone'])),
                DataCell(Text(student['destination'])),
                DataCell(Row(
                  children: [
                    TextButton(
                      onPressed: () => _showStudentScheduleDialog(student),
                      child: const Text("View Schedule", style: TextStyle(color: Colors.blue)),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _students.remove(student)),
                      child: const Text("Remove", style: TextStyle(color: Colors.red)),
                    ),
                  ],
                )),
              ]);
            }).toList(),
          ),
        ],
      ),
    );
  }



  Widget _buildManageTripsSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("🗺️ Trip Management", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          // Example static list
          ...List.generate(3, (index) {
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: const Icon(Icons.directions_bus),
                title: Text("Trip ${index + 1}"),
                subtitle: Text("From A to B"),
                trailing: TextButton(
                  onPressed: () {
                    // logic for viewing/editing trip
                  },
                  child: const Text("View Details"),
                ),
              ),
            );
          }),
          ElevatedButton.icon(
            onPressed: () {
              // Logic to add a new trip
            },
            icon: const Icon(Icons.add),
            label: const Text("Add New Trip"),
          )
        ],
      ),
    );
  }






  Widget _buildCircle(String title, String count, {required bool showButton, required int index}) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = -1),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF2E7D32),
          boxShadow: [
            BoxShadow(
              color: _hoveredIndex == index ? Colors.greenAccent.withOpacity(0.4) : Colors.black26,
              blurRadius: _hoveredIndex == index ? 12 : 6,
            )
          ],
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              Text(count, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              if (showButton)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                    child: const Text("View"),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }





  Widget _buildMetricCard(String title, String value, int index) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = -1),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 110,
        height: 100,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F1F1),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _hoveredIndex == index ? Colors.green.withOpacity(0.3) : Colors.black12,
              blurRadius: _hoveredIndex == index ? 10 : 4,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTable({required List<DataColumn> columns, required List<DataRow> rows}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10, bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DataTable(
        columnSpacing: 40,
        horizontalMargin: 20,
        headingRowColor: MaterialStateProperty.all(Colors.green),
        headingTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        columns: columns,
        rows: rows,
        dataRowColor: MaterialStateProperty.all(const Color(0xFFFDF9F3)),
        dividerThickness: 1,
      ),
    );
  }





  void _showAddBusDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Bus"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _busNameController,
              decoration: const InputDecoration(labelText: 'Bus Name'),
            ),
            TextField(
              controller: _capacityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Capacity'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              final name = _busNameController.text.trim();
              final capacity = int.tryParse(_capacityController.text.trim());
              if (name.isNotEmpty && capacity != null) {
                setState(() {
                  _buses.add({'name': name, 'capacity': capacity});
                  _busNameController.clear();
                  _capacityController.clear();
                });
                Navigator.pop(context);
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  void _showAddDestinationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Destination"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _destinationNameController,
              decoration: const InputDecoration(labelText: 'Destination Name'),
            ),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(labelText: 'Location'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              final name = _destinationNameController.text.trim();
              final location = _locationController.text.trim();
              if (name.isNotEmpty && location.isNotEmpty) {
                setState(() {
                  _destinations.add({'name': name, 'location': location});
                  _destinationNameController.clear();
                  _locationController.clear();
                });
                Navigator.pop(context);
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  void _showAddDriverDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Driver"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _driverNameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: _driverPhoneController,
              decoration: const InputDecoration(labelText: 'Phone Number'),
              keyboardType: TextInputType.phone,
            ),
            TextField(
              controller: _driverHometownController,
              decoration: const InputDecoration(labelText: 'Hometown'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              final name = _driverNameController.text.trim();
              final phone = _driverPhoneController.text.trim();
              final hometown = _driverHometownController.text.trim();
              if (name.isNotEmpty && phone.isNotEmpty && hometown.isNotEmpty) {
                setState(() {
                  _drivers.add({'name': name, 'phone': phone, 'hometown': hometown});
                  _driverNameController.clear();
                  _driverPhoneController.clear();
                  _driverHometownController.clear();
                });
                Navigator.pop(context);
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  void _showStudentScheduleDialog(Map<String, dynamic> student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Schedule for \${student['name']}"),
        content: SingleChildScrollView(
          child: DataTable(
            columns: const [
              DataColumn(label: Text("Date")),
              DataColumn(label: Text("Morning")),
              DataColumn(label: Text("Return")),
            ],
            rows: (student['schedule'] as List<Map<String, dynamic>>).map((entry) {
              return DataRow(cells: [
                DataCell(Text(entry['date'])),
                DataCell(Icon(entry['morning'] ? Icons.check : Icons.close, color: entry['morning'] ? Colors.green : Colors.red)),
                DataCell(Icon(entry['return'] ? Icons.check : Icons.close, color: entry['return'] ? Colors.green : Colors.red)),
              ]);
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          )
        ],
      ),
    );
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
            leading: const Icon(Icons.directions_bus),
            title: const Text('Manage Trips'),
            selected: _activeSection == 'trips',
            onTap: () {
              setState(() => _activeSection = 'trips');
              Navigator.pop(context);
            },
          ),


          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () => Navigator.pushNamed(context, '/'),
          ),
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


  @override
  void dispose() {
    _busNameController.dispose();
    _capacityController.dispose();
    _destinationNameController.dispose();
    _locationController.dispose();
    _driverNameController.dispose();
    _driverPhoneController.dispose();
    _driverHometownController.dispose();
    super.dispose();
  }
}
