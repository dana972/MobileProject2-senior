import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'views/index_screen.dart';
import 'views/owner_dashboard.dart';
import 'views/driver_dashboard.dart';
import 'views/student_dashboard.dart';

Future<void> main() async {
  await dotenv.load(fileName: "../.env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const IndexScreen(),
        '/dashboard/owner': (context) => const OwnerDashboard(),
        '/dashboard/driver': (context) => const DriverDashboard(),
        '/dashboard/student': (context) => const StudentDashboard(),
        // ✅ Removed assigned-trips route because it's now a section
      },
    );
  }
}
