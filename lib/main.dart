import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

// --- CONFIGURATION ---
const String supabaseUrl = 'https://tyonurrbwdjqfrmqrgpk.supabase.co';
const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR5b251cnJid2RqcWZybXFyZ3BrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODYxNzMzODMsImV4cCI6MjEwMTc0OTM4M30.95tDST7gwxemb2w2SS71arWh77omlFf0ezPwkTun2cM';
const String geminiApiKey = 'AQ.Ab8RN6Jncjc5ohHgdhh4-0hKsT21_SXalluvdSsQArNjy90xOQ';
const String superAdminEmail = 'sonwaniv842@gmail.com';

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
      title: 'Padh-Ai',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF00E5FF),
        scaffoldBackgroundColor: const Color(0xFF0D0F1A),
        fontFamily: 'Inter',
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E5FF),
          secondary: Color(0xFF00E5FF),
          surface: Color(0xFF161A26),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00E5FF),
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

// --- 1. AUTH GATE ---
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (supabase.auth.currentSession != null) {
          return const LMSWrapper();
        }
        return const AuthScreen();
      },
    );
  }
}

// --- 2. AUTHENTICATION SCREEN ---
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  bool _loading = false;
  final _email = TextEditingController();
  final _pin = TextEditingController();
  final _name = TextEditingController();
  String _selectedGrade = "KG1-KG4";

  Future<void> _handleAuth() async {
    setState(() => _loading = true);
    try {
      if (_isLogin) {
        await supabase.auth.signInWithPassword(email: _email.text.trim(), password: _pin.text.trim());
      } else {
        final res = await supabase.auth.signUp(email: _email.text.trim(), password: _pin.text.trim());
        if (res.user != null) {
          final bool isAdmin = _email.text.trim() == superAdminEmail;
          await supabase.from('profiles').upsert({
            'id': res.user!.id,
            'full_name': _name.text.trim(),
            'grade': _selectedGrade,
            'role': isAdmin ? 'admin' : 'student',
            'has_paid': isAdmin,
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            children: [
              const Text("🤖", style: TextStyle(fontSize: 80)),
              const Text("Padh-Ai", style: TextStyle(fontSize: 38, fontWeight: FontWeight.w900, color: Color(0xFF00E5FF))),
              const SizedBox(height: 40),
              if (!_isLogin) ...[
                TextField(controller: _name, decoration: const InputDecoration(labelText: "Student Name", border: OutlineInputBorder())),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: _selectedGrade,
                  items: ["KG1-KG4", "1-5", "9-12"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setState(() => _selectedGrade = v!),
                  decoration: const InputDecoration(labelText: "Select Class", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 15),
              ],
              TextField(controller: _email, decoration: const InputDecoration(labelText: "Email ID", border: OutlineInputBorder())),
              const SizedBox(height: 15),
              TextField(controller: _pin, obscureText: true, decoration: const InputDecoration(labelText: "6-Digit PIN", border: OutlineInputBorder())),
              const SizedBox(height: 30),
              _loading 
                ? const CircularProgressIndicator()
                : SizedBox(width: double.infinity, height: 55, child: ElevatedButton(onPressed: _handleAuth, child: Text(_isLogin ? "LOGIN" : "REGISTER"))),
              TextButton(onPressed: () => setState(() => _isLogin = !_isLogin), child: Text(_isLogin ? "New Student? Join Now" : "Already a member? Login")),
            ],
          ),
        ),
      ),
    );
  }
}

// --- 3. LMS WRAPPER (MAIN APP NAVIGATION) ---
class LMSWrapper extends StatefulWidget {
  const LMSWrapper({super.key});
  @override
  State<LMSWrapper> createState() => _LMSWrapperState();
}

class _LMSWrapperState extends State<LMSWrapper> {
  int _idx = 0;
  Map<String, dynamic>? _profile;
  bool _studyLockActive = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  _fetch() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      final u = await supabase.from('profiles').select().eq('id', user.id).maybeSingle();
      if (mounted) {
        setState(() => _profile = u);
      }
    }
  }

  void _toggleStudyLock() {
    if (_studyLockActive) {
      _showPinDialog();
    } else {
      setState(() => _studyLockActive = true);
    }
  }

  void _showPinDialog() {
    final pc = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        title: const Text("Parental PIN Required"),
        content: TextField(controller: pc, obscureText: true, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: "Enter 6-digit PIN")),
        actions: [
          TextButton(onPressed: () {
            if (pc.text.isNotEmpty) {
               setState(() => _studyLockActive = false);
               Navigator.pop(c);
            }
          }, child: const Text("UNLOCK"))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_profile == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final bool isPaid = _profile!['has_paid'] ?? false;
    final bool isAdmin = _profile!['role'] == 'admin';

    final List<Widget> tabs = [
      isPaid ? HomeLearnTab(profile: _profile!) : PaymentLockTab(profile: _profile!),
      AIChatTab(profile: _profile!),
      const ScannerTab(),
      if (isAdmin) const AdminDashboardTab(),
    ];

    return WillPopScope(
      onWillPop: () async => !_studyLockActive,
      child: Scaffold(
        appBar: AppBar(
          title: Text("PADH-AI (${_profile!['grade'] ?? 'KG1-KG4'})", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF00E5FF))),
          actions: [
            IconButton(icon: Icon(_studyLockActive ? Icons.lock : Icons.lock_open, color: Colors.orange), onPressed: _toggleStudyLock),
            IconButton(icon: const Icon(Icons.logout), onPressed: () => supabase.auth.signOut())
          ],
        ),
        body: tabs[_idx],
        bottomNavigationBar: _studyLockActive ? null : BottomNavigationBar(
          currentIndex: _idx,
          onTap: (i) => setState(() => _idx = i),
          selectedItemColor: const Color(0xFF00E5FF),
          unselectedItemColor: Colors.white54,
          type: BottomNavigationBarType.fixed,
          items: [
            const BottomNavigationBarItem(icon: Icon(Icons.school), label: "Learn"),
            const BottomNavigationBarItem(icon: Icon(Icons.chat), label: "AI Teacher"),
            const BottomNavigationBarItem(icon: Icon(Icons.camera_alt), label: "Scanner"),
            if (isAdmin) const BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: "Admin"),
          ],
        ),
      ),
    );
  }
}

