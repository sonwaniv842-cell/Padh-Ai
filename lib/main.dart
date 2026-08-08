import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_tts/flutter_tts.dart';

// CONFIG
const supabaseUrl = 'https://tyonurrbwdjqfrmqrgpk.supabase.co';
const supabaseAnonKey = 'YOUR_KEY_HERE';

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
      theme: ThemeData(brightness: Brightness.dark, primaryColor: Colors.deepPurple, scaffoldBackgroundColor: const Color(0xFF0D0D1E)),
      home: supabase.auth.currentSession == null ? const RegistrationScreen() : const MainDashboard(),
    );
  }
}

// --- 1. रजिस्ट्रेशन और क्लास/मीडियम सिलेक्शन ---
class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});
  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  String selectedClass = "1st";
  String selectedMedium = "Hindi";
  final phoneController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Padh AI में आपका स्वागत है", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            DropdownButtonFormField(
              value: selectedClass,
              items: List.generate(12, (i) => "${i + 1}th").map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) => setState(() => selectedClass = val as String),
              decoration: const InputDecoration(labelText: "अपनी कक्षा चुनें"),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Text("मीडियम: "),
                Radio(value: "Hindi", groupValue: selectedMedium, onChanged: (v) => setState(() => selectedMedium = v!)), const Text("Hindi"),
                Radio(value: "English", groupValue: selectedMedium, onChanged: (v) => setState(() => selectedMedium = v!)), const Text("English"),
              ],
            ),
            TextField(controller: phoneController, decoration: const InputDecoration(hintText: "फोन नंबर")),
            const SizedBox(height: 30),
            ElevatedButton(onPressed: () {}, child: const Text("रजिस्टर करें")) // यहाँ Supabase Auth का कोड आएगा
          ],
        ),
      ),
    );
  }
}

// --- 2. मेन डैशबोर्ड ---
class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});
  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int _currentIndex = 0;
  final FlutterTts tts = FlutterTts();

  // फीचर: डिजिटल पहाड़ा (KG बच्चों के लिए)
  Widget digitalPahada() {
    List<Map<String, String>> abc = [{"l":"A", "w":"Apple"}, {"l":"B", "w":"Ball"}];
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
      itemCount: abc.length,
      itemBuilder: (ctx, i) => InkWell(
        onTap: () => tts.speak("Bolo bacho, ${abc[i]['l']} for ${abc[i]['w']}"),
        child: Card(child: Center(child: Text(abc[i]['l']!, style: const TextStyle(fontSize: 80)))),
      ),
    );
  }

  // फीचर: एग्जाम और ₹50 फीस
  Widget examSection() {
    return Column(
      children: [
        const ListTile(title: Text("मंथली एग्जाम (30 तारीख)"), subtitle: Text("फीस: ₹50 मात्र")),
        const Text("नोट: इस ₹50 से आपको इनाम (TV, Watch, Cycle) मिल सकता है!"),
        ElevatedButton(onPressed: () {}, child: const Text("फीस जमा करें और एग्जाम शुरू करें"))
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Padh AI - भविष्य की शिक्षा")),
      body: _currentIndex == 0 ? digitalPahada() : (_currentIndex == 1 ? examSection() : const Center(child: Text("Helpline / Chat"))),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.school), label: "पढ़ाई"),
          BottomNavigationBarItem(icon: Icon(Icons.quiz), label: "एग्जाम"),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: "हेल्पलाइन"),
        ],
      ),
    );
  }
}
