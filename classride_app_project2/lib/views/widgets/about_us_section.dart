import 'package:flutter/material.dart';

class AboutUsSection extends StatelessWidget {
  final Key? sectionKey;

  const AboutUsSection({super.key, this.sectionKey});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: sectionKey,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      color: const Color(0xFFFFF5E4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'About ClassRide',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF121435),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'ClassRide is a smart transport solution that connects students with trusted bus drivers and helps '
                'bus owners manage their daily operations effortlessly.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 17, height: 1.5, color: Colors.black87),
          ),
          const SizedBox(height: 30),
          Image.asset(
            '../../assets/images/aboutus.jpg',
            width: MediaQuery.of(context).size.width * 0.8, // 80% of screen width
          ),
        ],
      ),
    );
  }
}