// --- 4. PAYMENT LOCK SCREEN ---
class PaymentLockTab extends StatefulWidget {
  final Map<String, dynamic> profile;
  const PaymentLockTab({super.key, required this.profile});
  @override
  State<PaymentLockTab> createState() => _PaymentLockTabState();
}

class _PaymentLockTabState extends State<PaymentLockTab> {
  final _phone = TextEditingController();
  XFile? _shot;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(25),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.cyan.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF00E5FF))),
            child: const Column(
              children: [
                Text("📢 ज़रूरी सूचना", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF00E5FF))),
                SizedBox(height: 10),
                Text("₹50 की परीक्षा फीस आपसे नहीं ली जा रही है, यह पैसा आपको गिफ्ट के रूप में वापस मिलेगा! फ्लिपकार्ट गिफ्ट वाउचर आपके दिए गए नंबर पर भेज दिया जाएगा।", textAlign: TextAlign.center, style: TextStyle(fontSize: 14, height: 1.4)),
              ],
            ),
          ),
          const SizedBox(height: 30),
          const Text("Step 1: Scan & Pay ₹50", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 15),
          Image.network("https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=upi://pay?pa=sonwaniv842@okaxis&pn=PadhAI&am=50"),
          const SizedBox(height: 30),
          TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "WhatsApp Number for Gift Delivery", border: OutlineInputBorder())),
          const SizedBox(height: 15),
          ElevatedButton.icon(
            onPressed: () async => _shot = await ImagePicker().pickImage(source: ImageSource.gallery),
            icon: const Icon(Icons.upload_file),
            label: Text(_shot == null ? "Upload Payment Screenshot" : "Screenshot Selected ✅"),
          ),
          const SizedBox(height: 25),
          SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: () async {
            if (_phone.text.isNotEmpty) {
               await supabase.from('profiles').update({'whatsapp': _phone.text.trim(), 'role': 'pending_approval'}).eq('id', widget.profile['id']);
               if (mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Request Sent! Admin will approve shortly.")));
               }
            } else {
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter active WhatsApp number!")));
            }
          }, child: const Text("SUBMIT FOR UNLOCK"))),
        ],
      ),
    );
  }
}

