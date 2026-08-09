import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_tts/flutter_tts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Supabase.initialize(
      url: 'https://tyonurrbwdjqfrmqrgpk.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR5b251cnJid2RqcWZybXFyZ3BrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODYxNzMzODMsImV4cCI6MjEwMTc0OTM4M30.95tDST7gwxemb2w2SS71arWh77omlFf0ezPwkTun2cM',
    );
  } catch (e) {
    debugPrint("Supabase Load Error: $e");
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
      home: const SafeHomeScreen(),
    );
  }
}

class SafeHomeScreen extends StatefulWidget {
  const SafeHomeScreen({super.key});
  @override
  State<SafeHomeScreen> createState() => _SafeHomeScreenState();
}

class _SafeHomeScreenState extends State<SafeHomeScreen> {
  final FlutterTts flutterTts = FlutterTts();
  final GlobalKey<ScaffoldState> _key = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  void _initTts() async {
    await flutterTts.setLanguage("hi-IN");
  }

  Future<void> _speak(String text) async {
    await flutterTts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _key,
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
                decoration: BoxDecoration(color: Color(0xFF8B5CF6)),
                child: Center(child: Text("Padh AI Menu", style: TextStyle(color: Colors.white, fontSize: 24)))),
            ListTile(leading: const Icon(Icons.home), title: const Text("Home"), onTap: () => Navigator.pop(context)),
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black, size: 30),
          onPressed: () => _key.currentState?.openDrawer(),
        ),
        title: Row(
          children: [
            // यहाँ फोटो की जगह 'Icon' का उपयोग किया गया है ताकि Error न आए
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.smart_toy_rounded, color: Color(0xFF8B5CF6)),
            ),
            const SizedBox(width: 10),
            const Text("Padh AI", style: TextStyle(color: Color(0xFF8B5CF6), fontWeight: FontWeight.w900)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 30),
            _buildIndiaBadge(),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text("पढ़ाई अब मज़ेदार — अपने AI Teacher से सीखो",
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, height: 1.2)),
            ),
            const SizedBox(height: 35),
            _buildButton("📸 किताब स्कैन करें", const Color(0xFF8B5CF6), Colors.white, () => _speak("अपनी किताब की फोटो लें")),
            const SizedBox(height: 15),
            _buildButton("🗣️ AI Teacher से बात करें", Colors.white, Colors.black, () => _speak("नमस्ते! मैं आपका ए आई टीचर हूँ।")),
            const SizedBox(height: 40),
            _buildScoreCard(),
            const SizedBox(height: 30),
            _buildYellowButton(),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildIndiaBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.grey.shade300)),
      child: const Text("✨ India का बच्चों वाला AI Teacher", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _buildButton(String t, Color b, Color tx, VoidCallback fn) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        height: 60,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: b, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
          onPressed: fn,
          child: Text(t, style: TextStyle(color: tx, fontWeight: FontWeight.bold, fontSize: 18)),
        ),
      ),
    );
  }

  Widget _buildScoreCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25)),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("AI Evaluation", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            Text("स्कोर: 98/100", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ]),
          Icon(Icons.stars, color: Colors.green, size: 40),
        ],
      ),
    );
  }

  Widget _buildYellowButton() {
    return GestureDetector(
      onTap: () => _speak("आज का पाठ शुरू करते हैं।"),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(20)),
        child: const Center(child: Text("🌟 आज का पाठ शुरू करें", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white))),
      ),
    );
  }
}
