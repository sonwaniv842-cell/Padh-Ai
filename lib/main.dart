import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:async';

// --- CONFIG ---
const supabaseUrl = 'https://tyonurrbwdjqfrmqrgpk.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR5b251cnJid2RqcWZybXFyZ3BrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODYxNzMzODMsImV4cCI6MjEwMTc0OTM4M30.95tDST7gwxemb2w2SS71arWh77omlFf0ezPwkTun2cM';
const geminiKey = 'YOUR_GEMINI_KEY'; // यहाँ अपनी Key डालें

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
        primaryColor: const Color(0xFF00E5FF),
        scaffoldBackgroundColor: const Color(0xFF0A0E21),
        cardTheme: CardTheme(color: const Color(0xFF1D1B2E), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
      ),
      home: supabase.auth.currentSession == null ? const AuthGate() : const MainLMS(),
    );
  }
}

// --- 1. AUTH GATE (ERROR-FREE REGISTRATION) ---
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool isLogin = true;
  final emailC = TextEditingController();
  final pinC = TextEditingController();
  final nameC = TextEditingController();
  bool isLoading = false;

  Future<void> _handleAuth() async {
    if (emailC.text.isEmpty || pinC.text.length < 6) {
      _showMsg("ईमेल और 6-अंकों का पिन ज़रूरी है!");
      return;
    }
    setState(() => isLoading = true);
    try {
      if (isLogin) {
        await supabase.auth.signInWithPassword(email: emailC.text, password: pinC.text);
      } else {
        final res = await supabase.auth.signUp(email: emailC.text, password: pinC.text);
        if (res.user != null) {
          // यहाँ हम पक्का कर रहे हैं कि 'role' और 'full_name' डेटाबेस में जाए
          await supabase.from('profiles').upsert({
            'id': res.user!.id,
            'full_name': nameC.text.isEmpty ? "Student" : nameC.text,
            'role': 'student',
            'is_active': true,
          });
        }
      }
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const MainLMS()));
    } catch (e) {
      _showMsg("त्रुटि: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showMsg(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            children: [
              const Text("🤖", style: TextStyle(fontSize: 80)),
              const Text("Padh-Ai", style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold, color: Color(0xFF00E5FF))),
              const SizedBox(height: 40),
              if (!isLogin) TextField(controller: nameC, decoration: const InputDecoration(labelText: "छात्र का पूरा नाम", border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: emailC, decoration: const InputDecoration(labelText: "ईमेल आईडी", border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: pinC, obscureText: true, decoration: const InputDecoration(labelText: "6-अंकों का पिन", border: OutlineInputBorder())),
              const SizedBox(height: 30),
              isLoading ? const CircularProgressIndicator() : ElevatedButton(onPressed: _handleAuth, style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 55)), child: Text(isLogin ? "प्रवेश करें" : "रजिस्टर करें")),
              TextButton(onPressed: () => setState(() => isLogin = !isLogin), child: Text(isLogin ? "नया अकाउंट बनायें" : "पुराना अकाउंट लॉगिन करें")),
            ],
          ),
        ),
      ),
    );
  }
}

// --- 2. MAIN LMS (GRADES & STUDY) ---
class MainLMS extends StatefulWidget {
  const MainLMS({super.key});
  @override
  State<MainLMS> createState() => _MainLMSState();
}

class _MainLMSState extends State<MainLMS> {
  int _idx = 0;
  Map<String, dynamic>? profile;