// --- 5. LEARNING TAB (CLASS BASED) ---
class HomeLearnTab extends StatelessWidget {
  final Map<String, dynamic> profile;
  const HomeLearnTab({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final grade = profile['grade'] ?? "KG1-KG4";
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _HeaderCard(name: profile['full_name'] ?? "Student"),
        const SizedBox(height: 20),
        if (grade == "KG1-KG4") ..._buildKG(),
        if (grade == "1-5") ..._buildPrimary(),
        if (grade == "9-12") ..._buildSenior(),
      ],
    );
  }

  List<Widget> _buildKG() {
    return [
      const _LearnCard(title: "A to Z Phonics", icon: "🍎", items: ["A for Apple", "B for Ball", "C for Cat", "D for Dog"]),
      const _LearnCard(title: "1-100 Counting", icon: "🔢", items: ["1 One", "2 Two", "3 Three", "4 Four", "5 Five"]),
      const _LearnCard(title: "Hindi Varnamala", icon: "🕉️", items: ["अ से अनार", "आ से आम", "क से कबूतर", "ख से खरगोश"]),
    ];
  }

  List<Widget> _buildPrimary() => [
    const _LearnCard(title: "Mathematics Basic", icon: "➕", items: ["Addition Simple", "Subtraction Simple", "Multiplication Tables"]),
    const _LearnCard(title: "Science & Nature", icon: "🌱", items: ["Parts of Plants", "Animals & Homes", "Our Solar System"])
  ];

  List<Widget> _buildSenior() => [
    const _LearnCard(title: "Physics Fundamentals", icon: "⚛️", items: ["Newton's Laws of Motion", "Quantum Mechanics Basics", "Atomic Structure"]),
    const _LearnCard(title: "Advanced Mathematics", icon: "📐", items: ["Calculus Principles", "Trigonometry Basics", "Coordinate Geometry"])
  ];
}

class _LearnCard extends StatelessWidget {
  final String title, icon; final List<String> items;
  const _LearnCard({required this.title, required this.icon, required this.items});
  
  @override
  Widget build(BuildContext context) {
    final tts = FlutterTts();
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ExpansionTile(
        leading: Text(icon, style: const TextStyle(fontSize: 25)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        children: items.map((i) => ListTile(
          title: Text(i),
          trailing: const Icon(Icons.volume_up, color: Color(0xFF00E5FF)),
          onTap: () async {
            await tts.setLanguage("hi-IN");
            await tts.speak(i);
          },
        )).toList(),
      ),
    );
  }
}

// --- 6. AI TEACHER CHAT TAB ---
class AIChatTab extends StatefulWidget {
  final Map<String, dynamic> profile;
  const AIChatTab({super.key, required this.profile});
  @override
  State<AIChatTab> createState() => _AIChatTabState();
}

class _AIChatTabState extends State<AIChatTab> {
  final List<Map<String, String>> _msgs = [];
  final _controller = TextEditingController();
  final _tts = FlutterTts();
  bool _typing = false;

  Future<void> _chat() async {
    final txt = _controller.text.trim();
    if (txt.isEmpty) return;
    _controller.clear();
    setState(() { _msgs.add({"r": "u", "t": txt}); _typing = true; });

    try {
      final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: geminiApiKey);
      final response = await model.generateContent([Content.text("Student Name: ${widget.profile['full_name']}. Grade: ${widget.profile['grade']}. Answer as a polite AI Teacher in Hindi/English mix: $txt")]);
      final reply = response.text ?? "उत्तर तैयार करने में त्रुटि हुई।";
      setState(() { _msgs.add({"r": "a", "t": reply}); _typing = false; });
      await _tts.setLanguage("hi-IN");
      await _tts.speak(reply);
    } catch (e) {
      setState(() {
        _msgs.add({"r": "a", "t": "नमस्ते! अभी गुरुजी व्यस्त हैं, लेकिन मैं आपकी पूरी मदद करूँगा।"});
        _typing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: ListView.builder(itemCount: _msgs.length, itemBuilder: (c, i) => _Bubble(msg: _msgs[i]))),
        if (_typing) const LinearProgressIndicator(),
        Padding(padding: const EdgeInsets.all(12), child: Row(children: [
          Expanded(child: TextField(controller: _controller, decoration: const InputDecoration(hintText: "Ask your Guru...", border: OutlineInputBorder()))),
          const SizedBox(width: 8),
          IconButton(icon: const Icon(Icons.send, color: Color(0xFF00E5FF)), onPressed: _chat)
        ])),
      ],
    );
  }
}

