import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase Initialized with correct URL & Key
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
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = "कनेक्शन सूचना: AuthRetryableFetchException(message: ClientException with SocketException: $e)";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAlignment.center,
            children: [
              // Top Right Switch Button (Admin/Student)
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

              // Logo Image / Icon
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

              // Form Fields
              if (isRegister) ...[
                _buildTextField(_studentNameController, 'छात्र का नाम (ऐच्छिक)', Icons.person_outline),
                const SizedBox(height: 16),
                _buildTextField(_fatherNameController, 'पिता/अभिभावक का नाम (ऑप्शनल)', Icons.family_restroom),
                const SizedBox(height: 16),
                _buildTextField(_whatsappController, 'WhatsApp नंबर (ऑप्शनल)', Icons.phone_android),
                const SizedBox(height: 16),
              ],

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

              // Forgot Password Option
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

              // Submit Button
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

              // Toggle Register/Login Link
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
