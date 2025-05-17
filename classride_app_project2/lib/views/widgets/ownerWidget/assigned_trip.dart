import 'package:flutter/material.dart';

class AssignedTripsSection extends StatefulWidget {
  const AssignedTripsSection({super.key});

  @override
  State<AssignedTripsSection> createState() => _AssignedTripsSectionState();
}

class _AssignedTripsSectionState extends State<AssignedTripsSection> {
  String? selectedBus;
  String? selectedDriver;
  String? selectedDestination;
  String? selectedTripType;
  TimeOfDay? pickTime;
  TimeOfDay? dropOffTime;

  final List<String> buses = ['Bus 16', 'Bus 22'];
  final List<String> drivers = ['Driver A', 'Driver B'];
  final List<String> destinations = ['liuu', 'school'];
  final List<String> tripTypes = ['MORNING', 'RETURN'];

  final List<Map<String, dynamic>> students = [
    {'name': 'Student A', 'phone': '1234567890'},
    {'name': 'Student B', 'phone': '9876543210'},
  ];

  String? selectedStudent;
  String? selectedNewTrip;

  void _showCreateTripDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Create Trip"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Select Bus'),
                value: selectedBus,
                onChanged: (value) => setState(() => selectedBus = value),
                items: buses.map((bus) => DropdownMenuItem(value: bus, child: Text(bus))).toList(),
              ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Assign Driver'),
                value: selectedDriver,
                onChanged: (value) => setState(() => selectedDriver = value),
                items: drivers.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
              ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Destination'),
                value: selectedDestination,
                onChanged: (value) => setState(() => selectedDestination = value),
                items: destinations.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
              ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Trip Type'),
                value: selectedTripType,
                onChanged: (value) => setState(() => selectedTripType = value),
                items: tripTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              ),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        TimeOfDay? picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                        if (picked != null) setState(() => pickTime = picked);
                      },
                      child: Text(pickTime == null ? "Pick Time" : pickTime!.format(context)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        TimeOfDay? picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                        if (picked != null) setState(() => dropOffTime = picked);
                      },
                      child: Text(dropOffTime == null ? "Drop-off Time" : dropOffTime!.format(context)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              // Submit logic here
              Navigator.pop(context);
            },
            child: const Text("Submit"),
          )
        ],
      ),
    );
  }

  void _showTransferStudentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Transfer Student to Another Trip"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Select Assigned Student"),
              ...students.map((student) => RadioListTile<String>(
                title: Text("${student['name']} - ${student['phone']}"),
                value: student['name'],
                groupValue: selectedStudent,
                onChanged: (value) => setState(() => selectedStudent = value),
              )),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Select New Trip'),
                value: selectedNewTrip,
                onChanged: (value) => setState(() => selectedNewTrip = value),
                items: ["liuu - 03:00", "school - 08:00"]
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              // Transfer logic
              Navigator.pop(context);
            },
            child: const Text("Transfer"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Manage Trips for Tomorrow", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("Here is where you manage your trips for tomorrow."),
          const SizedBox(height: 20),
          const Text("Scheduled Trips", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            children: [
              _tripCard("RETURN", "Bus: 16", "03:30 - 04:15", "To: liuu"),
              const SizedBox(width: 10),
              _tripCard("MORNING", "Bus: 16", "08:00 - 09:15", "To: liuu"),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              ElevatedButton(
                onPressed: _showCreateTripDialog,
                child: const Text("Create Trip"),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _showTransferStudentDialog,
                child: const Text("Transfer Student"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tripCard(String type, String bus, String time, String destination) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 5)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(type, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(bus),
            Text(time),
            Text(destination),
          ],
        ),
      ),
    );
  }
}

