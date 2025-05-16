import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TripHistory extends StatefulWidget {
  const TripHistory({Key? key}) : super(key: key);

  @override
  _TripHistoryState createState() => _TripHistoryState();
}

class _TripHistoryState extends State<TripHistory> {
  List<Map<String, dynamic>> trips = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCompletedTrips();
  }

  Future<void> fetchCompletedTrips() async {
    // Fetch the driver's phone number from shared preferences
    final prefs = await SharedPreferences.getInstance();
    final driverPhone = prefs.getString('phone_number');  // Assuming phone_number is stored after login.

    if (driverPhone == null) {
      // Handle the case where the phone number is not available
      print('Driver phone number not found');
      return;
    }

    final url = 'http://yourapi.com/api/driver/$driverPhone/completed-trips';  // Replace with actual API URL

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          trips = List<Map<String, dynamic>>.from(data['trips']);
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        throw Exception('Failed to load trips');
      }
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      print("Error fetching trips: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Trip History", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 4,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 24,
                headingRowColor: MaterialStateProperty.all(Colors.grey[200]),
                columns: const [
                  DataColumn(label: Text('Trip ID', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: trips.map((trip) {
                  return DataRow(cells: [
                    DataCell(Text('${trip['id']}')),
                    DataCell(Text(trip['date'])),
                    DataCell(
                      ElevatedButton(
                        onPressed: () => _showTripDetailsDialog(context, trip),
                        child: const Text("View Payments"),
                      ),
                    ),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ],
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
          children: trip['assigned_students'].map<Widget>((student) {
            return ListTile(
              title: Text(student['name']),
              trailing: Switch(
                value: student['paymentStatus'],
                onChanged: (bool value) {
                  // You could add functionality here to update payment status via the backend
                },
                activeColor: Colors.green,
                inactiveThumbColor: Colors.red,
                inactiveTrackColor: Colors.red.shade200,
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close"))
        ],
      ),
    );
  }
}
