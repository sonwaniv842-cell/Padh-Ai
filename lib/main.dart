import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:url_launcher/url_launcher.dart';

// --- CONFIG ---
const supabaseUrl = 'https://tyonurrbwdjqfrmqrgpk.supabase.co';
const supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY'; // <--- अपनी Supabase Anon Key यहाँ डालें

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
        cardTheme: CardTheme(
          color: const Color(0xFF1A1A2E), 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
        ),
        fontFamily: 'Inter',
      ),
      home: supabase.auth.currentSession == null ? const AuthScreen() : const MainContainer(),
    );
  }
}

// --- 1. ENHANCED SIGN-UP / USER PROFILE & LOGIN ---
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _nameController = TextEditingController();
  final _pNameController = TextEditingController();
  final _pPhoneController = TextEditingController();
  bool _isLoading = false;
  bool _isSignUp = true; // साइनअप और लॉगिन के बीच स्विच करने के लिए

  Future<void> _handleAuth() async {
    final email = _emailController.text.trim();
    final password = _passController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("कृपया ईमेल और पासवर्ड भरें।")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isSignUp) {
        // नया साइन-अप
        final res = await supabase.auth.signUp(email: email, password: password);
        if (res.user != null) {
          await supabase.from('profiles').upsert({
            'id': res.user!.id,
            'full_name': _nameController.text.trim(),
            'parent_name': _pNameController.text.trim(),
            'parent_phone': _pPhoneController.text.trim(),
            'class_level': '1st',
          });
          if (mounted) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const MainContainer()));
          }
        }
      } else {
        // पुराना यूज़र लॉगिन
        await supabase.auth.signInWithPassword(email: email, password: password);
        if (mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const MainContainer()));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            const SizedBox(height: 60),
            const Text(
              "Padh AI", 
              style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold, color: Color(0xFF6C63FF))
            ),
            const SizedBox(height: 20),
            Text(
              _isSignUp ? "नया अकाउंट बनायें" : "पुराने अकाउंट से लॉगिन करें",
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 25),
            
            // सिर्फ साइन-अप के समय ये 3 एक्स्ट्रा फ़ील्ड दिखेंगे
            if (_isSignUp) ...[
              _buildField(_nameController, "छात्र का नाम"),
              _buildField(_pNameController, "पिता/अभिभावक का नाम"),
              _buildField(_pPhoneController, "अभिभावक का WhatsApp नंबर", icon: Icons.whatsapp),
            ],

            _buildField(_emailController, "ईमेल आईडी"),
            _buildField(_passController, "पासवर्ड (कम से कम 6 अंक)", isPass: true),
            
            const SizedBox(height: 25),
            _isLoading 
              ? const CircularProgressIndicator() 
              : SizedBox(
                  width: double.infinity, 
                  height: 55, 
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF)),
                    onPressed: _handleAuth, 
                    child: Text(_isSignUp ? "रजिस्टर करें" : "लॉगिन करें", style: const TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                ),
            
            const SizedBox(height: 15),
            TextButton(
              onPressed: () => setState(() => _isSignUp = !_isSignUp),
              child: Text(_isSignUp ? "पहले से अकाउंट है? लॉगिन करें" : "नया अकाउंट बनायें (रजिस्टर)"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, {bool isPass = false, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        obscureText: isPass,
        decoration: InputDecoration(
          labelText: label, 
          prefixIcon: icon != null ? Icon(icon, color: Colors.green) : null, 
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))
        ),
      ),
    );
  }
}

// --- MAIN CONTAINER ---
class MainContainer extends StatefulWidget {
  const MainContainer({super.key});

  @override
  State<MainContainer> createState() => _MainContainerState();
}

