import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_tts/flutter_tts.dart';

// --- CONFIG ---
const supabaseUrl = 'https://tyonurrbwdjqfrmqrgpk.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR5b251cnJid2RqcWZybXFyZ3BrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDAzODU1NzksImV4cCI6MjA1NTk2MTU3OX0.aD4e71Hl74L_B5j65lK2I9w0I2jL0Z828Z458L99I20';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: supabaseUrl, 
    anonKey: supabaseAnonKey,
  );
  runApp(const PadhAIApp());
}

final supabase = Supabase.instance.client;

class PadhAIApp extends StatelessWidget {
  const PadhAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Padh AI',
      debugShowCheckedModeBanner: false,
      // --- Padh AI Studio Dark Navy & Purple Premium Theme ---
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0B0E17),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6C4CE0),
          secondary: Color(0xFF00D2A0),
          surface: Color(0xFF131827),
        ),
        cardTheme: CardTheme(
          color: const Color(0xFF131827),
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFF232B42), width: 1),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF192033),
          labelStyle: const TextStyle(color: Color(0xFFA0AEC0)),
          prefixIconColor: const Color(0xFF6C4CE0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF232B42)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF232B42)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF6C4CE0), width: 2),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6C4CE0),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      home: supabase.auth.currentSession == null ? const AuthScreen() : const MainContainer(),
    );
  }
}

// --- 1. AUTH SCREEN (USER & ADMIN LOGIN) ---
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _nameController = TextEditingController();
  final _pNameController = TextEditingController();
  final _pPhoneController = TextEditingController();

  bool _isSignUp = true;
  bool _isAdminMode = false;
  bool _isLoading = false;

  Future<void> _handleAuth() async {
    final email = _emailController.text.trim();
    final password = _passController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMsg("ईमेल और पासवर्ड ज़रूरी हैं");
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isAdminMode) {
        // Admin Login
        final res = await supabase.auth.signInWithPassword(
          email: email,
          password: password,
        ).timeout(const Duration(seconds: 20));

        if (res.user != null) {
          if (mounted) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const AdminDashboardScreen()));
          }
        }
      } else if (_isSignUp) {
        // Student Signup (Father's Name & Phone are now OPTIONAL)
        final res = await supabase.auth.signUp(
          email: email,
          password: password,
        ).timeout(const Duration(seconds: 20), onTimeout: () {
          throw 'इंटरनेट धीमा है, कृपया दोबारा प्रयास करें।';
        });

        if (res.user != null) {
          final pName = _pNameController.text.trim();
          final pPhone = _pPhoneController.text.trim();

          await supabase.from('profiles').upsert({
            'id': res.user!.id,
            'full_name': _nameController.text.trim().isEmpty ? 'छात्र' : _nameController.text.trim(),
            'parent_name': pName.isEmpty ? 'N/A' : pName,
            'parent_phone': pPhone.isEmpty ? 'N/A' : pPhone,
            'is_admin': false,
          }).timeout(const Duration(seconds: 15));
        }
        if (mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const MainContainer()));
        }
      } else {
        // Student Login
        await supabase.auth.signInWithPassword(
          email: email,
          password: password,
        ).timeout(const Duration(seconds: 20), onTimeout: () {
          throw 'इंटरनेट धीमा है, नेटवर्क चेक करें।';
        });

        if (mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const MainContainer()));
        }
      }
    } catch (e) {
      String errStr = e.toString();
      if (errStr.contains('SocketException') || errStr.contains('Failed host lookup')) {
        _showMsg("नेटवर्क एरर: आपका इंटरनेट धीमा या बंद है।");
      } else {
        _showMsg("सूचना: $errStr");
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF232B42),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Top Bar with Admin Toggle Button
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _isAdminMode = !_isAdminMode;
                        _isSignUp = false;
                      });
                    },
                    icon: Icon(_isAdminMode ? Icons.person : Icons.admin_panel_settings, color: const Color(0xFF00D2A0)),
                    label: Text(
                      _isAdminMode ? "स्टूडेंट लॉगिन" : "🔒 Admin Login",
                      style: const TextStyle(color: Color(0xFF00D2A0), fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 10),

              // AI Studio Stylish Logo Header
              Container(
                width: 85,
                height: 85,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isAdminMode 
                      ? [const Color(0xFFFF5252), const Color(0xFF6C4CE0)]
                      : [const Color(0xFF6C4CE0), const Color(0xFF00D2A0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C4CE0).withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Center(
                  child: Text(_isAdminMode ? "🔑" : "🤖", style: const TextStyle(fontSize: 42)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_isAdminMode ? "Padh AI Admin" : "Padh AI", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.extrabold, color: Colors.white)),
                  const SizedBox(width: 6),
                  const Icon(Icons.auto_awesome, color: Color(0xFF00D2A0), size: 24),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _isAdminMode 
                  ? "एडमिन पैनल में प्रवेश करें" 
                  : (_isSignUp ? "स्मार्ट एआई लर्निंग - नया अकाउंट बनाएं" : "आपका स्वागत है - लॉगिन करें"),
                style: const TextStyle(color: Color(0xFFA0AEC0), fontSize: 14),
              ),
              const SizedBox(height: 35),

              // FORM FIELDS
              if (_isSignUp && !_isAdminMode) ...[
                _buildField(_nameController, "छात्र का नाम (ऐच्छिक)", Icons.person_outline),
                _buildField(_pNameController, "पिता/अभिभावक का नाम (ऑप्शनल)", Icons.family_restroom_outlined),
                _buildField(_pPhoneController, "WhatsApp नंबर (ऑप्शनल)", Icons.phone_android_outlined),
              ],

              _buildField(_emailController, _isAdminMode ? "एडमिन ईमेल" : "ईमेल आईडी", Icons.alternate_email_outlined),
              _buildField(_passController, "पासवर्ड", Icons.lock_outline, isPass: true),

              const SizedBox(height: 20),
              
              _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF00D2A0)))
                  : SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _handleAuth,
                        child: Text(
                          _isAdminMode 
                            ? "एडमिन लॉगिन करें 🔓" 
                            : (_isSignUp ? "रजिस्टर करें ✨" : "लॉगिन करें 🚀")
                        ),
                      ),
                    ),

              if (!_isAdminMode) ...[
                const SizedBox(height: 15),
                TextButton(
                  onPressed: () => setState(() => _isSignUp = !_isSignUp),
                  child: Text(
                    _isSignUp ? "पहले से अकाउंट है? लॉगिन करें" : "नया अकाउंट बनाना है? रजिस्टर करें",
                    style: const TextStyle(color: Color(0xFF00D2A0), fontWeight: FontWeight.w600),
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, {bool isPass = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        obscureText: isPass,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
        ),
      ),
    );
  }
}

