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
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF7F0FF),
        primaryColor: Colors.deepPurple,
        fontFamily: 'Roboto',
      ),
      home: const AuthScreen(),
    );
  }
}

// --- 1. LOGIN & MEDIUM SELECTION ---
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
              const Icon(Icons.auto_awesome, size: 80, color: Colors.deepPurple),
              const Text("Padh AI School", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),
              const Text("अपना माध्यम चुनें (Select Medium)", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _mediumBtn("Hindi"),
                  const SizedBox(width: 20),
                  _mediumBtn("English"),
                ],
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity, height: 60,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                  onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => StudentHome(isHindi: selectedMedium == "Hindi"))),
                  child: const Text("प्रवेश करें (ENTER)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mediumBtn(String m) {
    bool isSel = selectedMedium == m;
    return ChoiceChip(
      label: Text(m, style: TextStyle(color: isSel ? Colors.white : Colors.black)),
      selected: isSel,
      selectedColor: Colors.deepPurple,
      onSelected: (v) => setState(() => selectedMedium = m),
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
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _menuCard("📖 पहाड़ा किताब (2-20)", "Table Flip Book", Colors.orange, () => Navigator.push(context, MaterialPageRoute(builder: (c) => PahadaBook(isHindi: isHindi)))),
          const SizedBox(height: 15),
          _menuCard("🎨 वर्णमाला (अ-ज्ञ / ABC)", "Alphabet with Pictures", Colors.blue, () => Navigator.push(context, MaterialPageRoute(builder: (c) => AlphabetBook(isHindi: isHindi)))),
          const SizedBox(height: 15),
          _menuCard("🔢 गिनती (1-100)", "Counting with Voice", Colors.green, () => Navigator.push(context, MaterialPageRoute(builder: (c) => CountingBook(isHindi: isHindi)))),
        ],
      ),
    );
  }

  Widget _menuCard(String title, String sub, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))]),
        child: Row(
          children: [
            const Icon(Icons.menu_book, color: Colors.white, size: 40),
            const SizedBox(width: 20),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              Text(sub, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ]),
          ],
        ),
      ),
    );
  }
}

// --- 3. ALPHABET BOOK WITH 3D CARTOON PICS ---
class AlphabetBook extends StatelessWidget {
  final bool isHindi;
  const AlphabetBook({super.key, required this.isHindi});

