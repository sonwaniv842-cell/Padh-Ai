import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:async';

// --- CONFIG ---
const supabaseUrl = 'https://tyonurrbwdjqfrmqrgpk.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR5b251cnJid2RqcWZybXFyZ3BrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODYxNzMzODMsImV4cCI6MjEwMTc0OTM4M30.95tDST7gwxemb2w2SS71arWh77omlFf0ezPwkTun2cM';

// 🔑 आपकी Gemini API Key यहाँ अटैच कर दी गई है
const geminiKey = 'AQ.Ab8RN6Jncjc5OhHgdhh4-0hKsT21_SXalluvdSsQArNjy90xOQ'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  runApp(const PadhAIProApp());
}

final supabase = Supabase.instance.client;

class PadhAIProApp extends StatelessWidget {
  const PadhAIProApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF00E5FF),
        scaffoldBackgroundColor: const Color(0xFF0A0E21),
        fontFamily: 'Inter',
        cardTheme: CardTheme(
          color: const Color(0xFF1D1B2E), 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
        ),
      ),
      home: supabase.auth.currentSession == null ? const AuthScreen() : const MainLMS(),
    );
  }
}

// --- 1. AUTH SCREEN ---
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  final emailC = TextEditingController();
  final pinC = TextEditingController();
  final nameC = TextEditingController();

  Future<void> _handleAuth() async {
    try {
      if (isLogin) {
        await supabase.auth.signInWithPassword(email: emailC.text, password: pinC.text);
      } else {
        final res = await supabase.auth.signUp(email: emailC.text, password: pinC.text);
        if (res.user != null) {
          await supabase.from('profiles').upsert({
            'id': res.user!.id,
            'full_name': nameC.text,
            'role': 'student',
            'is_active': true,
          });
        }
      }
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const MainLMS()));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
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
              const Text("Padh-Ai", style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold, color: Color(0xFF00E5FF))),
              const SizedBox(height: 40),
              if (!isLogin) ...[
                TextField(controller: nameC, decoration: const InputDecoration(labelText: "छात्र का पूरा नाम", border: OutlineInputBorder())),
                const SizedBox(height: 15),
              ],
              TextField(controller: emailC, decoration: const InputDecoration(labelText: "ईमेल आईडी", border: OutlineInputBorder())),
              const SizedBox(height: 15),
              TextField(controller: pinC, obscureText: true, decoration: const InputDecoration(labelText: "6-अंकों का पिन", border: OutlineInputBorder())),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _handleAuth, 
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 55)), 
                child: Text(isLogin ? "प्रवेश करें" : "रजिस्टर करें")
              ),
              TextButton(
                onPressed: () => setState(() => isLogin = !isLogin), 
                child: Text(isLogin ? "नया अकाउंट बनायें" : "लॉगिन करें")
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- 2. MAIN LMS DASHBOARD ---
class MainLMS extends StatefulWidget {
  const MainLMS({super.key});
  @override
  State<MainLMS> createState() => _MainLMSState();
}

class _MainLMSState extends State<MainLMS> {
  int _idx = 0;
  Map<String, dynamic>? profile;

  @override
  void initState() { 
    super.initState(); 
    _load(); 
  }

  _load() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      final u = await supabase.from('profiles').select().eq('id', user.id).single();
      setState(() => profile = u);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (profile == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final screens = [
      _buildHome(),
      AIChat(studentName: profile!['full_name'] ?? 'छात्र'),
      const Center(child: Text("रिजल्ट जल्द आएंगे!")),
      if (profile!['role'] == 'admin') const MasterAdmin(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text("नमस्ते ${profile!['full_name'] ?? 'छात्र'}!"), 
        actions: [
          IconButton(
            icon: const Icon(Icons.logout), 
            onPressed: () async {
              await supabase.auth.signOut();
              if (context.mounted) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const AuthScreen()));
              }
            }
          )
        ]
      ),
      body: screens[_idx],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _idx,
        onTap: (i) => setState(() => _idx = i),
        selectedItemColor: const Color(0xFF00E5FF),
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.school), label: "Learn"),
          const BottomNavigationBarItem(icon: Icon(Icons.chat), label: "AI Teacher"),
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
        const Card(child: Padding(padding: EdgeInsets.all(25), child: Column(children: [Text("📚 आज का पाठ", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), Text("चलो शुरू करते हैं!")] ))),
        const SizedBox(height: 20),
        _btn("🔢 1-100 गिनती (Auto)", () {}),
        _btn("🍎 वर्णमाला (Auto)", () {}),
        _btn("📖 मात्रा ज्ञान", () {}),
      ],
    );
  }
  Widget _btn(String t, VoidCallback tap) => Card(child: ListTile(title: Text(t), trailing: const Icon(Icons.play_circle), onTap: tap));
}

