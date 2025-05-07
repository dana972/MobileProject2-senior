import 'package:flutter/material.dart';

class ServicesSection extends StatelessWidget {
  const ServicesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFAF9F0),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Our Services',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF121435),
            ),
          ),
          const SizedBox(height: 30),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: [
              _buildServiceBox(
                icon: Icons.business_center,
                title: 'Be a Bus Owner',
                description: 'Start managing trips, drivers, and students on ClassRide.',
              ),
              _buildServiceBox(
                icon: Icons.directions_bus,
                title: 'Find a Bus to Ride',
                description: 'Use our chatbot to match with available school buses.',
              ),
              _buildServiceBox(
                icon: Icons.person_search,
                title: 'Find a Bus to Drive',
                description: 'Drivers can apply to drive buses through our chatbot.',
              ),
              _buildServiceBox(
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

  Widget _buildServiceBox({
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
          Icon(icon, size: 48, color: Color(0xFFFF5722)),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF121435),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
