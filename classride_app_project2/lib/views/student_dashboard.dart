import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  // Attendance toggles
  bool _todayMorningAttendance = false;
  bool _todayReturnAttendance = false;
  bool _tomorrowMorningAttendance = false;
  bool _tomorrowReturnAttendance = false;

  // Schedule times
  TimeOfDay? _todayMorningTime;
  TimeOfDay? _todayReturnTime;
  TimeOfDay? _tomorrowMorningTime;
  TimeOfDay? _tomorrowReturnTime;

  // Weekly schedule
  final List<String> _daysOfWeek = [
    "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"
  ];
  Map<String, TimeOfDay?> _weeklyMorningTimes = {};
  Map<String, TimeOfDay?> _weeklyReturnTimes = {};

  // Student Info Form
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _homeLocationController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();

  String _activeSection = 'dashboard';

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _homeLocationController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _pickTime({
    required BuildContext context,
    required bool isMorning,
    required bool isToday,
  }) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        if (isToday) {
          if (isMorning) {
            _todayMorningTime = picked;
          } else {
            _todayReturnTime = picked;
          }
        } else {
          if (isMorning) {
            _tomorrowMorningTime = picked;
          } else {
            _tomorrowReturnTime = picked;
          }
        }
      });
    }
  }

  Future<void> _editScheduleTime(BuildContext context, String day, bool isMorning) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isMorning) {
          _weeklyMorningTimes[day] = picked;
        } else {
          _weeklyReturnTimes[day] = picked;
        }
      });
    }
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return "--:--";
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat.jm().format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Student Dashboard")),
      drawer: _buildDrawer(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: _activeSection == 'dashboard'
            ? _buildDashboardContent()
            : _buildAssignedTripContent(),
      ),
    );
  }

  Widget _buildDashboardContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Today's Attendance", style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        _buildAttendanceCard(
          title: 'Morning Attendance (Today)',
          value: _todayMorningAttendance,
          onChanged: (val) async {
            final success = await ApiService.updateAttendance(
              date: DateTime.now().toIso8601String().split('T')[0],
              isMorning: true,
              isPresent: val,
            );
            if (success) {
              setState(() => _todayMorningAttendance = val);
            }
          },
        ),
        const SizedBox(height: 8),
        _buildAttendanceCard(
          title: 'Return Attendance (Today)',
          value: _todayReturnAttendance,
          onChanged: (val) async {
            final success = await ApiService.updateAttendance(
              date: DateTime.now().toIso8601String().split('T')[0],
              isMorning: false,
              isPresent: val,
            );
            if (success) {
              setState(() => _todayReturnAttendance = val);
            }
          },
        ),
        const SizedBox(height: 24),
        Text("Tomorrow's Attendance", style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        _buildAttendanceCard(
          title: 'Morning Attendance (Tomorrow)',
          value: _tomorrowMorningAttendance,
          onChanged: (val) async {
            final success = await ApiService.updateAttendance(
              date: DateTime.now().add(const Duration(days: 1)).toIso8601String().split('T')[0],
              isMorning: true,
              isPresent: val,
            );
            if (success) {
              setState(() => _tomorrowMorningAttendance = val);
            }
          },
        ),
        const SizedBox(height: 8),
        _buildAttendanceCard(
          title: 'Return Attendance (Tomorrow)',
          value: _tomorrowReturnAttendance,
          onChanged: (val) async {
            final success = await ApiService.updateAttendance(
              date: DateTime.now().add(const Duration(days: 1)).toIso8601String().split('T')[0],
              isMorning: false,
              isPresent: val,
            );
            if (success) {
              setState(() => _tomorrowReturnAttendance = val);
            }
          },
        ),

        const SizedBox(height: 24),
        Text("Today's Schedule", style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Card(
          elevation: 3,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text("Day: ${DateFormat('EEEE').format(DateTime.now())}"),
              ),
              ListTile(
                leading: const Icon(Icons.wb_sunny),
                title: const Text("Morning Time"),
                subtitle: Text(_formatTime(_todayMorningTime)),
                trailing: IconButton(
                  icon: const Icon(Icons.access_time),
                  onPressed: () => _pickTime(context: context, isMorning: true, isToday: true),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.nights_stay),
                title: const Text("Return Time"),
                subtitle: Text(_formatTime(_todayReturnTime)),
                trailing: IconButton(
                  icon: const Icon(Icons.access_time),
                  onPressed: () => _pickTime(context: context, isMorning: false, isToday: true),
                ),
              ),
            ],
          ),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.save),
          label: const Text("Save Today's Times"),
          onPressed: () async {
            if (_todayMorningTime != null && _todayReturnTime != null) {
              final success = await ApiService.updateSchedule(
                date: DateTime.now().toIso8601String().split('T')[0],
                morningTime: _formatTimeForApi(_todayMorningTime!),
                returnTime: _formatTimeForApi(_todayReturnTime!),
              );
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Today's schedule updated")),
                );
                await _loadAttendance(); // ⬅️ refresh data after update

              }
            }
          },
        ),

        const SizedBox(height: 24),
        Text("Tomorrow's Schedule", style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Card(
          elevation: 3,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text("Day: ${DateFormat('EEEE').format(DateTime.now().add(const Duration(days: 1)))}"),
              ),
              ListTile(
                leading: const Icon(Icons.wb_sunny),
                title: const Text("Morning Time"),
                subtitle: Text(_formatTime(_tomorrowMorningTime)),
                trailing: IconButton(
                  icon: const Icon(Icons.access_time),
                  onPressed: () => _pickTime(context: context, isMorning: true, isToday: false),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.nights_stay),
                title: const Text("Return Time"),
                subtitle: Text(_formatTime(_tomorrowReturnTime)),
                trailing: IconButton(
                  icon: const Icon(Icons.access_time),
                  onPressed: () => _pickTime(context: context, isMorning: false, isToday: false),
                ),
              ),
            ],
          ),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.save),
          label: const Text("Save Tomorrow's Times"),
          onPressed: () async {
            if (_tomorrowMorningTime != null && _tomorrowReturnTime != null) {
              final success = await ApiService.updateSchedule(
                date: DateTime.now().add(const Duration(days: 1)).toIso8601String().split('T')[0],
                morningTime: _formatTimeForApi(_tomorrowMorningTime!),
                returnTime: _formatTimeForApi(_tomorrowReturnTime!),
              );
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Tomorrow's schedule updated")),
                );
                await _loadAttendance(); // ⬅️ refresh data after update

              }
            }
          },
        ),

        const SizedBox(height: 24),
        Text("Edit My Info", style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Student Name",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: "Phone Number",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _homeLocationController,
                decoration: const InputDecoration(
                  labelText: "Home Location",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _destinationController,
                decoration: const InputDecoration(
                  labelText: "Destination",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Info saved successfully')),
                    );
                  }
                },
                icon: const Icon(Icons.save),
                label: const Text("Save"),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text("Weekly Schedule", style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Table(
          border: TableBorder.all(color: Colors.grey),
          columnWidths: const {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(2),
            2: FlexColumnWidth(2),
            3: FlexColumnWidth(1.5),
            4: FlexColumnWidth(1.5),
          },
          children: [
            const TableRow(
              decoration: BoxDecoration(color: Colors.blueAccent),
              children: [
                Padding(padding: EdgeInsets.all(8), child: Text("Day", style: TextStyle(color: Colors.white))),
                Padding(padding: EdgeInsets.all(8), child: Text("Morning Time", style: TextStyle(color: Colors.white))),
                Padding(padding: EdgeInsets.all(8), child: Text("Return Time", style: TextStyle(color: Colors.white))),
                Padding(padding: EdgeInsets.all(8), child: Text("Edit M")),
                Padding(padding: EdgeInsets.all(8), child: Text("Edit R")),
              ],
            ),
            ..._daysOfWeek.map((day) {
              return TableRow(
                children: [
                  Padding(padding: const EdgeInsets.all(8), child: Text(day)),
                  Padding(padding: const EdgeInsets.all(8), child: Text(_formatTime(_weeklyMorningTimes[day]))),
                  Padding(padding: const EdgeInsets.all(8), child: Text(_formatTime(_weeklyReturnTimes[day]))),
                  IconButton(
                    icon: const Icon(Icons.access_time),
                    onPressed: () => _editScheduleTime(context, day, true),
                  ),
                  IconButton(
                    icon: const Icon(Icons.access_time),
                    onPressed: () => _editScheduleTime(context, day, false),
                  ),
                ],
              );
            }).toList(),
          ],
        ),
      ],
    );
  }

  Widget _buildAssignedTripContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Assigned Trip", style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const Icon(Icons.wb_sunny),
            title: const Text("Morning Trip"),
            subtitle: const Text("Pickup: 7:30 AM from Home\nDestination: University Main Gate"),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: ListTile(
            leading: const Icon(Icons.nights_stay),
            title: const Text("Return Trip"),
            subtitle: const Text("Pickup: 3:15 PM from University\nDestination: Home Location"),
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceCard({required String title, required bool value, required ValueChanged<bool> onChanged}) {
    return Card(
      elevation: 3,
      child: ListTile(
        title: Text(title),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.green,
          inactiveThumbColor: Colors.red,
        ),
      ),
    );
  }

  Drawer _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text('Student Name', style: TextStyle(color: Colors.white, fontSize: 24)),
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
            title: const Text('Assigned Trip'),
            selected: _activeSection == 'assignedTrip',
            onTap: () {
              setState(() => _activeSection = 'assignedTrip');
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.chat),
            title: const Text('Chats'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () => Navigator.pushNamed(context, '/'),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () => Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false),
          ),
        ],
      ),
    );
  }
  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    final data = await ApiService.fetchAttendance();

    if (data == null) return;

    setState(() {
      _todayMorningAttendance = data['today']['attendance_morning'] ?? false;
      _todayReturnAttendance = data['today']['attendance_return'] ?? false;
      _tomorrowMorningAttendance = data['tomorrow']['attendance_morning'] ?? false;
      _tomorrowReturnAttendance = data['tomorrow']['attendance_return'] ?? false;

      _todayMorningTime = _parseTime(data['today']['morning_time']);
      _todayReturnTime = _parseTime(data['today']['return_time']);
      _tomorrowMorningTime = _parseTime(data['tomorrow']['morning_time']);
      _tomorrowReturnTime = _parseTime(data['tomorrow']['return_time']);
    });
  }

  TimeOfDay? _parseTime(String? timeString) {
    if (timeString == null) return null;
    final parts = timeString.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }
  String _formatTimeForApi(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
  }


}

