import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image_picker/image_picker.dart';

// --- CONFIGURATION ---
const supabaseUrl = 'https://tyonurrbwdjqfrmqrgpk.supabase.co';
const supabaseAnonKey = 'sb_publishable_VSX21HOdkHZTTYvxj7DGTQ_tcyv4gDJ';

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
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF6C63FF),
        scaffoldBackgroundColor: const Color(0xFF0D0D1E),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF)),
        ),
      ),
      home: supabase.auth.currentSession == null ? const AuthScreen() : const MainContainer(),
    );
  }
}

// --- GLOBAL STATE & PROFILE ---
class UserData {
  static String? fullName;
  static String? classLevel;
  static String? medium;
  static bool isAdmin = false;
}

// --- 1. AUTH & REGISTRATION SCREEN ---
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  String _selectedClass = "1st";
  String _selectedMedium = "Hindi";
  bool _isOTPsent = false;
  final _otpController = TextEditingController();

  Future<void> _handleAuth() async {
    try {
      if (!_isOTPsent) {
        await supabase.auth.signInWithOtp(phone: _phoneController.text.trim());
        setState(() => _isOTPsent = true);
      } else {
        final res = await supabase.auth.verifyOtp(
          phone: _phoneController.text.trim(),
          token: _otpController.text.trim(),
          type: OtpType.sms,
        );
        if (res.session != null) {
          // Profile Create/Update
          await supabase.from('profiles').upsert({
            'id': res.user!.id,
            'full_name': _nameController.text,
            'class_level': _selectedClass,
            'medium': _selectedMedium,
          });
          if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const MainContainer()));
        }
      }
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
            const SizedBox(height: 80),
            const Text("Padh AI", style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Color(0xFF6C63FF))),
            const Text("भविष्य की डिजिटल पाठशाला", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 40),
            if (!_isOTPsent) ...[
              TextField(controller: _nameController, decoration: const InputDecoration(labelText: "पूरा नाम", border: OutlineInputBorder())),
              const SizedBox(height: 15),
              DropdownButtonFormField(
                value: _selectedClass,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: ["KG1", "KG2", "1st", "2nd", "3rd", "4th", "5th", "6th", "7th", "8th", "9th", "10th", "11th", "12th", "UPSC"]
                    .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => _selectedClass = v!,
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  const Text("Medium: "),
                  Radio(value: "Hindi", groupValue: _selectedMedium, onChanged: (v) => setState(() => _selectedMedium = v!)), const Text("Hindi"),
                  Radio(value: "English", groupValue: _selectedMedium, onChanged: (v) => setState(() => _selectedMedium = v!)), const Text("English"),
                ],
              ),
              TextField(controller: _phoneController, decoration: const InputDecoration(labelText: "मोबाइल नंबर (+91)", border: OutlineInputBorder())),
            ] else ...[
              const Text("OTP दर्ज करें जो आपके फोन पर भेजा गया है"),
              const SizedBox(height: 20),
              TextField(controller: _otpController, decoration: const InputDecoration(labelText: "6-Digit OTP", border: OutlineInputBorder())),
            ],
            const SizedBox(height: 30),
            SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _handleAuth, child: Text(_isOTPsent ? "Verify OTP" : "Register / Login"))),
          ],
        ),
      ),
    );
  }
}

// --- MAIN CONTAINER (DASHBOARD) ---
class MainContainer extends StatefulWidget {
  const MainContainer({super.key});
  @override
  State<MainContainer> createState() => _MainContainerState();
}

class _MainContainerState extends State<MainContainer> {
  int _tabIndex = 0;
  bool _isLoading = true;
  final FlutterTts _tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  _loadProfile() async {
    final user = supabase.auth.currentUser;
    final data = await supabase.from('profiles').select().eq('id', user!.id).single();
    setState(() {
      UserData.fullName = data['full_name'];
      UserData.classLevel = data['class_level'];
      UserData.medium = data['medium'];
      UserData.isAdmin = data['is_admin'] ?? false;
      _isLoading = false;
    });
  }

