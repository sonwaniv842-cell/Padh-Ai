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
    debugPrint("Init Error: $e");
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
      home: const AuthScreen(), 
    );
  }
}

// --- 1. PREMIUM AUTH SCREEN (With Grade & Medium) ---
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isRegister = false;
  String selectedGrade = "1st";
  String selectedMedium = "Hindi";

  final List<String> grades = ["1st", "2nd", "3rd", "4th", "5th", "6th", "7th", "8th", "9th", "10th", "11th", "12th"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            children: [
              const Icon(Icons.auto_awesome, size: 70, color: Color(0xFF8B5CF6)),
              const Text("Padh AI", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF8B5CF6))),
              const SizedBox(height: 30),
              
              _buildInput("Email Address", Icons.email),
              const SizedBox(height: 15),
              _buildInput("Password", Icons.lock, obscure: true),
              
              if (isRegister) ...[
                const SizedBox(height: 20),
                // --- GRADE SELECTION ---
                const Align(alignment: Alignment.centerLeft, child: Text("अपनी कक्षा चुनें (Select Grade)", style: TextStyle(fontWeight: FontWeight.bold))),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
                  child: DropdownButton<String>(
                    value: selectedGrade,
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: grades.map((String value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
                    onChanged: (val) => setState(() => selectedGrade = val!),
                  ),
                ),
                const SizedBox(height: 20),
                
                // --- MEDIUM SELECTION ---
                const Align(alignment: Alignment.centerLeft, child: Text("माध्यम चुनें (Select Medium)", style: TextStyle(fontWeight: FontWeight.bold))),
                Row(
                  children: [
                    Expanded(child: RadioListTile(title: const Text("हिंदी"), value: "Hindi", groupValue: selectedMedium, onChanged: (v) => setState(() => selectedMedium = v!))),
                    Expanded(child: RadioListTile(title: const Text("English"), value: "English", groupValue: selectedMedium, onChanged: (v) => setState(() => selectedMedium = v!))),
                  ],
                ),
              ],
              
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                  onPressed: () {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => StudentDashboard(grade: selectedGrade, medium: selectedMedium)));
                  },
                  child: Text(isRegister ? "GET STARTED" : "LOGIN", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(onPressed: () => setState(() => isRegister = !isRegister), child: Text(isRegister ? "Already have account? Login" : "Create New Account", style: const TextStyle(color: Colors.black54))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(String label, IconData icon, {bool obscure = false}) {
    return TextField(obscureText: obscure, decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, color: const Color(0xFF8B5CF6)), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)));
  }
}

// --- 2. STUDENT DASHBOARD (Personalized) ---
class StudentDashboard extends StatelessWidget {
  final String grade;
  final String medium;
  const StudentDashboard({super.key, required this.grade, required this.medium});

  @override
  Widget build(BuildContext context) {
    final FlutterTts tts = FlutterTts();
    bool isHindi = medium == "Hindi";

    void _speak(String text) async {
      await tts.setLanguage(isHindi ? "hi-IN" : "en-US");
      await tts.setSpeechRate(0.35); // साफ़ और धीरे
      await tts.speak(text);
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        title: const Text("My Padh AI School", style: TextStyle(color: Color(0xFF8B5CF6), fontWeight: FontWeight.bold)),
        actions: [
          // Grade & Medium Badge
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: Chip(label: Text("$grade | $medium", style: const TextStyle(fontSize: 10, color: Colors.white)), backgroundColor: const Color(0xFF8B5CF6)),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(isHindi ? "पढ़ाई अब मज़ेदार — AI से सीखो" : "Learning is Fun — Learn with AI", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900), textAlign: TextAlign.center),
            const SizedBox(height: 30),
            
            _moduleCard(isHindi ? "📖 डिजिटल पहाड़ा बुक" : "📖 Digital Table Book", isHindi ? "पन्ने पलटें और सीखें" : "Flip pages & learn", Colors.orange, () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => PahadaFlipBook(isHindi: isHindi)));
            }),

            const SizedBox(height: 15),
            _moduleCard(isHindi ? "🎒 एबीसी और गिनती" : "🎒 ABC & 123 Fun", isHindi ? "मजेदार पढ़ाई" : "Playful learning", Colors.blue, () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => AlphabetPage(isHindi: isHindi)));
            }),

            const SizedBox(height: 30),
            _buildScoreCard(),
          ],
        ),
      ),
    );
  }

  Widget _moduleCard(String title, String desc, Color color, VoidCallback fn) {
    return InkWell(
      onTap: fn,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(24)),
        child: Row(children: [const Icon(Icons.auto_stories, color: Colors.white, size: 35), const SizedBox(width: 15), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)), Text(desc, style: const TextStyle(color: Colors.white70, fontSize: 12))])]),
      ),
    );
  }

  Widget _buildScoreCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20), padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("AI Score", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)), Text("98/100", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))]), Icon(Icons.stars, color: Colors.green, size: 40)]),
    );
  }
}

