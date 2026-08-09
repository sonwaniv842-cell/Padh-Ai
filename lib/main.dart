import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_tts/flutter_tts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // सुपबेस इनिशियलाइज़ (क्रैश रोकने के लिए try-catch)
  try {
    await Supabase.initialize(
      url: 'https://tyonurrbwdjqfrmqrgpk.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR5b251cnJid2RqcWZybXFyZ3BrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODYxNzMzODMsImV4cCI6MjEwMTc0OTM4M30.95tDST7gwxemb2w2SS71arWh77omlFf0ezPwkTun2cM',
    );
  } catch (e) {
    debugPrint("Connection Error: $e");
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
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF3E8FF), // लाइट पर्पल थीम
        primaryColor: const Color(0xFF8B5CF6),
      ),
      home: const WorkingHomeScreen(),
    );
  }
}

class WorkingHomeScreen extends StatefulWidget {
  const WorkingHomeScreen({super.key});

  @override
  State<WorkingHomeScreen> createState() => _WorkingHomeScreenState();
}

class _WorkingHomeScreenState extends State<WorkingHomeScreen> {
  final FlutterTts flutterTts = FlutterTts();
  final GlobalKey<ScaffoldState> _key = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _setupSpeaker();
  }

  // आवाज़ (Speaker) सेटअप
  void _setupSpeaker() async {
    await flutterTts.setLanguage("hi-IN"); // हिंदी भाषा सेट करें
    await flutterTts.setPitch(1.0);
    await flutterTts.setVolume(1.0);
    await flutterTts.setSpeechRate(0.5); // बोलने की रफ़्तार (धीरे और साफ़)
  }

  // फंक्शन: आवाज़ बोलने के लिए
  Future<void> _speakText(String text) async {
    if (text.isNotEmpty) {
      await flutterTts.speak(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _key,
      drawer: _buildSideMenu(), // तीन लाइन वाला मेनू बटन
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black, size: 30),
          onPressed: () => _key.currentState?.openDrawer(),
        ),
        title: Row(
          children: [
            Image.asset(
              'assets/padh-ai-logo.png',
              height: 35,
              errorBuilder: (context, error, stackTrace) => 
                  const Icon(Icons.smart_toy, color: Colors.indigo), // फोटो न होने पर रोबोट दिखेगा
            ),
            const SizedBox(width: 10),
            const Text("Padh AI", style: TextStyle(color: Color(0xFF8B5CF6), fontWeight: FontWeight.w900)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildIndiaBadge(),
            const SizedBox(height: 25),
            _buildHeroText(),
            const SizedBox(height: 35),
            
            // --- किताब स्कैन बटन (विद आवाज़) ---
            _buildMainActionButton(
              "📸 किताब स्कैन करें", 
              const Color(0xFF8B5CF6), 
              Colors.white, 
              () {
                _speakText("कृपया अपनी किताब की फोटो लें, मैं उसे पढ़कर सुनाता हूँ।");
              }
            ),
            
            const SizedBox(height: 15),

            // --- ए आई टीचर बटन (विद आवाज़) ---
            _buildMainActionButton(
              "🗣️ AI Teacher से बात करें", 
              Colors.white, 
              Colors.black, 
              () {
                _speakText("नमस्ते! मैं आपका ए आई टीचर हूँ। आज आप क्या पढ़ना चाहेंगे?");
              }
            ),

            const SizedBox(height: 40),
            _buildPremiumScoreCard(), // 98/100 वाला प्रीमियम कार्ड
            
            const SizedBox(height: 30),

            // --- बड़ा पीला बटन (आज का पाठ) ---
            _buildYellowLessonButton(),
            
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  // --- UI बनाने के छोटे हिस्से (Widgets) ---

  Widget _buildSideMenu() {
    return Drawer(
      child: ListView(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFF8B5CF6)),
            child: Center(child: Text("Padh AI", style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold))),
          ),
          ListTile(leading: const Icon(Icons.home), title: const Text("Home"), onTap: () => Navigator.pop(context)),
          ListTile(leading: const Icon(Icons.settings), title: const Text("Settings"), onTap: () {}),
        ],
      ),
    );
  }

  Widget _buildIndiaBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.grey.shade200)),
      child: const Text("✨ India का बच्चों वाला AI Teacher", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }

  Widget _buildHeroText() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        "पढ़ाई अब मज़ेदार — अपने AI Teacher से सीखो",
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Color(0xFF1F2937), height: 1.2),
      ),
    );
  }

  Widget _buildMainActionButton(String title, Color bg, Color txt, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        height: 60,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: bg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.purple.shade100)),
            elevation: 2,
          ),
          onPressed: onTap,
          child: Text(title, style: TextStyle(color: txt, fontWeight: FontWeight.bold, fontSize: 17)),
        ),
      ),
    );
  }

  Widget _buildPremiumScoreCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("AI Evaluation", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              Text("98/100 स्कोर", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              const SizedBox(width: 65, height: 65, child: CircularProgressIndicator(value: 0.98, strokeWidth: 7, color: Colors.green, backgroundColor: Color(0xFFF1F5F9))),
              const Text("98", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 20)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildYellowLessonButton() {
    return GestureDetector(
      onTap: () => _speakText("शानदार! आज का नया पाठ शुरू हो गया है। ध्यान से सुनें।"),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.amber, 
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        child: const Center(child: Text("🌟 आज का पाठ शुरू करें", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white))),
      ),
    );
  }
}