  @override
  void initState() { super.initState(); _load(); }
  _load() async {
    try {
      final u = await supabase.from('profiles').select().eq('id', supabase.auth.currentUser!.id).single();
      setState(() => profile = u);
    } catch (e) {
      debugPrint("Profile load error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (profile == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final screens = [
      _buildHome(),
      AIChat(studentName: profile!['full_name'] ?? "Student"), 
      const Center(child: Text("Results Coming Soon!")),
      if (profile!['role'] == 'admin') const MasterAdmin(),
    ];

    return Scaffold(
      appBar: AppBar(title: Text("नमस्ते ${profile!['full_name']}!")),
      body: screens[_idx],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _idx, onTap: (i) => setState(() => _idx = i), selectedItemColor: const Color(0xFF00E5FF), type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.school), label: "Learn"),
          const BottomNavigationBarItem(icon: Icon(Icons.chat), label: "Teacher"),
          const BottomNavigationBarItem(icon: Icon(Icons.history), label: "Results"),
          if (profile!['role'] == 'admin') const BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: "Admin"),
        ],
      ),
    );
  }

  Widget _buildHome() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _btn("🔢 1-100 गिनती (Auto Play)", () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AutoStudy(type: 'गिनती')))),
        _btn("🍎 वर्णमाला ABCD (Auto Play)", () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AutoStudy(type: 'वर्णमाला')))),
        _btn("📖 मात्रा ज्ञान (क, का, कि, की...)", () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AutoStudy(type: 'मात्रा')))),
      ],
    );
  }
  Widget _btn(String t, VoidCallback tap) => Card(child: ListTile(title: Text(t), trailing: const Icon(Icons.play_circle_fill, color: Colors.greenAccent), onTap: tap));
}

// --- 3. SLOW AUTO STUDY MODULE ---
class AutoStudy extends StatefulWidget {
  final String type; const AutoStudy({super.key, required this.type});
  @override
  State<AutoStudy> createState() => _AutoStudyState();
}

class _AutoStudyState extends State<AutoStudy> {
  int cur = 1; bool isP = false; final _tts = FlutterTts();

  _play() async {
    await _tts.setLanguage("hi-IN");
    await _tts.setSpeechRate(0.3); // बहुत धीमा बच्चों के लिए
    while (isP && cur <= 100) {
      await _tts.speak(cur.toString());
      await Future.delayed(const Duration(seconds: 4));
      if (mounted) setState(() { if(cur < 100) cur++; else isP = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.type)),
      body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text("$cur", style: const TextStyle(fontSize: 150, fontWeight: FontWeight.bold, color: Color(0xFF00E5FF))),
        const SizedBox(height: 50),
        ElevatedButton(onPressed: () { setState(() => isP = !isP); if(isP) _play(); }, child: Text(isP ? "रोकें (STOP)" : "पढ़ना शुरू करें")),
      ])),
    );
  }
}

// --- 4. PERSONALIZED AI TEACHER (GEMINI) ---
class AIChat extends StatefulWidget {
  final String studentName; const AIChat({super.key, required this.studentName});
  @override
  State<AIChat> createState() => _AIChatState();
}

class _AIChatState extends State<AIChat> {
  final _msgC = TextEditingController(); final List<Map<String, String>> _chats = []; final _tts = FlutterTts();

  _send() async {
    String q = _msgC.text; if (q.isEmpty) return;
    setState(() => _chats.add({"r": "u", "m": q})); _msgC.clear();
    
    try {
      final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: geminiKey);
      final prompt = "तुम Padh-Ai के गुरु हो। छात्र का नाम ${widget.studentName} है। उसे नाम लेकर प्यार से बात करो, प्रोत्साहित करो कि वो इनाम जीतेगा। अंत में धन्यवाद कहो।";
      final res = await model.generateContent([Content.text("$prompt. सवाल: $q")]);
      String ans = res.text ?? "बेटा, मुझे फिर से पूछो।";
      setState(() => _chats.add({"r": "a", "m": ans}));
      await _tts.speak(ans);
    } catch (e) {
      debugPrint("AI Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Expanded(child: ListView.builder(itemCount: _chats.length, itemBuilder: (c, i) => ListTile(
        title: Text(_chats[i]['m']!), leading: Text(_chats[i]['r'] == 'u' ? "🧒" : "🤖"),
      ))),
      Padding(padding: const EdgeInsets.all(12), child: Row(children: [Expanded(child: TextField(controller: _msgC)), IconButton(icon: const Icon(Icons.send), onPressed: _send)]))
    ]);
  }
}

// --- 5. MASTER ADMIN PANEL ---
class MasterAdmin extends StatelessWidget {
  const MasterAdmin({super.key});
  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(20), children: [
      const Text("मास्टर एडमिन कंट्रोल", style: TextStyle(fontSize: 22, color: Color(0xFF00E5FF))),
      const Divider(),
      ListTile(title: const Text("एग्जाम फीस बदलें"), trailing: const Icon(Icons.edit)),
      ListTile(title: const Text("छात्रों की लिस्ट (Payment Approve)"), trailing: const Icon(Icons.check_circle_outline)),
    ]);
  }
}