// --- 3. DIGITAL PAHADA BOOK (Responsive Language) ---
class PahadaFlipBook extends StatelessWidget {
  final bool isHindi;
  const PahadaFlipBook({super.key, required this.isHindi});

  @override
  Widget build(BuildContext context) {
    final FlutterTts tts = FlutterTts();
    return Scaffold(
      backgroundColor: const Color(0xFF2D3436),
      appBar: AppBar(title: Text(isHindi ? "डिजिटल पहाड़ा किताब" : "Digital Table Book")),
      body: PageView.builder(
        itemCount: 10,
        itemBuilder: (context, index) {
          int tableOf = index + 2;
          return Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
              child: Column(
                children: [
                  Container(width: double.infinity, padding: const EdgeInsets.all(20), decoration: const BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.only(topRight: Radius.circular(30), topLeft: Radius.circular(30))), child: Text(isHindi ? "$tableOf का पहाड़ा" : "Table of $tableOf", textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))),
                  Expanded(
                    child: ListView.builder(
                      itemCount: 10,
                      itemBuilder: (context, i) {
                        int res = tableOf * (i + 1);
                        return ListTile(
                          title: Text("$tableOf x ${i + 1} = $res", textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          onTap: () async {
                            await tts.setLanguage(isHindi ? "hi-IN" : "en-US");
                            await tts.setSpeechRate(0.3);
                            await tts.speak(isHindi ? "$tableOf गुना ${i + 1} बराबर $res" : "$tableOf times ${i + 1} is $res");
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// --- 4. ALPHABET MODULE (Personalized) ---
class AlphabetPage extends StatelessWidget {
  final bool isHindi;
  const AlphabetPage({super.key, required this.isHindi});

  @override
  Widget build(BuildContext context) {
    final FlutterTts tts = FlutterTts();
    final List<Map<String, String>> data = isHindi 
      ? [{"l": "क", "w": "कबूतर", "e": "🐦"}, {"l": "ख", "w": "खरगोश", "e": "🐰"}]
      : [{"l": "A", "w": "Apple", "e": "🍎"}, {"l": "B", "w": "Ball", "e": "⚽"}];

    return Scaffold(
      appBar: AppBar(title: Text(isHindi ? "क ख ग सीखें" : "Learn ABC")),
      body: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15),
        itemCount: data.length,
        itemBuilder: (context, i) => InkWell(
          onTap: () async {
            await tts.setLanguage(isHindi ? "hi-IN" : "en-US");
            await tts.speak(isHindi ? "${data[i]['l']} से ${data[i]['w']}" : "${data[i]['l']} for ${data[i]['w']}");
          },
          child: Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(data[i]['e']!, style: const TextStyle(fontSize: 50)), Text(data[i]['l']!, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Colors.blue)), Text(data[i]['w']!, style: const TextStyle(fontSize: 16, color: Colors.grey))]),
          ),
        ),
      ),
    );
  }
}
