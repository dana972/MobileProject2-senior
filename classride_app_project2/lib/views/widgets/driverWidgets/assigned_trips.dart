import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/api_service.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';


class AssignedTripsSection extends StatefulWidget {
  const AssignedTripsSection({super.key});

  @override
  State<AssignedTripsSection> createState() => _AssignedTripsSectionState();
}

class _AssignedTripsSectionState extends State<AssignedTripsSection> {
  static final String driverUrl = dotenv.env['DRIVER_API_URL']!;

  List<Map<String, dynamic>> _trips = [];
  List<Map<String, dynamic>> _activeTrips = [];
  bool _loading = true;
  TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredStudents = [];
  late IO.Socket socket;

  @override
  void initState() {
    super.initState();
    _fetchTrips();
    _searchController.addListener(_filterStudents);
  }

  Future<void> _fetchTrips() async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString('phone_number');

    if (phone == null) {
      print("❌ No phone number in SharedPreferences");
      setState(() => _loading = false);
      return;
    }

    final url = Uri.parse('$driverUrl/trips/$phone');
    print("📡 Requesting trips for $phone...");

    try {
      final response = await http.get(url);
      print("📬 Response status: ${response.statusCode}");
      print("📬 Response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final allTrips = List<Map<String, dynamic>>.from(data['trips']);
        print("✅ Trips received: ${allTrips.length}");

        final scheduled = allTrips.where((trip) => trip['status'] == 'scheduled').toList();
        final active = allTrips.where((trip) => trip['status'] == 'active').toList();

        setState(() {
          _trips = scheduled;
          _activeTrips = active;
          _loading = false;
        });
      } else {
        print("❌ Failed to load trips: ${response.statusCode}");
        setState(() => _loading = false);
      }
    } catch (e) {
      print("❌ Error fetching trips: $e");
      setState(() => _loading = false);
    }
  }

  // Filter students based on search query
  void _filterStudents() {
    setState(() {
      String query = _searchController.text.toLowerCase();

      _filteredStudents = List<Map<String, dynamic>>.from(_filteredStudents.where((student) {
        return student['full_name'].toLowerCase().contains(query);
      }).toList());

      _filteredStudents.sort((a, b) {
        bool aMatches = a['full_name'].toLowerCase().contains(query);
        bool bMatches = b['full_name'].toLowerCase().contains(query);
        if (aMatches && !bMatches) return -1;
        if (!aMatches && bMatches) return 1;
        return 0;
      });
    });
  }

  // Show Trip Modal
  Future<Map<String, dynamic>?> _showTripModal(BuildContext context, Map<String, dynamic> trip) async {
    final List<Map<String, dynamic>> students = List<Map<String, dynamic>>.from(trip['assigned_students'] ?? []);
    final formattedDate = DateFormat('MMMM d, y').format(DateTime.parse(trip['date']));
    final formattedPickup = _formatTime(trip['pickup_time']);
    final formattedDropoff = _formatTime(trip['dropoff_time']);
    final destinationName = trip['destination_name'] ?? 'Unknown Destination';

    List<Map<String, dynamic>> filtered = List.from(students); // Keep original

    return showDialog<Map<String, dynamic>>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("${trip['type'].toString().toUpperCase()} Trip Details"),
          content: StatefulBuilder(
            builder: (BuildContext context, void Function(void Function()) setModalState) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoRow(Icons.calendar_today, "Date", formattedDate),
                    const SizedBox(height: 8),
                    _infoRow(Icons.access_time, "Pickup Time", formattedPickup),
                    const SizedBox(height: 8),
                    _infoRow(Icons.access_time_filled, "Dropoff Time", formattedDropoff),
                    const SizedBox(height: 8),
                    _infoRow(Icons.info_outline, "Status", trip['status'].toString().toUpperCase()),
                    const SizedBox(height: 8),
                    _infoRow(Icons.place, "Destination", destinationName),

                    const Divider(height: 30),
                    const Text(
                      "👥 Assigned Students",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _searchController,
                      onChanged: (query) {
                        setModalState(() {
                          filtered = students.where((s) =>
                              s['full_name'].toLowerCase().contains(query.toLowerCase())
                          ).toList();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search by name...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                      ),
                    ),
                    const SizedBox(height: 15),

                    if (filtered.isEmpty)
                      const Text("No students assigned to this trip."),
                    if (filtered.isNotEmpty)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor: MaterialStateColor.resolveWith((states) => Colors.grey.shade200),
                            columns: const [
                              DataColumn(label: Text("Student Name")),
                              DataColumn(label: Text("Payment Status")),
                            ],
                            rows: filtered.map((student) {
                              return DataRow(
                                cells: [
                                  DataCell(
                                    GestureDetector(
                                      onTap: () => _showStudentDetails(context, student),
                                      child: Text(student['full_name']),
                                    ),
                                  ),
                                  DataCell(
                                    Switch(
                                      value: student['paid'] ?? false,
                                      onChanged: (bool value) async {
                                        setModalState(() {
                                          student['paid'] = value;
                                        });

                                        bool success = await ApiService.updatePaymentStatus(
                                          tripId: trip['trip_id'],
                                          studentPhone: student['phone_number'],
                                          paid: value,
                                        );

                                        if (!success) {
                                          setModalState(() {
                                            student['paid'] = !value;
                                          });
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Failed to update payment status')),
                                          );
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Payment status updated successfully')),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          actions: [
            if (trip['status'] != 'active')
              ElevatedButton.icon(
                icon: const Icon(Icons.play_arrow),
                label: const Text("Activate Trip"),
                onPressed: () async {
                  final success = await ApiService.activateTrip(trip['trip_id']);
                  if (success) {
                    setState(() {
                      trip['status'] = 'active';
                      _trips.remove(trip);
                      _activeTrips.add(trip);
                      _startSendingLocation(trip['trip_id']);
                    });

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("✅ Trip activated successfully")),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("❌ Failed to activate trip")),
                    );
                  }
                },
              ),
            if (trip['status'] == 'active')
              ElevatedButton.icon(
                icon: const Icon(Icons.check_circle),
                label: const Text("Complete Trip"),
                onPressed: () async {
                  final success = await ApiService.completeTrip(trip['trip_id']);
                  if (success) {
                    setState(() {
                      trip['status'] = 'completed';
                      _activeTrips.remove(trip);
                    });

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("✅ Trip completed successfully")),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("❌ Failed to complete trip")),
                    );
                  }
                },
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        ),
    );


  }

  // Show student details in a modal
  void _showStudentDetails(BuildContext context, Map<String, dynamic> student) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Student Details"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("👤 Name: ${student['full_name']}"),
              Text("📱 Phone: ${student['phone_number']}"),
              Text("📍 Address: ${student['address'] ?? 'N/A'}"),
              if (student['latitude'] != null && student['longitude'] != null)
                GestureDetector(
                  onTap: () {
                    final url =
                        'https://www.google.com/maps/search/?api=1&query=${student['latitude']},${student['longitude']}';
                    launchUrl(Uri.parse(url));
                  },
                  child: Text(
                    '🗺️ View on Google Maps',
                    style: const TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              Text("💰 Payment Status: ${student['paid'] == true ? 'Paid' : 'Pending'}"),
              const SizedBox(height: 10),
              Text("📝 Notes: ${student['notes'] ?? 'No notes available'}"),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }


  Widget _buildTripCard(BuildContext context, Map<String, dynamic> trip) {
    return Card(
      child: ListTile(
        leading: Icon(
          trip['type'] == 'morning' ? Icons.wb_sunny : Icons.nights_stay,
          color: trip['status'] == 'active' ? Colors.green : Colors.grey,
        ),
        title: Text("${trip['type'].toString().toUpperCase()} Trip"),
        subtitle: Text("📅 ${trip['date']} | 🕒 ${trip['pickup_time']} ➡ ${trip['dropoff_time']}"),
        trailing: ElevatedButton(
          onPressed: () => _openTripModal(context, trip),
          child: const Text("Details"),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Assigned Trips", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ..._trips.map((trip) => _buildTripCard(context, trip)).toList(),

          const SizedBox(height: 30),
          const Text("Active Trips", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          if (_activeTrips.isEmpty)
            const Text("No active trips."),
          ..._activeTrips.map((trip) => _buildTripCard(context, trip)).toList(),
        ],
      ),
    );
  }

  void _openTripModal(BuildContext context, Map<String, dynamic> trip) async {
    final updatedTrip = await _showTripModal(context, trip);

    if (updatedTrip != null) {
      setState(() {
        final index = _trips.indexWhere((t) => t['trip_id'] == updatedTrip['trip_id']);
        if (index != -1) {
          _trips[index] = updatedTrip;
        }

        final activeIndex = _activeTrips.indexWhere((t) => t['trip_id'] == updatedTrip['trip_id']);
        if (activeIndex != -1) {
          _activeTrips[activeIndex] = updatedTrip;
        }
      });
    }
  }
  void _startSendingLocation(int tripId) async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString('phone_number');
    if (phone == null) return;

    socket = IO.io('http://${dotenv.env['API_URL']!.split('//')[1]}', {
      'transports': ['websocket'],
      'autoConnect': true,
    });

    socket.connect();

    socket.onConnect((_) {
      print('✅ Connected to socket for live location');
    });

    bool permission = await _requestLocationPermission();
    if (!permission) return;

    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    ).listen((Position position) {
      socket.emit('driver_location', {
        'tripId': tripId,
        'driverPhone': phone,
        'latitude': position.latitude,
        'longitude': position.longitude,
      });

      print('📡 Sent location: ${position.latitude}, ${position.longitude}');
    });
  }
  Future<bool> _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;
    return true;
  }
  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.blueGrey),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              Text(value, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }

  String _formatTime(String time) {
    try {
      final parsed = DateFormat("HH:mm:ss").parse(time);
      return DateFormat.jm().format(parsed); // Converts to AM/PM format
    } catch (_) {
      return time; // fallback in case of invalid format
    }
  }

  Future<void> launchUrl(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not launch $uri';
    }
  }

}
