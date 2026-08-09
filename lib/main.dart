import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:async';

// --- SUPABASE & GEMINI CONFIG ---
const supabaseUrl = 'https://tyonurrbwdjqfrmqrgpk.supabase.co';

// आपकी असली Supabase Anon Key यहाँ लगा दी गई है
const supabaseAnonKey = 'EyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR5b251cnJid2RqcWZybXFyZ3BrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODYxNzMzODMsImV4cCI6MjEwMTc0OTM4M30.95tDST7gwxemb2w2SS71arWh77omlFf0ezPwkTun2cM';

const geminiKey = 'YOUR_GEMINI_API_KEY';

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
        primaryColor: const Color(0xFF6C63FF),
        scaffoldBackgroundColor: const Color(0xFF0D0F1F),
        cardTheme: CardTheme(color: const Color(0xFF1A1C2E), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
      ),
      home: supabase.auth.currentSession == null ? const AuthGate() : const MainLMS(),
    );
  }
}

// --- 1. AUTH & LANGUAGE SELECTION ---
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
  String selectedGrade = "KG-1";
  String selectedLang = "Hindi";

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
            'grade': selectedGrade, 
            'language': selectedLang,
            'role': 'student'
          });
        }
      }
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const MainLMS()));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            const SizedBox(height: 60),
            const Text("🤖", style: TextStyle(fontSize: 80)),
            const Text("Padh-Ai Login", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Color(0xFF6C63FF))),
            const SizedBox(height: 30),
            if (!isLogin) ...[
              TextField(controller: nameC, decoration: const InputDecoration(labelText: "पूरा नाम", border: OutlineInputBorder())),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("भाषा: "),
                  Radio(value: "Hindi", groupValue: selectedLang, onChanged: (v)=>setState(()=>selectedLang=v!)), const Text("Hindi"),
                  Radio(value: "English", groupValue: selectedLang, onChanged: (v)=>setState(()=>selectedLang=v!)), const Text("English"),
                ],
              ),
            ],
            TextField(controller: emailC, decoration: const InputDecoration(labelText: "ईमेल आईडी", border: OutlineInputBorder())),
            const SizedBox(height: 15),
            TextField(controller: pinC, obscureText: true, decoration: const InputDecoration(labelText: "पिन / पासवर्ड", border: OutlineInputBorder())),
            const SizedBox(height: 30),
            ElevatedButton(onPressed: _handleAuth, style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 55)), child: Text(isLogin ? "Login" : "Register")),
            TextButton(onPressed: () => setState(() => isLogin = !isLogin), child: Text(isLogin ? "New Account" : "Back to Login")),
          ],
        ),
      ),
    );
  }
}

// --- 2. MAIN LMS & HELPLINE ---
class MainLMS extends StatefulWidget {
  const MainLMS({super.key});
  @override
  State<MainLMS> createState() => _MainLMSState();
}

class _MainLMSState extends State<MainLMS> {
  Map<String, dynamic>? user;
  int _tabIndex = 0;

  @override
  void initState() { super.initState(); _loadUser(); }
  _loadUser() async {
    final u = await supabase.from('profiles').select().eq('id', supabase.auth.currentUser!.id).single();
    setState(() => user = u);
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final screens = [
      _buildHome(),
      const HelplineScreen(), // AI & Admin Helpline
      if (user!['role'] == 'admin') const AdminApprovalPanel(),
    ];

    return Scaffold(
      appBar: AppBar(title: Text("Padh-Ai: ${user!['grade']}")),
      body: screens[_tabIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: (i) => setState(() => _tabIndex = i),
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.school), label: "Learn"),
          const BottomNavigationBarItem(icon: Icon(Icons.support_agent), label: "Helpline"),
          if (user!['role'] == 'admin') const BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: "Admin"),
        ],
      ),
    );
  }

  Widget _buildHome() {
    bool isPaid = user!['has_paid'] ?? false;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildHero(),
        const SizedBox(height: 20),
        if (!isPaid) _buildPaymentPrompt(),
        if (isPaid) const Card(child: ListTile(leading: Icon(Icons.check_circle, color: Colors.green), title: Text("एग्जाम अनलॉक है!"))),
        const SizedBox(height: 20),
        _buildGradeContent(),
      ],
    );
  }

  Widget _buildHero() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF3B3399)]), borderRadius: BorderRadius.circular(20)),
      child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("नमस्ते स्टूडेंट!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        Text("हमारा लक्ष्य: आपकी शिक्षा, आपका भविष्य।", style: TextStyle(color: Colors.white70)),
      ]),
    );
  }

  Widget _buildPaymentPrompt() {
    return Card(
      color: Colors.red.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          const Text("एग्जाम फीस: ₹50", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const Text("फीस भरें और स्क्रीनशॉट हेल्पलाइन पर भेजें।", textAlign: TextAlign.center),
          const SizedBox(height: 15),
          Image.network('https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=upi://pay?pa=admin@upi', height: 120),
          const SizedBox(height: 15),
          ElevatedButton(onPressed: () => setState(() => _tabIndex = 1), child: const Text("स्क्रीनशॉट भेजें")),
        ]),
      ),
    );
  }

  Widget _buildGradeContent() {
    return const ListTile(title: Text("पढ़ाई शुरू करें..."), leading: Icon(Icons.play_circle_fill));
  }
}

