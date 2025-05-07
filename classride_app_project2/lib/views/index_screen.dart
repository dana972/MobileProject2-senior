import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import './widgets/about_us_section.dart';
import './widgets/services_section.dart';

class IndexScreen extends StatefulWidget {
  const IndexScreen({super.key});

  @override
  State<IndexScreen> createState() => _IndexScreenState();
}

class _IndexScreenState extends State<IndexScreen> {
  bool showLoginModal = false;
  bool isLogin = true;

  String? userRole;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _aboutUsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  void _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userRole = prefs.getString('role');
    });
  }

  void _toggleLoginModal() {
    setState(() {
      showLoginModal = !showLoginModal;
      isLogin = true;
    });
  }

  void _switchFormMode() {
    setState(() {
      isLogin = !isLogin;
    });
  }

  void _handleAuthAction() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    try {
      Map<String, dynamic> result;

      if (isLogin) {
        result = await ApiService.login(phoneNumber: phone, password: password);
      } else {
        result = await ApiService.signup(fullName: name, phoneNumber: phone, password: password);
      }

      print("✅ API response: $result");

      final prefs = await SharedPreferences.getInstance();

      if (result.containsKey('role') && result['role'] != null) {
        await prefs.setString('role', result['role']);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Signup failed')),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Success')),
      );

      _toggleLoginModal();
      _loadUserRole();
    } catch (e) {
      print("❌ Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121435),
        title: Row(
          children: const [
            Icon(Icons.directions_bus, color: Color(0xFFFF5722)),
            SizedBox(width: 10),
            Text('ClassRide', style: TextStyle(color: Colors.white)),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFFEDEBCA),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF121435)),
              child: Row(
                children: [
                  Icon(Icons.directions_bus, color: Color(0xFFFF5722), size: 32),
                  SizedBox(width: 10),
                  Text('ClassRide', style: TextStyle(color: Colors.white, fontSize: 24)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('About Us'),
              onTap: () {
                Navigator.pop(context);
                Future.delayed(const Duration(milliseconds: 300), () {
                  Scrollable.ensureVisible(
                    _aboutUsKey.currentContext!,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                  );
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.contact_mail),
              title: const Text('Contact Us'),
              onTap: () async {
                const whatsappNumber = '96171125228';
                const message = 'Hello ClassRide team, I need help';
                final url = Uri.parse('https://wa.me/$whatsappNumber?text=${Uri.encodeComponent(message)}');

                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Could not open WhatsApp')),
                  );
                }
              },
            ),
            if (userRole != null && userRole != 'pending')
              ListTile(
                leading: const Icon(Icons.dashboard),
                title: const Text('Dashboard'),
                onTap: () {
                  Navigator.pop(context);
                  if (userRole == 'owner') {
                    Navigator.pushNamed(context, '/dashboard/owner');
                  } else if (userRole == 'driver') {
                    Navigator.pushNamed(context, '/dashboard/driver');
                  } else if (userRole == 'student') {
                    Navigator.pushNamed(context, '/dashboard/student');
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invalid role')),
                    );
                  }
                },
              ),
            ListTile(
              leading: Icon(userRole != null ? Icons.logout : Icons.login),
              title: Text(userRole != null ? 'Logout' : 'Login / Signup'),
              onTap: () async {
                Navigator.pop(context);
                if (userRole != null) {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();
                  setState(() {
                    userRole = null;
                  });
                  Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                } else {
                  _toggleLoginModal();
                }
              },
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    'Welcome to ClassRide App!',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF121435),
                    ),
                  ),
                ),
                const SizedBox(height: 300), // spacing
                Container(
                  key: _aboutUsKey,
                  child: const AboutUsSection(),
                ),
                const SizedBox(height: 40),
                const ServicesSection(), // ✅ Add this
              ],
            ),
          ),
          if (showLoginModal)
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggleLoginModal,
                child: Container(
                  color: Colors.black.withOpacity(0.6),
                  alignment: Alignment.center,
                  child: GestureDetector(
                    onTap: () {},
                    child: Container(
                      width: 350,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDEBCA),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isLogin ? 'Login' : 'Sign Up',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF121435),
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (!isLogin)
                            Column(
                              children: [
                                TextField(
                                  controller: _nameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Full Name',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 15),
                              ],
                            ),
                          TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Phone Number',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 15),
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Password',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF121435),
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: _toggleLoginModal,
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF5722),
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: _handleAuthAction,
                                child: Text(isLogin ? 'Login' : 'Sign Up'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          TextButton(
                            onPressed: _switchFormMode,
                            child: Text(
                              isLogin ? "Don't have an account? Sign Up" : "Already have an account? Login",
                              style: const TextStyle(color: Color(0xFF121435)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
