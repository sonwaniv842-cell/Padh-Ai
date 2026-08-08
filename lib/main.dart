import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:url_launcher/url_launcher.dart';

// --- CONFIG ---
const supabaseUrl = 'https://tyonurrbwdjqfrmqrgpk.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR5b251cnJid2RqcWZybXFyZ3BrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDAzODU1NzksImV4cCI6MjA1NTk2MTU3OX0.aD4e71Hl74L_B5j65lK2I9w0I2jL0Z828Z458L99I20';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  runApp(const PadhAIApp());
}

final supabase = Supabase.instance.client;

class PadhAIApp extends StatelessWidget {
  const PadhAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        primaryColor: const Color(0xFF6C63FF),
        scaffoldBackgroundColor: const Color(0xFF0D0D1E),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.dark,
        ),
      ),
      home: supabase.auth.currentSession == null ? const AuthScreen() : const MainContainer(),
    );
  }
}

// --- 1. AUTH SCREEN (LOGIN + SIGNUP TOGGLE) ---
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
  bool _isLoading = false;

  Future<void> _handleAuth() async {
    if (_emailController.text.isEmpty || _passController.text.isEmpty) {
      _showMsg("ईमेल और पासवर्ड ज़रूरी हैं");
      return;
    }
    setState(() => _isLoading = true);
    try {
      if (_isSignUp) {
        final res = await supabase.auth.signUp(
          email: _emailController.text.trim(),
          password: _passController.text.trim(),
        );
        if (res.user != null) {
          await supabase.from('profiles').upsert({
            'id': res.user!.id,
            'full_name': _nameController.text.trim(),
            'parent_name': _pNameController.text.trim(),
            'parent_phone': _pPhoneController.text.trim(),
          });
        }
      } else {
        await supabase.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passController.text.trim(),
        );
      }

      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const MainContainer()));
      }
    } catch (e) {
      _showMsg("त्रुटि: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMsg(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            const SizedBox(height: 70),
            const Text("Padh AI", style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Color(0xFF6C63FF))),
            Text(_isSignUp ? "नया अकाउंट बनायें" : "अपने अकाउंट में लॉगिन करें", style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 40),

            if (_isSignUp) ...[
              _buildField(_nameController, "छात्र का नाम", Icons.person),
              _buildField(_pNameController, "पिता/अभिभावक का नाम", Icons.people),
              _buildField(_pPhoneController, "WhatsApp नंबर", Icons.chat),
            ],

            _buildField(_emailController, "ईमेल आईडी", Icons.email),
            _buildField(_passController, "पासवर्ड", Icons.lock, isPass: true),

            const SizedBox(height: 25),
            _isLoading
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(onPressed: _handleAuth, child: Text(_isSignUp ? "रजिस्टर करें" : "लॉगिन करें")),
                  ),

            TextButton(
              onPressed: () => setState(() => _isSignUp = !_isSignUp),
              child: Text(_isSignUp ? "पहले से अकाउंट है? लॉगिन करें" : "नया अकाउंट बनाना है? रजिस्टर करें"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, {bool isPass = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        obscureText: isPass,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF6C63FF)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        ),
      ),
    );
  }
}

// --- 2. MAIN DASHBOARD ---
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
        final data = await supabase.from('profiles').select().eq('id', user.id).maybeSingle();
        setState(() {
          userProfile = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _speakTrustMessage() async {
    String msg = "नमस्ते अभिभावक, हम पढ़ाई के नाम पर कोई फीस नहीं लेते। ₹50 की फीस केवल टेस्ट के लिए है जो बच्चों के इनाम और स्कॉलरशिप के काम आती है।";
    await flutterTts.setLanguage("hi-IN");
    await flutterTts.speak(msg);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Padh AI Home"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
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
        child: Column(
          children: [
            Container(
              height: 150,
              width: double.infinity,
              color: Colors.deepPurple,
              child: const Center(
                child: Text("Padh AI Scholarship", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(15),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("पैरेंट्स के लिए संदेश", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.volume_up, size: 30, color: Colors.blueAccent),
                            onPressed: _speakTrustMessage,
                          ),
                        ],
                      ),
                      const Text("हम पढ़ाई के लिए ₹1 भी फीस नहीं लेते। टेस्ट फीस ₹50 बच्चों के भविष्य के इनामों के लिए है।"),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(15),
              child: userProfile?['has_paid'] == true
                  ? const Card(child: ListTile(leading: Icon(Icons.check_circle, color: Colors.green), title: Text("एग्जाम अनलॉक है ✅")))
                  : const Card(child: ListTile(leading: Icon(Icons.lock, color: Colors.red), title: Text("एग्जाम लॉक है (₹50 फीस लंबित)"))),
            ),
          ],
        ),
      ),
    );
  }
}
