import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

void main() {
  runApp(const PadhAIApp());
}

class PadhAIApp extends StatelessWidget {
  const PadhAIApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Padh AI Digital School',
      theme: ThemeData(scaffoldBackgroundColor: const Color(0xFFF7F0FF), primaryColor: Colors.deepPurple),
      home: const AuthScreen(),
    );
  }
}

// --- 1. LOGIN & GRADE SELECTION ---
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  String selectedMedium = "Hindi";
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            children: [
              const Icon(Icons.school_rounded, size: 80, color: Colors.deepPurple),
              const Text("Padh AI School", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              const Text("अपना माध्यम चुनें (Select Medium)", style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Radio(value: "Hindi", groupValue: selectedMedium, onChanged: (v) => setState(() => selectedMedium = v.toString())),
                  const Text("Hindi"),
                  Radio(value: "English", groupValue: selectedMedium, onChanged: (v) => setState(() => selectedMedium = v.toString())),
                  const Text("English"),
                ],
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity, height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                  onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => StudentHome(isHindi: selectedMedium == "Hindi"))),
                  child: const Text("प्रवेश करें (Enter)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- 2. HOME SCREEN ---
class StudentHome extends StatelessWidget {
  final bool isHindi;
  const StudentHome({super.key, required this.isHindi});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isHindi ? "मेरा डिजिटल स्कूल" : "My Digital School"), backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
      body: GridView.count(
        padding: const EdgeInsets.all(20),
        crossAxisCount: 1, childAspectRatio: 3, crossAxisSpacing: 15, mainAxisSpacing: 15,
        children: [
          _menuCard(isHindi ? "📖 पहाड़ा किताब (2-20)" : "📖 Table Book (2-20)", Colors.orange, () => Navigator.push(context, MaterialPageRoute(builder: (c) => PahadaBook(isHindi: isHindi)))),
          _menuCard(isHindi ? "🎨 वर्णमाला (अ-ज्ञ / A-Z)" : "🎨 Alphabet Learning", Colors.blue, () => Navigator.push(context, MaterialPageRoute(builder: (c) => AlphabetBook(isHindi: isHindi)))),
          _menuCard(isHindi ? "🔢 गिनती (1-100)" : "🔢 Counting (1-100)", Colors.green, () => Navigator.push(context, MaterialPageRoute(builder: (c) => CountingBook(isHindi: isHindi)))),
        ],
      ),
    );
  }

  Widget _menuCard(String title, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))]),
        child: Center(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
      ),
    );
  }
}

// --- 3. COMPLETE ALPHABET BOOK (अ-ज्ञ & A-Z) ---
class AlphabetBook extends StatelessWidget {
  final bool isHindi;
  const AlphabetBook({super.key, required this.isHindi});

  @override
  Widget build(BuildContext context) {
    final FlutterTts tts = FlutterTts();
    
    // पूरी हिंदी वर्णमाला (अ से ज्ञ)
    final List<String> hindiAlpha = [
      "अ","आ","इ","ई","उ","ऊ","ऋ","ए","ऐ","ओ","औ","अं","अः",
      "क","ख","ग","घ","ङ","च","छ","ज","झ","ञ","ट","ठ","ड","ढ","ण","त","थ","द","ध","न","प","फ","ब","भ","म","य","र","ल","व","श","ष","स","ह","क्ष","त्र","ज्ञ"
    ];
    
    // पूरा A to Z
    final List<String> englishAlpha = List.generate(26, (index) => String.fromCharCode(65 + index));

    final data = isHindi ? hindiAlpha : englishAlpha;

    return Scaffold(
      appBar: AppBar(title: Text(isHindi ? "अ से ज्ञ तक" : "A to Z Letters")),
      body: GridView.builder(
        padding: const EdgeInsets.all(15),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10),
        itemCount: data.length,
        itemBuilder: (context, i) => InkWell(
          onTap: () {
            tts.setLanguage(isHindi ? "hi-IN" : "en-US");
            tts.setSpeechRate(0.3);
            tts.speak(isHindi ? data[i] : data[i]);
          },
          child: Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.blue.shade100)),
            child: Center(child: Text(data[i], style: const TextStyle(fontSize: 35, fontWeight: FontWeight.bold, color: Colors.blue))),
          ),
        ),
      ),
    );
  }
}

// --- 4. COMPLETE PAHADA BOOK (2-20) With Flip Pages ---
class PahadaBook extends StatelessWidget {
  final bool isHindi;
  const PahadaBook({super.key, required this.isHindi});

  @override
  Widget build(BuildContext context) {
    final FlutterTts tts = FlutterTts();
    final List<String> hindiNums = ["","","दो","तीन","चार","पाँच","छह","सात","आठ","नौ","दस","ग्यारह","बारह","तेरह","चौदह","पंद्रह","सोलह","सत्रह","अठारह","उन्नीस","बीस"];

    void speakTable(int n, int m) async {
      await tts.setLanguage(isHindi ? "hi-IN" : "en-US");
      await tts.setSpeechRate(0.3);
      int res = n * m;
      if (isHindi && n <= 10) {
        List<String> units = ["", "एकम", "दूनी", "तिये", "चौके", "पंचे", "छक्के", "सत्ते", "अट्ठे", "नम्मे", "दहाम"];
        tts.speak("${hindiNums[n]} ${units[m]} $res");
      } else {
        tts.speak(isHindi ? "$n गुना $m बराबर $res" : "$n times $m is $res");
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(isHindi ? "पहाड़ा (2-20)" : "Tables (2-20)")),
      body: PageView.builder(
        itemCount: 19, // 2 से 20 तक
        itemBuilder: (context, index) {
          int tableOf = index + 2;
          return Center(
            child: Container(
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 15)]),
              child: Column(
                children: [
                  Container(width: double.infinity, padding: const EdgeInsets.all(15), decoration: const BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.vertical(top: Radius.circular(25))), child: Text("$tableOf का पहाड़ा", textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))),
                  Expanded(
                    child: ListView.builder(
                      itemCount: 10,
                      itemBuilder: (c, i) => ListTile(
                        title: Text("$tableOf  x  ${i+1}  =  ${tableOf*(i+1)}", textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        onTap: () => speakTable(tableOf, i+1),
                      ),
                    ),
                  ),
                  const Padding(padding: EdgeInsets.all(10), child: Text("पन्ना पलटने के लिए स्लाइड करें ➡️", style: TextStyle(color: Colors.grey))),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// --- 5. COMPLETE COUNTING BOOK (1-100) ---
class CountingBook extends StatelessWidget {
  final bool isHindi;
  const CountingBook({super.key, required this.isHindi});

  @override
  Widget build(BuildContext context) {
    final FlutterTts tts = FlutterTts();
    return Scaffold(
      appBar: AppBar(title: Text(isHindi ? "गिनती (1-100)" : "Counting (1-100)")),
      body: GridView.builder(
        padding: const EdgeInsets.all(15),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 8, mainAxisSpacing: 8),
        itemCount: 100,
        itemBuilder: (context, i) {
          int num = i + 1;
          return InkWell(
            onTap: () {
              tts.setLanguage(isHindi ? "hi-IN" : "en-US");
              tts.setSpeechRate(0.3);
              tts.speak(num.toString());
            },
            child: Container(
              decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.green.shade200)),
              child: Center(child: Text("$num", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green))),
            ),
          );
        },
      ),
    );
  }
}