// --- 3. LIVE AI CHAT (With Personalized Encouragement) ---
class AIChat extends StatefulWidget {
  final String studentName;
  const AIChat({super.key, required this.studentName});
  @override
  State<AIChat> createState() => _AIChatState();
}

class _AIChatState extends State<AIChat> {
  final _msgC = TextEditingController();
  final List<Map<String, String>> _chats = [];
  final _tts = FlutterTts();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  void _initTts() async {
    await _tts.setLanguage("hi-IN");
    await _tts.setSpeechRate(0.5);
  }

  _send() async {
    String q = _msgC.text.trim();
    if (q.isEmpty || _isLoading) return;
    
    setState(() {
      _chats.add({"role": "user", "text": q});
      _isLoading = true;
    });
    _msgC.clear();

    try {
      // Gemini Model Setup
      final model = GenerativeModel(
        model: 'gemini-1.5-flash', 
        apiKey: geminiKey,
      );

      final prompt = "तुम Padh-Ai के एआई टीचर हो। छात्र का नाम ${widget.studentName} है। "
                     "हमेशा उसे नाम लेकर बुलाओ। उसे बहुत प्यार से जवाब दो और पढ़ाई के लिए प्रोत्साहित करो। "
                     "अगर वह अच्छा जवाब दे तो कहो: '${widget.studentName}, आप बहुत अच्छा कर रहे हैं!', "
                     "'लगता है आप फर्स्ट आएंगे और आपको इनाम मिलेगा!' "
                     "अंत में समय देने के लिए धन्यवाद कहो। छात्र का सवाल: $q";

      final res = await model.generateContent([Content.text(prompt)]);
      String responseText = res.text ?? "माफ़ करना, मैं अभी सुन नहीं पाया।";

      setState(() {
        _chats.add({"role": "ai", "text": responseText});
        _isLoading = false;
      });
      
      // AI की आवाज़ में उत्तर बोलें
      await _tts.speak(responseText);
    } catch (e) {
      setState(() {
        _chats.add({"role": "ai", "text": "माफ़ करना ${widget.studentName}, कुछ तकनीकी समस्या आई है।"});
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: _chats.length, 
            itemBuilder: (c, i) => ListTile(
              title: Align(
                alignment: _chats[i]['role'] == 'user' ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: _chats[i]['role'] == 'user' ? const Color(0xFF00E5FF).withOpacity(0.2) : const Color(0xFF1D1B2E), 
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.3))
                  ),
                  child: Text(_chats[i]['text']!, style: const TextStyle(fontSize: 16))
                ),
              ),
            )
          )
        ),
        if (_isLoading) const Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()),
        Padding(
          padding: const EdgeInsets.all(10), 
          child: Row(
            children: [
              Expanded(child: TextField(controller: _msgC, decoration: const InputDecoration(hintText: "पूछिए गुरुजी से...", border: OutlineInputBorder()))),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.send, color: Color(0xFF00E5FF)), 
                onPressed: _send
              )
            ]
          )
        )
      ],
    );
  }
}

// --- 4. ADMIN PANEL ---
class MasterAdmin extends StatelessWidget {
  const MasterAdmin({super.key});
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text("मास्टर कंट्रोल", style: TextStyle(fontSize: 22, color: Color(0xFF00E5FF))),
        const Divider(),
        ListTile(title: const Text("एग्जाम फीस सेट करें"), trailing: const Icon(Icons.edit)),
        ListTile(title: const Text("छात्रों की लिस्ट"), trailing: const Icon(Icons.people)),
      ],
    );
  }
}
