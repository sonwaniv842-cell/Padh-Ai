import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Supabase.initialize(
      url: 'https://tyonurrbwdjqfrmqrgpk.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR5b251cnJid2RqcWZybXFyZ3BrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODYxNzMzODMsImV4cCI6MjEwMTc0OTM4M30.95tDST7gwxemb2w2SS71arWh77omlFf0ezPwkTun2cM',
    );
  } catch (e) {
    debugPrint("Supabase Init Error: $e");
  }
  runApp(const PadhAIApp());
}

class PadhAIApp extends StatelessWidget {
  const PadhAIApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Padh AI',
      theme: ThemeData(scaffoldBackgroundColor: const Color(0xFFF3E8FF)),
      home: const AuthScreen(), // सबसे पहले लॉगिन खुलेगा
    );
  }
}

// --- 1. LOGIN / REGISTER SCREEN ---
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isAdmin = false;
  bool isRegister = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            children: [
              const Icon(Icons.face_retouching_natural_rounded, size: 80, color: Color(0xFF8B5CF6)),
              const SizedBox(height: 10),
              const Text("Padh AI", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF8B5CF6))),
              const SizedBox(height: 40),
              _buildInput("Email Address", Icons.email),
              const SizedBox(height: 15),
              _buildInput("Password", Icons.lock, obscure: true),
              const SizedBox(height: 30),
              
              // Login Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                  onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const StudentDashboard())),
                  child: Text(isRegister ? "REGISTER" : "LOGIN", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 20),
              
              TextButton(
                onPressed: () => setState(() => isRegister = !isRegister),
                child: Text(isRegister ? "Already have account? Login" : "New Student? Register Now", style: const TextStyle(color: Colors.black)),
              ),
              
              // Admin Toggle
              SwitchListTile(
                title: const Text("Admin Access?", style: TextStyle(fontSize: 14)),
                value: isAdmin, 
                onChanged: (v) => setState(() => isAdmin = v),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(String label, IconData icon, {bool obscure = false}) {
    return TextField(
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label, prefixIcon: Icon(icon, color: const Color(0xFF8B5CF6)),
        filled: true, fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }
}

// --- 2. MAIN DASHBOARD ---
class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});
  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final FlutterTts tts = FlutterTts();

  void _speak(String text) async {
    await tts.setLanguage("hi-IN");
    await tts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0, title: const Text("Padh AI Home", style: TextStyle(color: Color(0xFF8B5CF6), fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // वह शानदार हेडलाइन
            const Text("पढ़ाई अब मज़ेदार — AI से सीखो", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900), textAlign: TextAlign.center),
            const SizedBox(height: 30),
            
            // KG1 LEARNING BUTTON (नया मॉड्यूल)
            _moduleCard("🌟 KG1 Learning Module", "ABCD, पहाड़ा, गिनती", Colors.amber, () {
              _speak("चलिए बच्चों, आज कुछ नया सीखते हैं!");
              Navigator.push(context, MaterialPageRoute(builder: (context) => const KG1Module()));
            }),

            const SizedBox(height: 20),
            _moduleCard("📸 किताब स्कैन करें", "AI टीचर को फोटो दिखाएं", const Color(0xFF8B5CF6), () => _speak("कृपया फोटो लें")),
            
            const SizedBox(height: 30),
            // स्कोर कार्ड
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("AI Score", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)), Text("98/100", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))]),
                  Icon(Icons.stars, color: Colors.green, size: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _moduleCard(String title, String desc, Color color, VoidCallback fn) {
    return InkWell(
      onTap: fn,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
        child: Row(
          children: [
            const Icon(Icons.play_circle_fill, color: Colors.white, size: 40),
            const SizedBox(width: 15),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              Text(desc, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ])
          ],
        ),
      ),
    );
  }
}

// --- 3. KG1 LEARNING MODULE (Fun & Cartoon Style) ---
class KG1Module extends StatefulWidget {
  const KG1Module({super.key});
  @override
  State<KG1Module> createState() => _KG1ModuleState();
}

class _KG1ModuleState extends State<KG1Module> {
  bool isHindi = false;
  final FlutterTts tts = FlutterTts();

  void _speak(String t) async {
    await tts.setLanguage(isHindi ? "hi-IN" : "en-US");
    await tts.speak(t);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF8B5CF6),
          title: const Text("Digital KG1 School 🎒"),
          actions: [
            // भाषा बदलने का बटन
            TextButton(
              onPressed: () => setState(() => isHindi = !isHindi),
              child: Text(isHindi ? "English" : "हिंदी", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          ],
          bottom: const TabBar(
            tabs: [Tab(text: "ABCD"), Tab(text: "123"), Tab(text: "Pahada")],
            indicatorColor: Colors.white,
          ),
        ),
        body: TabBarView(
          children: [
            _buildAlphabetGrid(),
            _buildCountingGrid(),
            _buildPahadaModule(),
          ],
        ),
      ),
    );
  }

  // ABCD Module
  Widget _buildAlphabetGrid() {
    final list = isHindi ? ["क", "ख", "ग", "घ"] : ["A", "B", "C", "D"];
    final words = isHindi ? ["कबूतर", "खरगोश", "गमला", "घड़ी"] : ["Apple", "Ball", "Cat", "Dog"];
    final icons = ["🐦", "🐰", "🪴", "⌚", "🍎", "⚽", "🐱", "🐶"];

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15),
      itemCount: 4,
      itemBuilder: (c, i) => _cartoonCard(list[i], words[i], icons[i + (isHindi ? 0 : 4)], () => _speak("${list[i]} for ${words[i]}")),
    );
  }

  // Counting Module
  Widget _buildCountingGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10),
      itemCount: 9,
      itemBuilder: (c, i) => _cartoonCard("${i + 1}", "", "🌟", () => _speak("${i + 1}")),
    );
  }

  // Cartoon Pahada (Tables)
  Widget _buildPahadaModule() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 5,
      itemBuilder: (c, i) => Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.orange.shade100, width: 2)),
        child: ListTile(
          leading: const CircleAvatar(backgroundColor: Colors.orange, child: Icon(Icons.star, color: Colors.white)),
          title: Text("Table of ${i + 2}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          trailing: const Icon(Icons.volume_up, color: Colors.orange),
          onTap: () => _speak("Two times one is two, two times two is four"),
        ),
      ),
    );
  }

  Widget _cartoonCard(String title, String sub, String icon, VoidCallback fn) {
    return InkWell(
      onTap: fn,
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF8B5CF6))),
            if (sub.isNotEmpty) Text(sub, style: const TextStyle(fontSize: 14, color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}
