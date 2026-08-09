import 'package:flutter/material.dart';

void main() {
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
        scaffoldBackgroundColor: const Color(0xFFF3E8FF), // लाइट पर्पल बैकग्राउंड
        primaryColor: const Color(0xFF8B5CF6), // मुख्य पर्पल कलर
      ),
      home: const StudentHome(),
    );
  }
}

class StudentHome extends StatelessWidget {
  const StudentHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            // रोबोट वाला आइकन
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy_outlined, color: Colors.indigo, size: 28),
            ),
            const SizedBox(width: 12),
            const Text(
              "Padh AI",
              style: TextStyle(color: Color(0xFF8B5CF6), fontWeight: FontWeight.w900, fontSize: 24),
            ),
          ],
        ),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.menu, color: Colors.black, size: 30)),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 30),
            
            // 1. "India का बच्चों वाला AI Teacher" बैज
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Text(
                "✨ India का बच्चों वाला AI Teacher",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),

            const SizedBox(height: 25),

            // 2. मुख्य हेडलाइन
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "पढ़ाई अब मज़ेदार — अपने AI Teacher से सीखो",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1F2937),
                  height: 1.2,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 3. सब-टेक्स्ट (Details)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 30),
              child: Text(
                "Live video call जैसा अनुभव. बच्चा कोई भी सवाल पूछे — पहाड़ा, English, Maths, GK — AI टीचर हिंदी या English में प्यार से समझाएगा।",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, fontSize: 15, height: 1.5),
              ),
            ),

            const SizedBox(height: 35),

            // 4. कॉल टू एक्शन बटन (Buttons)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {},
                      icon: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                      label: const Text("किताब स्कैन करें", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        side: const BorderSide(color: Color(0xFF8B5CF6)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {},
                      child: const Text("AI Teacher से बात करें", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // 5. स्टैट्स (10k+, 2, 24x7)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStat("10k+", "Happy बच्चे"),
                _buildStat("2", "भाषाएँ"),
                _buildStat("24x7", "AI Teacher"),
              ],
            ),

            const SizedBox(height: 40),

            // 6. मुख्य व्हाइट कार्ड (Visual Section)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, spreadRadius: 5),
                  ],
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 30),
                    // यहाँ मैंने आपके फोटो वाली इमेजेस का लेआउट बनाया है
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Image.network(
                        "https://i.ibb.co/V9XpByM/sample-ui.png", // यहाँ आप अपनी इलस्ट्रेशन डाल सकते हैं
                        height: 200,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(20)),
                          child: const Icon(Icons.image_outlined, size: 50, color: Colors.purple),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      "आपका AI लर्निंग पार्टनर तैयार है!",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "आज क्या सीखना चाहोगे?",
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String val, String label) {
    return Column(
      children: [
        Text(val, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF8B5CF6))),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
