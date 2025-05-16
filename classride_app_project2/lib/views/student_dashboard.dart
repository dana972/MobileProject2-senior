import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'package:classride_app_project2/views/widgets/studentWidgets/assigned_trip_section.dart';
import './app_colors.dart'; // ✅ Import your custom colors
import 'package:shared_preferences/shared_preferences.dart';
import 'package:classride_app_project2/views/widgets/chat_screen.dart';
import 'package:classride_app_project2/views/widgets/chatting.dart';
import 'package:classride_app_project2/views/widgets/chat_list_screen.dart';


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
  final Map<String, int> dayMap = {
    "Monday": 1,
    "Tuesday": 2,
    "Wednesday": 3,
    "Thursday": 4,
    "Friday": 5,
    "Saturday": 6,
    "Sunday": 7,
  };

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
  Map<String, bool> _weeklyMorningAttendance = {};
  Map<String, bool> _weeklyReturnAttendance = {};

  String _activeSection = 'dashboard';

  @override
  void initState() {
    super.initState();
    _initDashboard();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _initDashboard() async {
    await _loadAttendance();
    await _loadWeeklySchedule();
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

  Future<void> _loadWeeklySchedule() async {
    final weeklyData = await ApiService.fetchWeeklySchedule();

    setState(() {
      for (final item in weeklyData) {
        final int dayNum = item['day_of_week'];
        final String dayName = _daysOfWeek[dayNum - 1];

        _weeklyMorningTimes[dayName] = _parseTime(item['morning_time']);
        _weeklyReturnTimes[dayName] = _parseTime(item['return_time']);

        _weeklyMorningAttendance[dayName] = item['attendance_morning'] ?? false;
        _weeklyReturnAttendance[dayName] = item['attendance_return'] ?? false;

      }
    });
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
      initialTime: isMorning
          ? (_weeklyMorningTimes[day] ?? TimeOfDay(hour: 7, minute: 0))
          : (_weeklyReturnTimes[day] ?? TimeOfDay(hour: 15, minute: 0)),
    );

    if (picked != null) {
      setState(() {
        if (isMorning) {
          _weeklyMorningTimes[day] = picked;
        } else {
          _weeklyReturnTimes[day] = picked;
        }
      });

      final TimeOfDay morning = _weeklyMorningTimes[day] ?? TimeOfDay(hour: 7, minute: 0);
      final TimeOfDay returnT = _weeklyReturnTimes[day] ?? TimeOfDay(hour: 15, minute: 0);

      final success = await ApiService.updateWeeklySchedule(
        dayOfWeek: dayMap[day]!, // ✅ named parameter
        morningTime: _formatTimeForApi(morning),
        returnTime: _formatTimeForApi(returnT),
        attendanceMorning: _weeklyMorningAttendance[day] ?? false,
        attendanceReturn: _weeklyReturnAttendance[day] ?? false,
      );


      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Updated $day schedule")),
        );
      }
    }
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return "--:--";
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat.jm().format(dt);
  }

  Future<bool> _confirmUpdate(BuildContext context, String title) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Update'),
        content: Text('Are you sure you want to update $title?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('OK')),
        ],
      ),
    ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Student Dashboard")),
      drawer: _buildDrawer(context),
      body: () {
        switch (_activeSection) {
          case 'dashboard':
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: _buildDashboardContent(),
            );
          case 'assignedTrip':
            return const AssignedTripSection();
          case 'chat':
            return const ChatListScreen(isDriver: false);


          default:
            return const Center(child: Text("Section not found"));
        }
      }(),
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
            bool confirmed = await _confirmUpdate(context, "today's morning attendance");
            if (!confirmed) return;

            final success = await ApiService.updateAttendance(
              date: DateTime.now().toIso8601String().split('T')[0],
              isMorning: true,
              isPresent: val,
            );
            if (success) {
              setState(() => _todayMorningAttendance = val);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Morning attendance updated")),
              );
            }
          },
        ),
        const SizedBox(height: 8),
        _buildAttendanceCard(
          title: 'Return Attendance (Today)',
          value: _todayReturnAttendance,
          onChanged: (val) async {
            bool confirmed = await _confirmUpdate(context, "today's return attendance");
            if (!confirmed) return;

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
            bool confirmed = await _confirmUpdate(context, "tomorrow's morning attendance");
            if (!confirmed) return;

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
            bool confirmed = await _confirmUpdate(context, "tomorrow's return attendance");
            if (!confirmed) return;

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
                leading: const Icon(Icons.wb_sunny, color: AppColors.orange),
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
                await _loadAttendance();
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
                leading: const Icon(Icons.wb_sunny,color: AppColors.orange),
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
                await _loadAttendance();
              }
            }
          },
        ),

        const SizedBox(height: 8),

        const SizedBox(height: 24),
        Text("Weekly Schedule", style: Theme.of(context).textTheme.titleLarge),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text("Add Day"),
              onPressed: () => _showAddDayDialog(context),
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.remove),
              label: const Text("Remove Day"),
              onPressed: () => _showRemoveDayDialog(context),
            ),
          ],
        ),
        const SizedBox(height: 8),
    Table(
    border: TableBorder.all(color: Colors.grey),
    columnWidths: const {
    0: FlexColumnWidth(2.5),
    1: FlexColumnWidth(2),
    2: FlexColumnWidth(2),
    3: FlexColumnWidth(1.5),
    4: FlexColumnWidth(1.5),
    5: FlexColumnWidth(2),
    6: FlexColumnWidth(2),
    },
    children: [
    const TableRow(
    decoration: BoxDecoration(color: AppColors.softGreen),
    children: [
    Padding(padding: EdgeInsets.all(8), child: Text("Day", style: TextStyle(color: Colors.white))),
    Padding(padding: EdgeInsets.all(8), child: Text("Morning Time", style: TextStyle(color: Colors.white))),
    Padding(padding: EdgeInsets.all(8), child: Text("Return Time", style: TextStyle(color: Colors.white))),
    Padding(padding: EdgeInsets.all(8), child: Text("Att. M")),
    Padding(padding: EdgeInsets.all(8), child: Text("Att. R")),
    ],
    ),
    ..._daysOfWeek.map((day) {
    return TableRow(
    children: [
    Padding(padding: const EdgeInsets.all(8), child: Text(day)),
      Padding(
        padding: const EdgeInsets.all(8),
        child: IconButton(
          icon: const Icon(Icons.access_time),
          onPressed: () => _editScheduleTime(context, day, true),
        ),
      ),

      Padding(
        padding: const EdgeInsets.all(8),
        child: IconButton(
          icon: const Icon(Icons.access_time),
          onPressed: () => _editScheduleTime(context, day, false),
        ),
      ),

      // ✅ Morning Attendance Switch
    Padding(
    padding: const EdgeInsets.all(8),
    child: Switch(
    value: _weeklyMorningAttendance[day] ?? false,
    onChanged: (bool val) {
    setState(() => _weeklyMorningAttendance[day] = val);
    _sendAttendanceToBackend(day, true, val);
    },
      activeColor: AppColors.deepGreen,          // ON state (thumb)
      inactiveThumbColor: AppColors.orange,
    ),
    ),

    // ✅ Return Attendance Switch
    Padding(
    padding: const EdgeInsets.all(8),
    child: Switch(
    value: _weeklyReturnAttendance[day] ?? false,
    onChanged: (bool val) {
    setState(() => _weeklyReturnAttendance[day] = val);
    _sendAttendanceToBackend(day, false, val);
    },
      inactiveThumbColor: AppColors.orange,      // OFF state (thumb)

    ),
    ),
    ],
    );
    }).toList(),
    ],
    ),

      ],
    );
  }



  Widget _buildAttendanceCard({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      elevation: 3,
      child: ListTile(
        title: Text(title),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.deepGreen,          // ON state (thumb)
          inactiveThumbColor: AppColors.orange,      // OFF state (thumb)
        ),
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
              onTap: () {
                setState(() {
                  _activeSection = 'chat';
                });
                Navigator.pop(context);
              }

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
              await prefs.clear(); // ✅ Clear token and role
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            },


          ),
        ],
      ),
    );
  }


  Future<void> _sendAttendanceToBackend(String dayName, bool isMorning, bool value) async {
    final TimeOfDay morningTime = _weeklyMorningTimes[dayName] ?? TimeOfDay(hour: 7, minute: 0);
    final TimeOfDay returnTime = _weeklyReturnTimes[dayName] ?? TimeOfDay(hour: 15, minute: 0);

    final bool attMorning = _weeklyMorningAttendance[dayName] ?? false;
    final bool attReturn = _weeklyReturnAttendance[dayName] ?? false;

    final success = await ApiService.updateWeeklySchedule(
      dayOfWeek: dayMap[dayName]!, // ✅ Convert String -> int
      morningTime: _formatTimeForApi(morningTime),
      returnTime: _formatTimeForApi(returnTime),
      attendanceMorning: attMorning,
      attendanceReturn: attReturn,
    );

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Failed to update weekly attendance")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ $dayName schedule updated successfully")),
      );

    }
  }

  void _showAddDayDialog(BuildContext context) {
    final _newDayController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add New Day"),
        content: TextField(
          controller: _newDayController,
          decoration: const InputDecoration(labelText: "Enter day name (e.g., Sunday)"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              final newDay = _newDayController.text.trim();
              if (newDay.isNotEmpty && !_daysOfWeek.contains(newDay)) {
                setState(() {
                  _daysOfWeek.add(newDay);
                  _weeklyMorningAttendance[newDay] = false;
                  _weeklyReturnAttendance[newDay] = false;
                  _weeklyMorningTimes[newDay] = TimeOfDay(hour: 7, minute: 0);
                  _weeklyReturnTimes[newDay] = TimeOfDay(hour: 15, minute: 0);
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
  void _showRemoveDayDialog(BuildContext context) {
    String? _selectedDayToRemove;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Remove Day"),
              content: DropdownButton<String>(
                value: _selectedDayToRemove,
                hint: const Text("Select day to remove"),
                isExpanded: true,
                items: _daysOfWeek.map((day) {
                  return DropdownMenuItem(value: day, child: Text(day));
                }).toList(),
                onChanged: (val) {
                  setState(() => _selectedDayToRemove = val);
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () async {
                    if (_selectedDayToRemove != null) {
                      final success = await ApiService.deleteWeeklyScheduleDay(_selectedDayToRemove!);
                      if (success) {
                        setState(() {
                          _weeklyMorningAttendance.remove(_selectedDayToRemove);
                          _weeklyReturnAttendance.remove(_selectedDayToRemove);
                          _weeklyMorningTimes.remove(_selectedDayToRemove);
                          _weeklyReturnTimes.remove(_selectedDayToRemove);
                          _daysOfWeek.remove(_selectedDayToRemove);
                        });
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("✅ ${_selectedDayToRemove!} removed successfully")),
                        );
                      } else {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("❌ Failed to delete day from backend")),
                        );
                      }
                    }
                  },
                  child: const Text("Remove"),
                ),
              ],
            );
          },
        );
      },
    );
  }


}