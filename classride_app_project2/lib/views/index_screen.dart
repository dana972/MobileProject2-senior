import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import './widgets/about_us_section.dart';
import './widgets/services_section.dart';
import './app_colors.dart';

class IndexScreen extends StatefulWidget {
  const IndexScreen({super.key});

  @override
  State<IndexScreen> createState() => _IndexScreenState();
}

class _IndexScreenState extends State<IndexScreen> {
  bool showLoginModal = false;
  bool isLogin = true;

  String? userRole;
  final GlobalKey _servicesKey = GlobalKey();
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBeige,
      appBar: AppBar(
        backgroundColor: AppColors.deepGreen,
        title: Row(
          children: const [
            Icon(Icons.directions_bus, color: AppColors.orange),
            SizedBox(width: 10),
            Text('ClassRide', style: TextStyle(color: Colors.white)),//background of the home
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: Drawer(
        backgroundColor: AppColors.lightBeige,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: AppColors.deepGreen),
              child: Row(
                children: [
                  Icon(Icons.directions_bus, color: AppColors.orange, size: 32),
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
              leading: const Icon(Icons.design_services),
              title: const Text('Services'),
              onTap: () {
                Navigator.pop(context);
                Future.delayed(const Duration(milliseconds: 300), () {
                  Scrollable.ensureVisible(
                    _servicesKey.currentContext!,
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
                LayoutBuilder(
                  builder: (context, constraints) {
                    bool isMobile = constraints.maxWidth < 700;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isMobile) ...[
                          _buildImageSection(),
                          const SizedBox(height: 30),
                          _buildTextSection(),
                        ] else ...[
                          Row(
                            children: [
                              Expanded(child: _buildTextSection()),
                              const SizedBox(width: 40),
                              Expanded(child: _buildImageSection()),
                            ],
                          ),
                        ],
                      ],
                    );
                  },
                ),

                const SizedBox(height: 200),
                Container(
                  key: _aboutUsKey,
                  child: const AboutUsSection(),
                ),
                const SizedBox(height: 40),
                Container(
                  key: _servicesKey,
                  child: const ServicesSection(),
                ),
              ],
            ),
          ),
          if (showLoginModal) _buildLoginModal(),
        ],
      ),
    );
  }

  Widget _buildLoginModal() {
    return Positioned.fill(
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
                color: AppColors.lightBeige,
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
                          backgroundColor: AppColors.deepGreen,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _toggleLoginModal,
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.orange,
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
    );
  }

  Widget _buildTextSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hop on.\nTrack live.\nNever miss a ride with ClassRide.',
          style: TextStyle(
            fontSize: 50,
            fontWeight: FontWeight.bold,
            color: AppColors.deepGreen,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'ClassRide connects bus owners, drivers, and students in one smart platform — for hassle-free campus rides.',
          style: TextStyle(fontSize: 16, color: Colors.black87),
        ),
        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: () async {
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
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
          child: const Text(
            'CONTACT US',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ),

      ],
    );
  }

  Widget _buildImageSection() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          'assets/images/bustracking.jpg',
          fit: BoxFit.contain,
        ),
      ),
    );
  }

}