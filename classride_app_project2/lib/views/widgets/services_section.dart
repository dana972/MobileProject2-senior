import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/api_service.dart';
import '../app_colors.dart';
import 'package:intl/intl.dart';

class ServicesSection extends StatelessWidget {
  const ServicesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.lightBeige,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Our Services',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.deepGreen,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              Wrap(
                spacing: 20,
                runSpacing: 20,
                alignment: WrapAlignment.center,
                children: [
                  _buildServiceBox(
                    context,
                    icon: Icons.business_center,
                    title: 'Be a Bus Owner',
                    description: 'Start managing trips, drivers, and students on ClassRide.',
                  ),
                  _buildServiceBox(
                    context,
                    icon: Icons.directions_bus,
                    title: 'Find a Bus to Ride',
                    description: 'Use our chatbot to match with available school buses.',
                  ),
                  _buildServiceBox(
                    context,
                    icon: Icons.person_search,
                    title: 'Find a Bus to Drive',
                    description: 'Drivers can apply to drive buses through our chatbot.',
                  ),
                  _buildServiceBox(
                    context,
                    icon: Icons.group_add,
                    title: 'Join a Known Owner',
                    description: 'Already know a bus owner? Request to join their team.',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildServiceBox(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String description,
      }) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: AppColors.orange),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.deepGreen,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              final token = prefs.getString('auth_token');

              if (token == null || token.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please log in first.')),
                );
                return;
              }

              if (title == 'Be a Bus Owner') {
                _showApplyModal(context);
              } else if (title == 'Join a Known Owner') {
                _showJoinKnownOwnerModal(context);
              } else {
                _showInfoDialog(context, title);
              }

            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange),
            child: const Text('Start Now', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  static void _showApplyModal(BuildContext context) {
    final homeTownController = TextEditingController();
    XFile? selectedImage;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bus Owner Application'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: homeTownController,
                decoration: const InputDecoration(labelText: 'Home Town'),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () async {
                  final picker = ImagePicker();
                  final picked = await picker.pickImage(source: ImageSource.gallery);
                  if (picked != null) {
                    setState(() => selectedImage = picked);
                  }
                },
                icon: const Icon(Icons.image),
                label: Text(selectedImage != null ? 'Change Logo' : 'Upload Bus Logo'),
              ),
              if (selectedImage != null) Text('✔ Logo selected: ${selectedImage!.name}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (homeTownController.text.isEmpty || selectedImage == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields and upload a logo')),
                );
                return;
              }

              Navigator.pop(context);
              final result = await ApiService.submitOwnerApplication(
                homeTown: homeTownController.text,
                logoFile: File(selectedImage!.path),
              );

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(result['message'] ?? 'Application submitted')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  static void _showInfoDialog(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: const Text('This feature will redirect you to our smart chatbot system.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to chatbot or relevant page
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  static void _showJoinKnownOwnerModal(BuildContext context) {
    List<Map<String, String>> ownerOptions = [];
    String? selectedOwnerPhone;
    String? selectedOwnerName;

    final universityController = TextEditingController();
    final addressController = TextEditingController();

    List<Map<String, dynamic>> weeklySchedule = [];

    void addScheduleRow() {
      weeklySchedule.add({
        'day_of_week': null,
        'morning_time': TimeOfDay(hour: 7, minute: 30),
        'return_time': TimeOfDay(hour: 15, minute: 0),
        'attendance_morning': true, // ✅ default to true
        'attendance_return': true,  // ✅ default to true
      });
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join a Known Owner'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return FutureBuilder<List<Map<String, String>>>(
              future: ApiService.fetchOwnerPhoneNamePairs(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                ownerOptions = snapshot.data!;

                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        value: selectedOwnerPhone,
                        decoration: const InputDecoration(labelText: 'Select Owner'),
                        items: ownerOptions.map((owner) {
                          return DropdownMenuItem<String>(
                            value: owner['phone'],
                            child: Text(owner['name'] ?? ''),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            selectedOwnerPhone = val;
                            selectedOwnerName = ownerOptions.firstWhere((o) => o['phone'] == val)['name'];
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: universityController,
                        decoration: const InputDecoration(labelText: 'University'),
                      ),
                      TextField(
                        controller: addressController,
                        decoration: const InputDecoration(labelText: 'Home Address'),
                      ),
                      const SizedBox(height: 15),
                      const Text('Your Weekly Schedule', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Column(
                        children: List.generate(weeklySchedule.length, (index) {
                          final entry = weeklySchedule[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: DropdownButtonFormField<int>(
                                    value: entry['day_of_week'],
                                    decoration: const InputDecoration(labelText: 'Day'),
                                    items: List.generate(7, (i) {
                                      final dayName = DateFormat.E().format(DateTime(2024, 1, i + 1));
                                      return DropdownMenuItem(
                                        value: i + 1,
                                        child: Text(dayName),
                                      );
                                    }),
                                    onChanged: (val) {
                                      setState(() => weeklySchedule[index]['day_of_week'] = val);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  flex: 2,
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      final picked = await showTimePicker(
                                        context: context,
                                        initialTime: entry['morning_time'],
                                      );
                                      if (picked != null) {
                                        setState(() => weeklySchedule[index]['morning_time'] = picked);
                                      }
                                    },
                                    child: Text('Morning: ${entry['morning_time'].format(context)}'),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  flex: 2,
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      final picked = await showTimePicker(
                                        context: context,
                                        initialTime: entry['return_time'],
                                      );
                                      if (picked != null) {
                                        setState(() => weeklySchedule[index]['return_time'] = picked);
                                      }
                                    },
                                    child: Text('Return: ${entry['return_time'].format(context)}'),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => setState(() => weeklySchedule.removeAt(index)),
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                      TextButton.icon(
                        onPressed: () => setState(() => addScheduleRow()),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Day'),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (selectedOwnerPhone == null ||
                  universityController.text.isEmpty ||
                  addressController.text.isEmpty ||
                  weeklySchedule.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields and add schedule')),
                );
                return;
              }

              final schedule = weeklySchedule
                  .where((e) => e['day_of_week'] != null)
                  .map((e) => {
                'day_of_week': e['day_of_week'],
                'morning_time': e['morning_time'].format(context),
                'return_time': e['return_time'].format(context),
                'attendance_morning': e['attendance_morning'],
                'attendance_return': e['attendance_return'],
              })
                  .toList();


              Navigator.pop(context);

              final success = await ApiService.sendJoinRequest(
                ownerPhone: selectedOwnerPhone!,
                university: universityController.text,
                address: addressController.text,
                schedule: schedule,
              );

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(success
                      ? 'Request sent successfully.'
                      : 'Failed to send request.'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

}