  // FEATURE 1: KG Pahada with AI Voice
  Widget _buildLearn() {
    if (UserData.classLevel!.contains("KG")) {
      List<Map<String, String>> letters = [
        {"l": "A", "w": "Apple"}, {"l": "B", "w": "Ball"}, {"l": "C", "w": "Cat"}, {"l": "D", "w": "Dog"}
      ];
      return GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15),
        itemCount: letters.length,
        itemBuilder: (c, i) => InkWell(
          onTap: () => _tts.speak(UserData.medium == "Hindi" ? "Bolo bacho, ${letters[i]['l']} for ${letters[i]['w']}" : "${letters[i]['l']} for ${letters[i]['w']}"),
          child: Container(
            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white24)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(letters[i]['l']!, style: const TextStyle(fontSize: 60, fontWeight: FontWeight.bold)),
                Text(letters[i]['w']!, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ),
      );
    }
    return Center(child: Text("${UserData.classLevel} की पढ़ाई जल्द शुरू होगी!", style: const TextStyle(fontSize: 18)));
  }

  // FEATURE 2: Monthly Exam System
  Widget _buildExam() {
    return Padding(
      padding: const EdgeInsets.all(25),
      child: Column(
        children: [
          const Icon(Icons.stars, size: 80, color: Colors.amber),
          const SizedBox(height: 20),
          const Text("मंथली मेगा एग्जाम", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const Text("तारीख: हर महीने की 30 तारीख", style: TextStyle(color: Colors.grey)),
          const Divider(height: 40),
          const ListTile(leading: Icon(Icons.payment), title: Text("एग्जाम फीस: ₹50 मात्र"), subtitle: Text("प्रथम आने पर: Smart TV या Cycle!")),
          const SizedBox(height: 30),
          SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: () {}, child: const Text("Pay ₹50 & Enroll Now"))),
        ],
      ),
    );
  }

  // FEATURE 3: Scanner (Dummy UI for Mobile Compatibility)
  Widget _buildScanner() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.qr_code_scanner, size: 100, color: Color(0xFF6C63FF)),
          const SizedBox(height: 20),
          const Text("किसी भी सवाल को स्कैन करें", style: TextStyle(fontSize: 18)),
          const SizedBox(height: 20),
          ElevatedButton.icon(onPressed: () async => await ImagePicker().pickImage(source: ImageSource.camera), icon: const Icon(Icons.camera_alt), label: const Text("कैमरा खोलें")),
        ],
      ),
    );
  }

  // FEATURE 4: AI + Admin Helpline
  Widget _buildHelpline() {
    return Column(
      children: [
        const Expanded(child: Center(child: Text("नमस्ते! क्या सहायता चाहिए?\n(Admin ऑफलाइन होने पर AI जवाब देगा)", textAlign: TextAlign.center))),
        Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              const Expanded(child: TextField(decoration: InputDecoration(hintText: "यहाँ अपना सवाल लिखें...", border: OutlineInputBorder()))),
              IconButton(onPressed: () {}, icon: const Icon(Icons.send, color: Color(0xFF6C63FF))),
            ],
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: Text("Padh AI: ${UserData.fullName}"),
        actions: [if (UserData.isAdmin) IconButton(icon: const Icon(Icons.admin_panel_settings, color: Colors.orange), onPressed: () {})],
      ),
      body: IndexedStack(index: _tabIndex, children: [_buildLearn(), _buildExam(), _buildScanner(), _buildHelpline()]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex,
        selectedItemColor: const Color(0xFF6C63FF),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => setState(() => _tabIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.book), label: "पढ़ाई"),
          BottomNavigationBarItem(icon: Icon(Icons.quiz), label: "एग्जाम"),
          BottomNavigationBarItem(icon: Icon(Icons.camera), label: "स्कैन"),
          BottomNavigationBarItem(icon: Icon(Icons.support_agent), label: "हेल्पलाइन"),
        ],
      ),
    );
  }
}