// --- 7. CAMERA SCANNER TAB ---
class ScannerTab extends StatefulWidget {
  const ScannerTab({super.key});
  @override
  State<ScannerTab> createState() => _ScannerTabState();
}

class _ScannerTabState extends State<ScannerTab> {
  bool _busy = false; String _res = "Scan a question to get instant help!";

  _scan() async {
    final img = await ImagePicker().pickImage(source: ImageSource.camera);
    if (img == null) return;
    setState(() => _busy = true);

    try {
      final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: geminiApiKey);
      final bytes = await img.readAsBytes();
      final content = [Content.multi([TextPart("Solve this EdTech study question completely step-by-step:"), DataPart('image/jpeg', bytes)])];
      final response = await model.generateContent(content);
      setState(() { _res = response.text ?? "No solution found"; _busy = false; });
      FlutterTts().setLanguage("hi-IN");
      FlutterTts().speak(_res);
    } catch (e) {
      setState(() { _res = "स्कैन करने में समस्या आई। कृपया पुनः प्रयास करें।"; _busy = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_busy) const CircularProgressIndicator() else const Icon(Icons.document_scanner, size: 100, color: Color(0xFF00E5FF)),
            const SizedBox(height: 20),
            Text(_res, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 30),
            FloatingActionButton.extended(onPressed: _scan, label: const Text("SCAN QUESTION"), icon: const Icon(Icons.camera_alt)),
          ],
        ),
      ),
    );
  }
}

// --- 8. ADMIN DASHBOARD TAB ---
class AdminDashboardTab extends StatefulWidget {
  const AdminDashboardTab({super.key});
  @override
  State<AdminDashboardTab> createState() => _AdminDashboardTabState();
}

class _AdminDashboardTabState extends State<AdminDashboardTab> {
  List _students = [];

  @override
  void initState() { super.initState(); _load(); }
  _load() async {
    final data = await supabase.from('profiles').select().neq('role', 'admin');
    setState(() => _students = data);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text("Master Admin Control", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF00E5FF))),
        const SizedBox(height: 20),
        _StatCard(title: "Total Registered Students", value: "${_students.length}"),
        const SizedBox(height: 20),
        const Text("Student Payment Approvals", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 10),
        ..._students.map((s) => Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            title: Text(s['full_name'] ?? 'Unknown Student'),
            subtitle: Text("Grade: ${s['grade']} | WhatsApp: ${s['whatsapp'] ?? 'N/A'}"),
            trailing: Switch(
              value: s['has_paid'] ?? false,
              activeColor: const Color(0xFF00E5FF),
              onChanged: (v) async {
                await supabase.from('profiles').update({'has_paid': v}).eq('id', s['id']);
                _load();
              },
            ),
          ),
        )).toList(),
      ],
    );
  }
}

// --- HELPER COMPONENTS ---
class _HeaderCard extends StatelessWidget {
  final String name; const _HeaderCard({required this.name});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: const LinearGradient(colors: [Color(0xFF00E5FF), Color(0xFF00B0FF)])),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text("नमस्ते,", style: TextStyle(color: Colors.black54, fontSize: 16)),
        Text(name, style: const TextStyle(color: Colors.black, fontSize: 28, fontWeight: FontWeight.bold)),
      ]),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title, value; const _StatCard({required this.title, required this.value});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white24)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(title), Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00E5FF), fontSize: 18))]),
    );
  }
}

class _Bubble extends StatelessWidget {
  final Map<String, String> msg; const _Bubble({required this.msg});
  @override
  Widget build(BuildContext context) {
    bool isA = msg['r'] == 'a';
    return Align(
      alignment: isA ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.all(10), padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: isA ? Colors.white10 : const Color(0xFF00E5FF), borderRadius: BorderRadius.circular(15)),
        child: Text(msg['t']!, style: TextStyle(color: isA ? Colors.white : Colors.black, fontSize: 15)),
      ),
    );
  }
}