// --- 3. HELPLINE WITH SMART AI REPLY ---
class HelplineScreen extends StatefulWidget {
  const HelplineScreen({super.key});
  @override
  State<HelplineScreen> createState() => _HelplineScreenState();
}

class _HelplineScreenState extends State<HelplineScreen> {
  final _msgController = TextEditingController();
  final List<Map<String, String>> _chats = [];
  bool _isAIThinking = false;

  _sendMsg() async {
    if (_msgController.text.isEmpty) return;
    String userMsg = _msgController.text;
    setState(() { _chats.add({"role": "user", "text": userMsg}); _isAIThinking = true; });
    _msgController.clear();

    try {
      final model = GenerativeModel(model: 'gemini-pro', apiKey: geminiKey);
      final prompt = "तुम Padh-Ai के एडमिन हो। बच्चा परेशान है। उसे बहुत प्यार से जवाब दो कि एडमिन जल्द ही स्क्रीनशॉट चेक करके एग्जाम अनलॉक कर देंगे। जवाब छात्र की भाषा में दो। संदेश: $userMsg";
      final response = await model.generateContent([Content.text(prompt)]);
      setState(() { _chats.add({"role": "ai", "text": response.text ?? "ठीक है, हम देख रहे हैं।"}); _isAIThinking = false; });
    } catch (e) {
      setState(() => _isAIThinking = false);
    }
  }

  _pickScreenshot() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("स्क्रीनशॉट भेजा गया! एडमिन जल्द ही अप्रूव करेंगे।")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: ListView.builder(itemCount: _chats.length, itemBuilder: (c, i) => _buildChatBubble(_chats[i]))),
        if (_isAIThinking) const LinearProgressIndicator(),
        Padding(
          padding: const EdgeInsets.all(10),
          child: Row(children: [
            IconButton(icon: const Icon(Icons.add_a_photo), onPressed: _pickScreenshot),
            Expanded(child: TextField(controller: _msgController, decoration: const InputDecoration(hintText: "यहाँ लिखें..."))),
            IconButton(icon: const Icon(Icons.send), onPressed: _sendMsg),
          ]),
        )
      ],
    );
  }

  Widget _buildChatBubble(Map<String, String> chat) {
    bool isAI = chat['role'] == 'ai';
    return Align(
      alignment: isAI ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.all(8), padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: isAI ? Colors.white10 : Colors.deepPurple, borderRadius: BorderRadius.circular(15)),
        child: Text(chat['text']!, style: const TextStyle(fontSize: 14)),
      ),
    );
  }
}

// --- 4. ADMIN APPROVAL PANEL ---
class AdminApprovalPanel extends StatelessWidget {
  const AdminApprovalPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text("एडमिन: पेमेंट अप्रूवल", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const Divider(),
        Card(
          child: ListTile(
            title: const Text("छात्र: राहुल कुमार"),
            subtitle: const Text("WhatsApp: 9876543210"),
            trailing: ElevatedButton(onPressed: () {}, child: const Text("Approve")),
            onTap: () {},
          ),
        ),
      ],
    );
  }
}
