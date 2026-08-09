import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:url_launcher/url_launcher.dart';

// --- SUPABASE CONFIGURATION ---
const supabaseUrl = 'https://tyonurrbwdjqfrmqrgpk.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR5b251cnJid2RqcWZybXFyZ3BrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODYxNzMzODMsImV4cCI6MjEwMTc0OTM4M30.95tDST7gwxemb2w2SS71arWh77omlFf0ezPwkTun2cM';

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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6C63FF), brightness: Brightness.dark),
      ),
      home: supabase.auth.currentSession == null ? const AuthScreen() : const MainDashboard(),
    );
  }
}

// --- 1. AUTH SCREEN (LOGIN/SIGNUP TOGGLE) ---
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _name = TextEditingController();
  final _pName = TextEditingController();
  final _pPhone = TextEditingController();
  bool _isSignUp = true;
  bool _loading = false;

  Future<void> _handleAuth() async {
    setState(() => _loading = true);
    try {
      if (_isSignUp) {
        final res = await supabase.auth.signUp(email: _email.text.trim(), password: _pass.text.trim());
        if (res.user != null) {
          await supabase.from('profiles').upsert({
            'id': res.user!.id, 
            'full_name': _name.text, 
            'parent_name': _pName.text, 
            'parent_phone': _pPhone.text,
          });
        }
      } else {
        await supabase.auth.signInWithPassword(email: _email.text.trim(), password: _pass.text.trim());
      }
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const MainDashboard()));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            const SizedBox(height: 70),
            const Text("Padh AI", style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Color(0xFF6C63FF))),
            const SizedBox(height: 30),
            if (_isSignUp) ...[
              _buildField(_name, "छात्र का नाम", Icons.person),
              _buildField(_pName, "अभिभावक का नाम", Icons.people),
              _buildField(_pPhone, "WhatsApp नंबर", Icons.chat_bubble_outline),
            ],
            _buildField(_email, "ईमेल", Icons.email),
            _buildField(_pass, "पासवर्ड", Icons.lock, isPass: true),
            const SizedBox(height: 25),
            _loading ? const CircularProgressIndicator() : SizedBox(width: double.infinity, height: 55, child: ElevatedButton(onPressed: _handleAuth, child: Text(_isSignUp ? "रजिस्टर करें" : "लॉगिन करें"))),
            TextButton(onPressed: () => setState(() => _isSignUp = !_isSignUp), child: Text(_isSignUp ? "अकाउंट है? लॉगिन करें" : "नया अकाउंट बनायें"))
          ],
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController c, String l, IconData i, {bool isPass = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(controller: c, obscureText: isPass, decoration: InputDecoration(labelText: l, prefixIcon: Icon(i, color: const Color(0xFF6C63FF)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)))),
    );
  }
}

// --- 2. MAIN DASHBOARD ---
class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});
  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  Map<String, dynamic>? profile;
  int _tab = 0;
  final _tts = FlutterTts();

  @override
  void initState() { super.initState(); _load(); }

  _load() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      final data = await supabase.from('profiles').select().eq('id', user.id).maybeSingle();
      setState(() => profile = data ?? {'full_name': 'Student', 'is_admin': false});
    }
  }

  void _speak() async {
    await _tts.setLanguage("hi-IN");
    await _tts.speak("नमस्ते, हम पढ़ाई के लिए कोई फीस नहीं लेते। ₹50 टेस्ट फीस बच्चों के इनाम के लिए है।");
  }

  @override
  Widget build(BuildContext context) {
    if (profile == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: Text("Padh AI: ${profile!['full_name'] ?? 'User'}"), actions: [
        if (profile!['is_admin'] == true) IconButton(icon: const Icon(Icons.admin_panel_settings, color: Colors.orange), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AdminPage()))),
        IconButton(icon: const Icon(Icons.logout), onPressed: () => supabase.auth.signOut())
      ]),
      body: _tab == 0 ? _homeView() : _examView(),
      bottomNavigationBar: BottomNavigationBar(currentIndex: _tab, onTap: (i) => setState(() => _tab = i), items: const [
        BottomNavigationBarItem(icon: Icon(Icons.school), label: "Learn"),
        BottomNavigationBarItem(icon: Icon(Icons.quiz), label: "Exam"),
      ]),
    );
  }

  Widget _homeView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Image.network(profile?['banner_url'] ?? 'https://placehold.co/600x200/6C63FF/white?text=Padh+AI', height: 150, width: double.infinity, fit: BoxFit.cover),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Card(child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text("पैरेंट्स के लिए संदेश", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.volume_up, size: 30, color: Colors.blueAccent), onPressed: _speak),
                ]),
                const Text("पढ़ाई ₹0। टेस्ट फीस ₹50 इनामों (TV/Cycle) के लिए। हम ₹1 भी अपने पास नहीं रखते।"),
              ]),
            )),
          ),
        ],
      ),
    );
  }

  Widget _examView() {
    bool paid = profile?['has_paid'] ?? false;
    return Center(child: Padding(
      padding: const EdgeInsets.all(25),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(paid ? Icons.check_circle : Icons.lock, size: 80, color: paid ? Colors.green : Colors.red),
        Text(paid ? "परीक्षा अनलॉक है!" : "परीक्षा लॉक है", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        if (!paid) ...[
          const Text("₹50 फीस न देने पर परीक्षा में बैठने नहीं दिया जाएगा।", textAlign: TextAlign.center),
          const SizedBox(height: 20),
          Image.network('https://api.qrserver.com/v1/create-qr-code/?size=120x120&data=upi://pay?pa=sonwaniv842@okaxis', height: 120),
        ]
      ]),
    ));
  }
}

// --- 3. ADMIN PANEL ---
class AdminPage extends StatefulWidget { const AdminPage({super.key}); @override State<AdminPage> createState() => _AdminPageState(); }
class _AdminPageState extends State<AdminPage> {
  List users = [];
  @override void initState() { super.initState(); _fetch(); }
  _fetch() async { final d = await supabase.from('profiles').select(); setState(() => users = d); }
  _toggle(String id, bool s) async { await supabase.from('profiles').update({'has_paid': !s}).eq('id', id); _fetch(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text("Admin Panel")), body: ListView.builder(itemCount: users.length, itemBuilder: (c, i) => Card(
      child: ListTile(
        title: Text(users[i]['full_name'] ?? 'User'),
        subtitle: Text("Parent: ${users[i]['parent_name'] ?? 'N/A'}"),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(icon: const Icon(Icons.call, color: Colors.green), onPressed: () => launchUrl(Uri.parse("tel:${users[i]['parent_phone']}"))),
          Switch(value: users[i]['has_paid'] ?? false, onChanged: (v) => _toggle(users[i]['id'], users[i]['has_paid'] ?? false)),
        ]),
      ),
    )));
  }
}
