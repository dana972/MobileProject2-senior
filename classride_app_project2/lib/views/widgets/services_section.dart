import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../app_colors.dart';

class ServicesSection extends StatelessWidget {
  const ServicesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.lightBeige,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
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
                showApplyButton: true,
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
    );
  }

  static Widget _buildServiceBox(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String description,
        bool showApplyButton = false,
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
          if (showApplyButton) ...[
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                final token = prefs.getString('auth_token');

                if (token != null && token.isNotEmpty) {
                  _showApplyModal(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please log in to apply as a bus owner.'),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange),
              child: const Text(
                'Apply Now',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static void _showApplyModal(BuildContext context) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Bus Owner Application'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
              ),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // TODO: Submit form data to backend
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Application submitted')),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFFF5722)),
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }
}
