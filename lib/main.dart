import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:ui';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://tyonurrbwdjqfrmqrgpk.supabase.co',
    anonKey: 'YOUR_ANON_KEY', // अपनी चाबी यहाँ डालें
  );
  runApp(const PadhAIApp());
}

// --- बच्चों वाला फ्रेंडली थीम ---
class KidsTheme {
  static const Color bgPurple = Color(0xFFF3E8FF); // लाइट पर्पल बैकग्राउंड
  static const Color primaryPurple = Color(0xFF8B5CF6); // मुख्य पर्पल
  static const Color accentGreen = Color(0xFF10B981); // AI टीचर वाला हरा
  static const Color white = Colors.white;
  static const Color textDark = Color(0xFF1F2937);
}

class PadhAIApp extends StatelessWidget {
  const PadhAIApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Padh AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Inter', // मॉडर्न साफ़ फॉन्ट
        scaffoldBackgroundColor: KidsTheme.bgPurple,
      ),
      home: const DashboardScreen(),
    );
  }
}

// --- डैशबोर्ड स्क्रीन (वेबसाइट स्टाइल में) ---
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(backgroundColor: KidsTheme.primaryPurple.withOpacity(0.1), child: const Text("🤖")),
            const SizedBox(width: 10),
            const Text("Padh AI", style: TextStyle(color: KidsTheme.primaryPurple, fontWeight: FontWeight.w900)),
          ],
        ),
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.menu, color: KidsTheme.textDark))],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- ऊपर वाला हीरो सेक्शन (वेबसाइट की तरह) ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [KidsTheme.white, KidsTheme.bgPurple],
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), border: Border.all(color: KidsTheme.primaryPurple.withOpacity(0.2))),
                    child: const Text("✨ India का बच्चों वाला AI Teacher", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: KidsTheme.textDark)),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "पढ़ाई अब मज़ेदार — अपने AI Teacher से सीखो",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: KidsTheme.textDark, height: 1.2),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Live video call जैसा अनुभव. बच्चा कोई भी सवाल पूछे — पहाड़ा, English, Maths, GK — AI टीचर हिंदी या English में समझाएगा।",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _actionButton("📸 किताब स्कैन करें", KidsTheme.primaryPurple, true),
                      const SizedBox(width: 12),
                      _actionButton("AI Teacher से बात करें", Colors.white, false),
                    ],
                  ),
                ],
              ),
            ),

            // --- स्टैट्स सेक्शन ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statItem("10k+", "Happy बच्चे"),
                  _statItem("2", "भाषाएँ"),
                  _statItem("24x7", "AI Teacher"),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // --- मुख्य इमेज और कार्ड एरिया ---
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
                ),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                      child: Image.network(
                        "https://img.freepik.com/free-vector/kid-learning-with-robot-illustration_23-2148866504.jpg", // सैंपल कार्टून इमेज
                        fit: BoxFit.cover,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Text("आपका AI लर्निंग पार्टनर तैयार है!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          SizedBox(height: 10),
                          Text("आज क्या सीखना चाहोगे?", style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(String title, Color color, bool isDark) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: KidsTheme.primaryPurple, width: isDark ? 0 : 1)),
      ),
      onPressed: () {}, // यहाँ आपका फंक्शन आएगा
      child: Text(title, style: TextStyle(color: isDark ? Colors.white : KidsTheme.textDark, fontWeight: FontWeight.bold)),
    );
  }

  Widget _statItem(String val, String label) {
    return Column(
      children: [
        Text(val, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: KidsTheme.primaryPurple)),
        Text(label, style: const TextStyle(color: Colors.black54, fontSize: 13)),
      ],
    );
  }
}
