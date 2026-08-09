import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- CONFIGURATION ---
const supabaseUrl = 'https://tyonurrbwdjqfrmqrgpk.supabase.co';
const supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY'; // 👈 यहाँ अपनी असली Key डालें

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
        primaryColor: const Color(0xFF00E5FF), // Cyber Cyan
        scaffoldBackgroundColor: const Color(0xFF0A0E21), // Robot Navy
        fontFamily: 'Roboto',
        cardTheme: CardTheme(
          color: const Color(0xFF1D1B2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 10,
        ),
      ),
      home: supabase.auth.currentSession == null ? const AuthScreen() : const StartupWrapper(),
    );
  }
}

// --- 1. LOGIN / SIGNUP & PASSWORD RESET ---
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;

  Future<void> _handleAuth() async {
    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        await supabase.auth.signInWithPassword(email: _emailController.text.trim(), password: _passController.text);
      } else {
        final res = await supabase.auth.signUp(email: _emailController.text.trim(), password: _passController.text);
        if (res.user != null) {
          await supabase.from('profiles').upsert({
            'id': res.user!.id,
            'full_name': _nameController.text.trim(),
            'role': 'student',
            'is_active': true,
          });
        }
      }
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const StartupWrapper()));
    } catch (e) {
      _showError("त्रुटि: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (_emailController.text.trim().isEmpty) {
      _showError("पासवर्ड रीसेट के लिए अपनी ईमेल भरें");
      return;
    }
    try {
      await supabase.auth.resetPasswordForEmail(_emailController.text.trim());
      _showError("पासवर्ड रीसेट लिंक आपकी ईमेल पर भेज दिया गया है।");
    } catch (e) {
      _showError("त्रुटि: $e");
    }
  }

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            children: [
              const Text("🤖", style: TextStyle(fontSize: 80)),
              const Text("Padh-AI", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF00E5FF))),
              const SizedBox(height: 40),
              if (!_isLogin) TextField(controller: _nameController, decoration: const InputDecoration(labelText: "पूरा नाम", border: OutlineInputBorder())),
              if (!_isLogin) const SizedBox(height: 15),
              TextField(controller: _emailController, decoration: const InputDecoration(labelText: "ईमेल आईडी", border: OutlineInputBorder())),
              const SizedBox(height: 15),
              TextField(controller: _passController, obscureText: true, decoration: const InputDecoration(labelText: "पिन / पासवर्ड", border: OutlineInputBorder())),
              const SizedBox(height: 30),
              _isLoading ? const CircularProgressIndicator() : SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _handleAuth, child: Text(_isLogin ? "लॉगिन" : "साइन-अप"))),
              TextButton(onPressed: () => setState(() => _isLogin = !_isLogin), child: Text(_isLogin ? "नया अकाउंट बनायें" : "पुराना अकाउंट है? लॉगिन करें")),
              TextButton(onPressed: _resetPassword, child: const Text("पासवर्ड भूल गए? रीसेट करें", style: TextStyle(color: Colors.grey))),
            ],
          ),
        ),
      ),
    );
  }
}

// --- 2. CLASS SELECTION WRAPPER ---
class StartupWrapper extends StatefulWidget {
  const StartupWrapper({super.key});
  @override
  State<StartupWrapper> createState() => _StartupWrapperState();
}

class _StartupWrapperState extends State<StartupWrapper> {
  bool _isLoading = true;
  String? _class;

  @override
  void initState() {
    super.initState();
    _checkClass();
  }

  _checkClass() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final data = await supabase.from('profiles').select('class_level').eq('id', user.id).maybeSingle();
        if (data != null && data['class_level'] != null) {
          _class = data['class_level'];
        }
      }
    } catch (e) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_class == null) return const ClassSelectionScreen();
    return const MainDashboard();
  }
}

class ClassSelectionScreen extends StatelessWidget {
  const ClassSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    List<String> classes = ["KG-1", "KG-2", "1st", "2nd", "3rd", "4th", "5th", "6th", "7th", "8th", "9th", "10th", "11th", "12th"];
    return Scaffold(
      appBar: AppBar(title: const Text("अपनी कक्षा चुनें")),
      body: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 2),
        itemCount: classes.length,
        itemBuilder: (c, i) => InkWell(
          onTap: () async {
            final user = supabase.auth.currentUser;
            if (user != null) {
              await supabase.from('profiles').update({'class_level': classes[i]}).eq('id', user.id);
            }
            if (context.mounted) {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const StartupWrapper()));
            }
          },
          child: Card(child: Center(child: Text(classes[i], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)))),
        ),
      ),
    );
  }
}

// --- 3. MAIN DASHBOARD & EXAM HISTORY ---
class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});
  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("🤖 Padh-AI"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout), 
            onPressed: () async {
              await supabase.auth.signOut();
              if (mounted) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const AuthScreen()));
              }
            }
          )
        ],
      ),
      body: _tab == 0 ? const StudentHome() : const ExamHistory(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "होम"),
          BottomNavigationBarItem(icon: Icon(Icons.history_edu), label: "एग्जाम हिस्ट्री"),
        ],
      ),
    );
  }
}

class StudentHome extends StatelessWidget {
  const StudentHome({super.key});
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text("🤖 नमस्ते स्टूडेंट!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                SizedBox(height: 5),
                Text("आज हम क्या पढ़ेंगे?", style: TextStyle(color: Colors.cyanAccent)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        _buildFeatureCard("📸 कैमरा स्कैनर", "किताब का फोटो लें और AI से समझें"),
        _buildFeatureCard("📚 डेली क्विज", "आज का टेस्ट दें और इनाम जीतें"),
      ],
    );
  }

  Widget _buildFeatureCard(String title, String sub) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      child: ListTile(title: Text(title), subtitle: Text(sub), trailing: const Icon(Icons.arrow_forward_ios)),
    );
  }
}

class ExamHistory extends StatelessWidget {
  const ExamHistory({super.key});
  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    if (user == null) return const Center(child: Text("लॉगिन करें"));

    return FutureBuilder(
      future: supabase.from('exam_history').select().eq('student_id', user.id),
      builder: (context, AsyncSnapshot snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        if (snap.data.isEmpty) {
          return const Center(child: Text("अभी कोई एग्जाम हिस्ट्री नहीं है।"));
        }
        return ListView.builder(
          itemCount: snap.data.length,
          itemBuilder: (c, i) => Card(
            margin: const EdgeInsets.all(10),
            child: ListTile(
              title: Text("${snap.data[i]['month'] ?? 'मासिक'} - टेस्ट रिजल्ट"),
              subtitle: Text("मार्क्स: ${snap.data[i]['marks'] ?? 0} | प्रतिशत: ${snap.data[i]['percent'] ?? 0}%"),
              trailing: const Icon(Icons.check_circle, color: Colors.green),
            ),
          ),
        );
      },
    );
  }
}
