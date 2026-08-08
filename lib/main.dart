import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase Initialized with correct URL & Publishable Key
  await Supabase.initialize(
    url: 'https://tyonurrbwdjqfrmqrgpk.supabase.co',
    anonKey: 'Sb_publishable_VSX21HOdkHZTTYvxj7DGTQ_tcyv4gDJ',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Padh AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D1117),
        primaryColor: Colors.deepPurpleAccent,
      ),
      home: const AuthScreen(),
    );
  }
}

// --- 1. ऑथेंटिक स्क्रीन (लॉगिन / एडमिन / रजिस्टर) ---
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isAdmin = false;
  bool isRegister = false;

  final _studentNameController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleSubmit() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (isRegister) {
        final response = await Supabase.instance.client.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        if (response.user != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('रजिस्ट्रेशन सफल रहा! 🎉')),
          );
          _navigateToHome();
        }
      } else {
        final response = await Supabase.instance.client.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        if (response.user != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('लॉगिन सफल रहा! 🎉')),
          );
          _navigateToHome();
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = "कनेक्शन सूचना: $e";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen(isAdmin: isAdmin)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Admin/Student Switcher Button
              Align(
                alignment: Alignment.topRight,
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      isAdmin = !isAdmin;
                      isRegister = false;
                      _errorMessage = null;
                    });
                  },
                  icon: Icon(
                    isAdmin ? Icons.person : Icons.admin_panel_settings,
                    color: Colors.tealAccent,
                    size: 20,
                  ),
                  label: Text(
                    isAdmin ? 'स्टूडेंट लॉगिन' : 'Admin Login',
                    style: const TextStyle(
                      color: Colors.tealAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // App Logo with Backup Icon
              Container(
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Image.asset(
                  'assets/padh-ai-logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    decoration: BoxDecoration(
                      color: isAdmin ? Colors.amber.shade700 : Colors.teal.shade400,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Icon(
                      isAdmin ? Icons.key : Icons.smart_toy,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                isAdmin ? 'Padh AI Admin' : 'Padh AI',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 30),

              // Register Extra Fields
              if (isRegister) ...[
                _buildTextField(_studentNameController, 'छात्र का नाम (ऐच्छिक)', Icons.person_outline),
                const SizedBox(height: 16),
                _buildTextField(_fatherNameController, 'पिता/अभिभावक का नाम (ऑप्शनल)', Icons.family_restroom),
                const SizedBox(height: 16),
                _buildTextField(_whatsappController, 'WhatsApp नंबर (ऑप्शनल)', Icons.phone_android),
                const SizedBox(height: 16),
              ],

              // Email & Password Fields
              _buildTextField(
                _emailController,
                isAdmin ? 'एडमिन ईमेल' : 'ईमेल आईडी',
                Icons.alternate_email,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                _passwordController,
                'पासवर्ड',
                Icons.lock_outline,
                isPassword: true,
              ),
              const SizedBox(height: 12),

              // Forgot Password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: const Text(
                    'पासवर्ड भूल गए? (Reset Password)',
                    style: TextStyle(color: Colors.amber, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Login Button
              if (!isRegister)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'लॉगिन करें',
                                style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(width: 8),
                              Text('🚀', style: TextStyle(fontSize: 18)),
                            ],
                          ),
                  ),
                ),

              const SizedBox(height: 16),

              // Register Switch Text
              if (!isAdmin)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      isRegister = !isRegister;
                      _errorMessage = null;
                    });
                  },
                  child: Text(
                    isRegister ? 'पहले से अकाउंट है? लॉगिन करें' : 'नया अकाउंट बनाना है? रजिस्टर करें',
                    style: const TextStyle(
                      color: Colors.tealAccent,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

              if (isRegister) ...[
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'रजिस्टर करें 📝',
                            style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],

              // Error Box
              if (_errorMessage != null) ...[
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        prefixIcon: Icon(icon, color: const Color(0xFF818CF8)),
        filled: true,
        fillColor: const Color(0xFF1E293B),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
        ),
      ),
    );
  }
}

// --- 2. होम स्क्रीन एवं डिजिटल पहाड़ा डैशबोर्ड ---
class HomeScreen extends StatelessWidget {
  final bool isAdmin;
  const HomeScreen({super.key, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isAdmin ? 'Padh AI Admin Dashboard' : 'Padh AI - डिजिटल पढ़ाई'),
        backgroundColor: const Color(0xFF1E293B),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Supabase.instance.client.auth.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const AuthScreen()),
              );
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.deepPurple, Colors.indigo],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAdmin ? 'स्वागत है, एडमिन सर! 👋' : 'नमस्ते छात्र! Padh AI में स्वागत है 📚',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isAdmin ? 'यहाँ से आप अपने सभी बच्चों और डेटा को मैनेज कर सकते हैं।' : 'आइए आज कुछ नया और मजेदार सीखते हैं!',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'सीखने के विकल्प (Modules)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 16),

            // डिजिटल पहाड़ा Card
            _buildFeatureCard(
              context,
              title: '📖 डिजिटल पहाड़ा (Pahada Book)',
              description: '1 से 20 तक के पहाड़े बोलकर और देखकर सीखें।',
              icon: Icons.menu_book_rounded,
              color: Colors.orangeAccent,
              imageAsset: 'assets/padh-ai-pahada-book.jpg',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PahadaScreen()),
                );
              },
            ),
            const SizedBox(height: 16),

            // AI रीडिंग क्लास
            _buildFeatureCard(
              context,
              title: '🤖 AI रीडिंग क्लास',
              description: 'बच्चों के लिए कहानियाँ और पढ़ने की प्रैक्टिस।',
              icon: Icons.record_voice_over,
              color: Colors.tealAccent,
              imageAsset: 'assets/padh-ai-child-reading.jpg',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('AI रीडिंग क्लास जल्द ही शुरू हो रही है!')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required String imageAsset,
    required VoidCallback onTap,
  }) {
    return Card(
      color: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            imageAsset,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => CircleAvatar(
              backgroundColor: color.withOpacity(0.2),
              child: Icon(icon, color: color),
            ),
          ),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
        subtitle: Text(description, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 18),
        onTap: onTap,
      ),
    );
  }
}

// --- 3. डिजिटल पहाड़ा स्क्रीन ---
class PahadaScreen extends StatefulWidget {
  const PahadaScreen({super.key});

  @override
  State<PahadaScreen> createState() => _PahadaScreenState();
}

class _PahadaScreenState extends State<PahadaScreen> {
  int selectedNumber = 2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$selectedNumber का डिजिटल पहाड़ा'),
        backgroundColor: const Color(0xFF1E293B),
      ),
      body: Column(
        children: [
          // Pahada Number Selector Bar
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 20,
              itemBuilder: (context, index) {
                int number = index + 1;
                bool isSelected = number == selectedNumber;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedNumber = number;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.deepPurpleAccent : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? Colors.white : Colors.transparent),
                    ),
                    child: Center(
                      child: Text(
                        '$number',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Pahada Table List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 10,
              itemBuilder: (context, index) {
                int multiplier = index + 1;
                int result = selectedNumber * multiplier;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$selectedNumber  ×  $multiplier',
                        style: const TextStyle(fontSize: 20, color: Colors.tealAccent, fontWeight: FontWeight.bold),
                      ),
                      const Text('=', style: TextStyle(fontSize: 20, color: Colors.white)),
                      Text(
                        '$result',
                        style: const TextStyle(fontSize: 22, color: Colors.amberAccent, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