  @override
  Widget build(BuildContext context) {
    final FlutterTts tts = FlutterTts();
    
    // अ से अनार, आ से आम वाला डेटा
    final List<Map<String, String>> hindiData = [
      {"l": "अ", "w": "अनार", "i": "🍎"}, {"l": "आ", "w": "आम", "i": "🥭"},
      {"l": "इ", "w": "इमली", "i": "🍭"}, {"l": "ई", "w": "ईख", "i": "🎋"},
      {"l": "उ", "w": "उल्लू", "i": "🦉"}, {"l": "ऊ", "w": "ऊन", "i": "🧶"},
      {"l": "ऋ", "w": "ऋषि", "i": "🧘"}, {"l": "ए", "w": "एड़ी", "i": "👣"},
      {"l": "ऐ", "w": "ऐनक", "i": "👓"}, {"l": "ओ", "w": "ओखली", "i": "🥣"},
      {"l": "औ", "w": "औरत", "i": "👩"}, {"l": "अं", "w": "अंगूर", "i": "🍇"},
      {"l": "क", "w": "कबूतर", "i": "🐦"}, {"l": "ख", "w": "खरगोश", "i": "🐰"},
      {"l": "ग", "w": "गमला", "i": "🪴"}, {"l": "घ", "w": "घड़ी", "i": "⌚"},
    ];

    final List<Map<String, String>> englishData = [
      {"l": "A", "w": "Apple", "i": "🍎"}, {"l": "B", "w": "Ball", "i": "⚽"},
      {"l": "C", "w": "Cat", "i": "🐱"}, {"l": "D", "w": "Dog", "i": "🐶"},
      {"l": "E", "w": "Elephant", "i": "🐘"}, {"l": "F", "w": "Fish", "i": "🐟"},
    ];

    final data = isHindi ? hindiData : englishData;

    return Scaffold(
      appBar: AppBar(title: Text(isHindi ? "चित्र वर्णमाला" : "Picture ABC")),
      body: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15),
        itemCount: data.length,
        itemBuilder: (context, i) => InkWell(
          onTap: () async {
            await tts.setLanguage(isHindi ? "hi-IN" : "en-US");
            await tts.setPitch(1.0);
            await tts.setSpeechRate(0.4);
            String speech = isHindi ? "${data[i]['l']} से ${data[i]['w']}" : "${data[i]['l']} for ${data[i]['w']}";
            await tts.speak(speech);
          },
          child: Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(data[i]['i']!, style: const TextStyle(fontSize: 60)), // 3D Cartoon Icon
                const SizedBox(height: 10),
                Text(data[i]['l']!, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Colors.blue)),
                Text(data[i]['w']!, style: const TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- 4. IMPROVED COUNTING (NAIN to NAU Fix) ---
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
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 10, mainAxisSpacing: 10),
        itemCount: 100,
        itemBuilder: (context, i) {
          int num = i + 1;
          return InkWell(
            onTap: () async {
              await tts.setLanguage(isHindi ? "hi-IN" : "en-US"); // भाषा फिक्स
              await tts.setSpeechRate(0.4);
              await tts.speak(num.toString());
            },
            child: Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.green.shade100, width: 2)),
              child: Center(child: Text("$num", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green))),
            ),
          );
        },
      ),
    );
  }
}

// --- 5. PAHADA BOOK (Correct Flip & Speech) ---
class PahadaBook extends StatelessWidget {
  final bool isHindi;
  const PahadaBook({super.key, required this.isHindi});

  @override
  Widget build(BuildContext context) {
    final FlutterTts tts = FlutterTts();
    final List<String> hindiNums = ["","","दो","तीन","चार","पाँच","छह","सात","आठ","नौ","दस","ग्यारह","बारह","तेरह","चौदह","पंद्रह","सोलह","सत्रह","अठारह","उन्नीस","बीस"];

    void speakTable(int n, int m) async {
      await tts.setLanguage(isHindi ? "hi-IN" : "en-US");
      await tts.setSpeechRate(0.35);
      int res = n * m;
      
      if (isHindi && n <= 10) {
        List<String> units = ["", "एकम", "दूनी", "तिये", "चौके", "पंचे", "छक्के", "सत्ते", "अट्ठे", "नम्मे", "दहाम"];
        await tts.speak("${hindiNums[n]} ${units[m]} $res");
      } else {
        await tts.speak(isHindi ? "$n गुना $m बराबर $res" : "$n times $m is $res");
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(isHindi ? "डिजिटल पहाड़ा" : "Table Book")),
      body: PageView.builder(
        itemCount: 19,
        itemBuilder: (context, index) {
          int tableOf = index + 2;
          return Center(
            child: Container(
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)]),
              child: Column(
                children: [
                  Container(width: double.infinity, padding: const EdgeInsets.all(20), decoration: const BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.vertical(top: Radius.circular(30))), child: Text(isHindi ? "$tableOf का पहाड़ा" : "Table of $tableOf", textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold))),
                  Expanded(
                    child: ListView.builder(
                      itemCount: 10,
                      itemBuilder: (c, i) => ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                        title: Text("$tableOf  x  ${i+1}  =  ${tableOf*(i+1)}", textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.blueGrey)),
                        onTap: () => speakTable(tableOf, i+1),
                      ),
                    ),
                  ),
                  const Padding(padding: EdgeInsets.all(15), child: Text("अगले पहाड़े के लिए पन्ना पलटें ➡️", style: TextStyle(color: Colors.grey))),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
