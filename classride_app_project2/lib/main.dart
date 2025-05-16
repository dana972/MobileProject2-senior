import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'views/index_screen.dart';
import 'views/owner_dashboard.dart';
import 'views/driver_dashboard.dart';
import 'views/student_dashboard.dart';
import 'views/app_colors.dart'; // ✅ Import your custom colors
import 'views/driver_tracking_page.dart'; // 👈 create this if you haven't
import 'views/student_tracking_page.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // ✅ Required before dotenv.load()

  const keyString = 'Ks93!jsL04@xCj8VtQzY2wMa12345678'; // 👈 Count characters
  print('Key length: ${keyString.length}'); // should print 32
  await dotenv.load(fileName: "./.env");
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.lightBeige,
        primaryColor: AppColors.orange,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.orange,
          foregroundColor: Colors.white,
        ),
        drawerTheme: const DrawerThemeData(
          backgroundColor: AppColors.softGreen,
        ),

        switchTheme: SwitchThemeData(
          thumbColor: MaterialStateProperty.all(AppColors.deepGreen),
          trackColor: MaterialStateProperty.all(AppColors.softGreen),
        ),
        timePickerTheme: TimePickerThemeData(
          backgroundColor: AppColors.lightBeige,
          hourMinuteColor: AppColors.softGreen,
          hourMinuteTextColor: AppColors.deepGreen,
          dialHandColor: AppColors.orange,
          dialBackgroundColor: AppColors.softGreen,
          entryModeIconColor: AppColors.deepGreen,
          dayPeriodTextColor: AppColors.deepGreen,         // Text color for AM/PM
          dayPeriodColor: AppColors.orange,             // Background color
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),

        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.orange,
          backgroundColor: AppColors.lightBeige,
        ).copyWith(
          primary: AppColors.orange,     // 👈 used for AM/PM active toggle
          secondary: AppColors.orange,
        ),
      ),

      initialRoute: '/',
      routes: {
        '/': (context) => const IndexScreen(),
        '/dashboard/owner': (context) => const OwnerDashboard(),
        '/dashboard/driver': (context) => const DriverDashboard(),
        '/dashboard/student': (context) => const StudentDashboard(),
        '/test/driver-tracking': (context) => const DriverTrackingPage(tripId: 'trip_123'),
        '/test/student-tracking': (context) => const StudentTrackingPage(tripId: 'trip_123'),

      },
    );
  }
}