class _MainContainerState extends State<MainContainer> {
  Map<String, dynamic>? userProfile;
  final FlutterTts flutterTts = FlutterTts();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final data = await supabase.from('profiles').select().eq('id', user.id).maybeSingle();
        setState(() { 
          userProfile = data; 
          _isLoading = false; 
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _speakTrustMessage() async {
    String msg = "नमस्ते अभिभावक, हम पढ़ाई के नाम पर एक रुपया भी फीस नहीं लेते। 3 महीने पढ़ाकर देखें, सुधार न दिखे तो कहें। 50 रुपये की फीस केवल टेस्ट के लिए है जो बच्चों के 10,000 से 20,000 रुपये के इनाम और स्कॉलरशिप के काम आती है। हमारा सपना बस इतना है कि कल बच्चा आगे बढ़े।";
    await flutterTts.setLanguage("hi-IN");
    await flutterTts.speak(msg);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final bannerUrl = userProfile?['banner_url'] ?? 'https://placeholder.co/600x200/6C63FF/white?text=Padh+AI+Scholarship';

    return Scaffold(
      appBar: AppBar(
        title: const Text("Padh AI Home"), 
        actions: [
          if (userProfile?['is_admin'] == true) 
            IconButton(
              icon: const Icon(Icons.admin_panel_settings, color: Colors.amber), 
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AdminPanel()))
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await supabase.auth.signOut();
              if (mounted) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const AuthScreen()));
              }
            },
          )
        ]
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // DYNAMIC BANNER
            Image.network(
              bannerUrl, 
              height: 180, 
              width: double.infinity, 
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 180,
                color: const Color(0xFF1A1A2E),
                child: const Center(child: Text("Padh AI Banner", style: TextStyle(fontSize: 20))),
              ),
            ),

            // PARENT TRUST MESSAGE
            Padding(
              padding: const EdgeInsets.all(15),
              child: Card(
                elevation: 10,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("पैरेंट्स के लिए संदेश", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFBB86FC))),
                          IconButton(
                            icon: const Icon(Icons.volume_up, size: 35, color: Color(0xFF6C63FF)), 
                            onPressed: _speakTrustMessage
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "हम पढ़ाई के नाम पर ₹1 भी फीस नहीं लेते। 3 महीने पढ़ाकर देखें, सुधार न दिखे तो कहें। ₹50 की फीस केवल हर महीने के टेस्ट के लिए है जो एकत्रित होकर Rank 1, 2, 3 बच्चों के ₹10,000 - ₹20,000 के इनाम, स्कॉलरशिप और गिफ्ट्स के काम आती है।",
                        style: TextStyle(height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // EXAM LOCK / UNLOCK SYSTEM
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: userProfile?['has_paid'] == true ? _buildAdmitCard() : _buildLockedExam(),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildLockedExam() {
    return Card(
      color: Colors.red.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            const Icon(Icons.lock, size: 60, color: Colors.redAccent),
            const SizedBox(height: 15),
            const Text("एग्जाम सेक्शन लॉक है", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            const Text(
              "एग्जाम फीस (₹50) न देने पर आपको परीक्षा में नहीं बैठने दिया जाएगा।", 
              textAlign: TextAlign.center, 
              style: TextStyle(color: Colors.grey)
            ),
            const SizedBox(height: 20),
            const Text("इस QR कोड पर ₹50 पे करें और एडमिन को स्क्रीनशॉट भेजें:", style: TextStyle(fontSize: 12)),
            const SizedBox(height: 10),
            Image.network(
              'https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=upi://pay?pa=ADMIN@UPI&pn=PadhAI', 
              height: 150
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdmitCard() {
    return Card(
      color: Colors.green.withOpacity(0.1),
      child: const ListTile(
        leading: Icon(Icons.assignment_ind, color: Colors.green, size: 40),
        title: Text("एग्जाम अनलॉक हो गया!"),
        subtitle: Text("अपना एडमिट कार्ड यहाँ से डाउनलोड करें और परीक्षा में बैठें।"),
        trailing: Icon(Icons.arrow_forward_ios),
      ),
    );
  }
}

// --- ADVANCED ADMIN PANEL ---
class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  List<dynamic> users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  _fetchUsers() async {
    final data = await supabase.from('profiles').select();
    setState(() { users = data; _loading = false; });
  }

  _togglePayment(String id, bool currentStatus) async {
    await supabase.from('profiles').update({'has_paid': !currentStatus}).eq('id', id);
    _fetchUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Control Centre")),
      body: _loading 
        ? const Center(child: CircularProgressIndicator()) 
        : ListView.builder(
            itemCount: users.length,
            itemBuilder: (c, i) {
              final u = users[i];
              final phone = u['parent_phone'] ?? '';
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                child: ListTile(
                  title: Text(u['full_name'] ?? 'No Name', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Parent: ${u['parent_name'] ?? 'N/A'}\nWhatsApp: $phone"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.call, color: Colors.green), 
                        onPressed: () {
                          if (phone.isNotEmpty) {
                            launchUrl(Uri.parse("tel:$phone"));
                          }
                        }
                      ),
                      Switch(
                        value: u['has_paid'] ?? false, 
                        activeColor: Colors.green, 
                        onChanged: (v) => _togglePayment(u['id'], u['has_paid'] ?? false)
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("ब्रॉडकास्ट मैसेज फ़ीचर जल्द आ रहा है।")),
          );
        },
        label: const Text("Broadcast Message"),
        icon: const Icon(Icons.notification_add),
      ),
    );
  }
}