// --- 2. STUDENT DASHBOARD ---
class MainContainer extends StatefulWidget {
  const MainContainer({super.key});

  @override
  State<MainContainer> createState() => _MainContainerState();
}

class _MainContainerState extends State<MainContainer> {
  Map<String, dynamic>? userProfile;
  final FlutterTts flutterTts = FlutterTts();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final data = await supabase
            .from('profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle()
            .timeout(const Duration(seconds: 15));
        
        setState(() {
          userProfile = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _speakTrustMessage() async {
    String msg = "नमस्ते अभिभावक, हम पढ़ाई के नाम पर कोई फीस नहीं लेते। ₹50 की फीस केवल टेस्ट के लिए है जो बच्चों के इनाम और स्कॉलरशिप के काम आती है।";
    await flutterTts.setLanguage("hi-IN");
    await flutterTts.speak(msg);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFF6C4CE0))),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF131827),
        elevation: 0,
        title: Row(
          children: const [
            Text("🤖 Padh AI", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            SizedBox(width: 6),
            Icon(Icons.auto_awesome, color: Color(0xFF00D2A0), size: 18),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFFFF5252)),
            onPressed: () async {
              await supabase.auth.signOut();
              if (mounted) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const AuthScreen()));
              }
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C4CE0), Color(0xFF4A2FB5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C4CE0).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text("🏆 Padh AI Scholarship Test", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  SizedBox(height: 6),
                  Text("अपनी तैयारी जांचें और स्कॉलरशिप पाएं", style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("पैरेंट्स के लिए संदेश 👨‍👩‍👧", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        IconButton(
                          icon: const Icon(Icons.volume_up_rounded, size: 28, color: Color(0xFF00D2A0)),
                          onPressed: _speakTrustMessage,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "हम पढ़ाई के लिए ₹1 भी फीस नहीं लेते। टेस्ट फीस ₹50 बच्चों के भविष्य के इनामों और स्कॉलरशिप के लिए है।",
                      style: TextStyle(color: Color(0xFFA0AEC0), height: 1.5, fontSize: 13.5),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),

            userProfile?['has_paid'] == true
                ? Card(
                    child: ListTile(
                      leading: const Icon(Icons.check_circle_rounded, color: Color(0xFF00D2A0), size: 30),
                      title: const Text("एग्जाम अनलॉक है ✅", style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text("आप टेस्ट देने के लिए पात्र हैं"),
                    ),
                  )
                : Card(
                    child: ListTile(
                      leading: const Icon(Icons.lock_clock_rounded, color: Color(0xFFFF5252), size: 30),
                      title: const Text("एग्जाम लॉक है", style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text("₹50 फीस लंबित है", style: TextStyle(color: Color(0xFFFF5252))),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

// --- 3. ADMIN DASHBOARD SCREEN ---
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  List<dynamic> _students = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    try {
      final data = await supabase.from('profiles').select().order('id');
      setState(() {
        _students = data;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF131827),
        title: const Text("🔒 Admin Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFFFF5252)),
            onPressed: () async {
              await supabase.auth.signOut();
              if (mounted) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const AuthScreen()));
              }
            },
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00D2A0)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _students.length,
              itemBuilder: (context, index) {
                final student = _students[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFF6C4CE0),
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(student['full_name'] ?? 'अज्ञात छात्र', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("पिता: ${student['parent_name'] ?? 'N/A'} | फोन: ${student['parent_phone'] ?? 'N/A'}"),
                    trailing: Icon(
                      student['has_paid'] == true ? Icons.check_circle : Icons.pending,
                      color: student['has_paid'] == true ? const Color(0xFF00D2A0) : const Color(0xFFFF5252),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
