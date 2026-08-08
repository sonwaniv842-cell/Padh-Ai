import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_tts/flutter_tts.dart';

// --- CONFIG ---
const supabaseUrl = 'https://tyonurrbwdjqfrmqrgpk.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR5b251cnJid2RqcWZybXFyZ3BrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDAzODU1NzksImV4cCI6MjA1NTk2MTU3OX0.aD4e71Hl74L_B5j65lK2I9w0I2jL0Z828Z458L99I20';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: supabaseUrl, 
    anonKey: supabaseAnonKey,
  );
  runApp(const PadhAIApp());
}

final supabase = Supabase.instance.client;

class PadhAIApp extends StatelessWidget {
  const PadhAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Padh AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0B0E17),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6C4CE0),
          secondary: Color(0xFF00D2A0),
          surface: Color(0xFF131827),
        ),
        cardTheme: CardTheme(
          color: const Color(0xFF131827),
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFF232B42), width: 1),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF192033),
          labelStyle: const TextStyle(color: Color(0xFFA0AEC0)),
          prefixIconColor: const Color(0xFF6C4CE0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF232B42)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF232B42)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF6C4CE0), width: 2),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6C4CE0),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      home: supabase.auth.currentSession == null ? const AuthScreen() : const MainContainer(),
    );
  }
}

// --- 1. AUTH SCREEN WITH FORGOT PASSWORD ---
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

  bool _isSignUp = true;
  bool _isAdminMode = false;
  bool _isLoading = false;

  Future<void> _handleAuth() async {
    final email = _emailController.text.trim();
    final password = _passController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMsg("ईमेल और पासवर्ड ज़रूरी हैं");
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isAdminMode) {
        final res = await supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );

        if (res.user != null && mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const AdminDashboardScreen()));
        }
      } else if (_isSignUp) {
        final res = await supabase.auth.signUp(
          email: email,
          password: password,
        );

        if (res.user != null) {
          final pName = _pNameController.text.trim();
          final pPhone = _pPhoneController.text.trim();

          await supabase.from('profiles').upsert({
            'id': res.user!.id,
            'full_name': _nameController.text.trim().isEmpty ? 'छात्र' : _nameController.text.trim(),
            'parent_name': pName.isEmpty ? 'N/A' : pName,
            'parent_phone': pPhone.isEmpty ? 'N/A' : pPhone,
            'has_paid': false,
            'is_admin': false,
          });
        }
        if (mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const MainContainer()));
        }
      } else {
        await supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );

        if (mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const MainContainer()));
        }
      }
    } catch (e) {
      _showMsg("कनेक्शन सूचना: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showMsg("कृपया पहले अपनी ईमेल आईडी लिखें!");
      return;
    }

    try {
      await supabase.auth.resetPasswordForEmail(email);
      _showMsg("✅ पासवर्ड रीसेट लिंक आपके ईमेल ($email) पर भेज दिया गया है!");
    } catch (e) {
      _showMsg("रीसेट एरर: $e");
    }
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF232B42),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _isAdminMode = !_isAdminMode;
                        _isSignUp = false;
                      });
                    },
                    icon: Icon(_isAdminMode ? Icons.person : Icons.admin_panel_settings, color: const Color(0xFF00D2A0)),
                    label: Text(
                      _isAdminMode ? "स्टूडेंट लॉगिन" : "🔒 Admin Login",
                      style: const TextStyle(color: Color(0xFF00D2A0), fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 10),
              Container(
                width: 85,
                height: 85,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isAdminMode 
                      ? [const Color(0xFFFF5252), const Color(0xFF6C4CE0)]
                      : [const Color(0xFF6C4CE0), const Color(0xFF00D2A0)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: Text(_isAdminMode ? "🔑" : "🤖", style: const TextStyle(fontSize: 42)),
                ),
              ),
              const SizedBox(height: 16),
              Text(_isAdminMode ? "Padh AI Admin" : "Padh AI", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 35),
              if (_isSignUp && !_isAdminMode) ...[
                _buildField(_nameController, "छात्र का नाम (ऐच्छिक)", Icons.person_outline),
                _buildField(_pNameController, "पिता/अभिभावक का नाम (ऑप्शनल)", Icons.family_restroom_outlined),
                _buildField(_pPhoneController, "WhatsApp नंबर (ऑप्शनल)", Icons.phone_android_outlined),
              ],
              _buildField(_emailController, _isAdminMode ? "एडमिन ईमेल" : "ईमेल आईडी", Icons.alternate_email_outlined),
              _buildField(_passController, "पासवर्ड", Icons.lock_outline, isPass: true),
              
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _resetPassword,
                  child: const Text("पासवर्ड भूल गए? (Reset Password)", style: TextStyle(color: Color(0xFFFFD77A), fontSize: 13)),
                ),
              ),
              
              const SizedBox(height: 10),
              _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF00D2A0)))
                  : SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _handleAuth,
                        child: Text(_isAdminMode ? "एडमिन लॉगिन करें 🔓" : (_isSignUp ? "रजिस्टर करें ✨" : "लॉगिन करें 🚀")),
                      ),
                    ),
              if (!_isAdminMode) ...[
                const SizedBox(height: 15),
                TextButton(
                  onPressed: () => setState(() => _isSignUp = !_isSignUp),
                  child: Text(_isSignUp ? "पहले से अकाउंट है? लॉगिन करें" : "नया अकाउंट बनाना है? रजिस्टर करें", style: const TextStyle(color: Color(0xFF00D2A0))),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, {bool isPass = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        obscureText: isPass,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      ),
    );
  }
}

// --- 2. STUDENT DASHBOARD ---
class MainContainer extends StatefulWidget {
  const MainContainer({super.key});

  @override
  State<MainContainer> createState() => _MainContainerState();
}

class _MainContainerState extends State<MainContainer> {
  Map<String, dynamic>? userProfile;
  Map<String, dynamic>? appConfig;
  final FlutterTts flutterTts = FlutterTts();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final profileData = await supabase.from('profiles').select().eq('id', user.id).maybeSingle();
        final configData = await supabase.from('app_config').select().eq('id', 1).maybeSingle();

        setState(() {
          userProfile = profileData;
          appConfig = configData ?? {'test_fee': 50};
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _speakDetailedTerms() async {
    final int fee = appConfig?['test_fee'] ?? 50;
    String speechText = "नमस्ते अभिभावक एवं प्यारे बच्चों। कृपया ध्यान दें। हम पढ़ाई के नाम पर एक रुपया भी फीस नहीं लेते हैं। जो भी पचास रुपये की टेस्ट फीस ली जा रही है, वह शत प्रतिशत आपके ही बच्चों को गिफ्ट और स्कॉलरशिप के रूप में वापस दे दी जाएगी। हम किसी को नकद पैसा नहीं देते, बल्कि सीधे फ्लिपकार्ट का गिफ्ट कार्ड देते हैं, ताकि कोई भी पैसों का गलत इस्तेमाल न कर सके और आपके बच्चे अपनी पसंद का सामान और किताबें ही खरीद सकें। फीस जमा करके एडमिन से अपना टेस्ट अनलॉक करवाएं। धन्यवाद।";
    await flutterTts.setLanguage("hi-IN");
    await flutterTts.speak(speechText);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF6C4CE0))));
    }

    final bool hasPaid = userProfile?['has_paid'] == true;
    final int fee = appConfig?['test_fee'] ?? 50;
    final String? giftUrl = userProfile?['flipkart_gift_url'];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF131827),
        title: const Text("🤖 Padh AI", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFFFF5252)),
            onPressed: () async {
              await supabase.auth.signOut();
              if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const AuthScreen()));
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            if (!hasPaid) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF191F33),
                  border: Border.all(color: const Color(0xFFFF5252), width: 1.5),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFFFF5252).withOpacity(0.2), blurRadius: 15)
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.lock_clock_rounded, color: Color(0xFFFF5252), size: 36),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "एक्सेस लॉक है - फीस लंबित",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFF5252)),
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: Color(0xFF232B42), height: 25),
                    const Text(
                      "📜 जरूरी नियम एवं शर्तें (Terms & Conditions):",
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF00D2A0)),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "1. 💯% पारदर्शी नीति: हम पढ़ाई का ₹1 भी फीस नहीं लेते हैं।\n"
                      "2. 🎁 आपका पैसा, आपके बच्चे का गिफ्ट: जो ₹$fee की फीस ली जा रही है, वह शत-प्रतिशत आपके ही बच्चों को इनाम और स्कॉलरशिप के रूप में मिलेगी।\n"
                      "3. 🛒 नकद (Cash) नहीं, सीधे Flipkart Gift Card: हम पैसों का नकद भुगतान नहीं करते। बच्चों को सीधे Flipkart Gift Card भेजा जाएगा।\n"
                      "4. 🔓 लॉक कैसे खोलें: ₹$fee फीस देकर एडमिन से अपना अकाउंट अनलॉक करवाएं।",
                      style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 13.5, height: 1.6),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00D2A0),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: _speakDetailedTerms,
                        icon: const Icon(Icons.volume_up_rounded, size: 30, color: Colors.black),
                        label: const Text(
                          "🔊 अभिभावक यहाँ दबाकर सुनें",
                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 17),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ] else ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Color(0xFF00D2A0), size: 55),
                      const SizedBox(height: 10),
                      const Text("एग्जाम अनलॉक है ✅", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      const Text("आप स्कॉलरशिप टेस्ट देने के लिए पूरी तरह पात्र हैं।", style: TextStyle(color: Color(0xFFA0AEC0))),
                      if (giftUrl != null && giftUrl.isNotEmpty) ...[
                        const Divider(height: 30, color: Color(0xFF232B42)),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF192033),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFFFD77A)),
                          ),
                          child: Column(
                            children: [
                              const Text("🎁 आपका Flipkart रिवॉर्ड / गिफ्ट कार्ड:", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFFD77A), fontSize: 15)),
                              const SizedBox(height: 10),
                              SelectableText(
                                giftUrl,
                                style: const TextStyle(color: Color(0xFF00D2A0), fontWeight: FontWeight.bold, fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      ]
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// --- 3. ADMIN DASHBOARD ---
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  List<dynamic> _students = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final studentsData = await supabase.from('profiles').select().order('id');
      setState(() {
        _students = studentsData;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleLockStatus(String userId, bool currentPaidStatus) async {
    try {
      await supabase.from('profiles').update({'has_paid': !currentPaidStatus}).eq('id', userId);
      _fetchData();
      _showMsg("छात्र का स्टेटस अपडेट हो गया!");
    } catch (e) {
      _showMsg("एरर: $e");
    }
  }

  Future<void> _updateFlipkartCard(String userId) async {
    final cardController = TextEditingController();
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("🎁 Flipkart Gift Card लिंक/कोड दर्ज करें"),
        content: TextField(
          controller: cardController,
          decoration: const InputDecoration(hintText: "यहाँ Flipkart Voucher/URL डालें"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text("रद्द करें")),
          ElevatedButton(
            onPressed: () async {
              await supabase.from('profiles').update({'flipkart_gift_url': cardController.text.trim()}).eq('id', userId);
              Navigator.pop(c);
              _fetchData();
              _showMsg("गिफ्ट कार्ड भेज दिया गया! 🎁");
            },
            child: const Text("सेव करें"),
          ),
        ],
      ),
    );
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF131827),
        title: const Text("🔒 Admin Control Panel"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFFFF5252)),
            onPressed: () async {
              await supabase.auth.signOut();
              if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const AuthScreen()));
            },
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00D2A0)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _students.length,
              itemBuilder: (context, index) {
                final student = _students[index];
                final bool isPaid = student['has_paid'] == true;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const CircleAvatar(backgroundColor: Color(0xFF6C4CE0), child: Icon(Icons.person, color: Colors.white)),
                          title: Text(student['full_name'] ?? 'अज्ञात छात्र', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("पिता: ${student['parent_name'] ?? 'N/A'}\nफोन: ${student['parent_phone'] ?? 'N/A'}"),
                          trailing: Switch(
                            value: isPaid,
                            activeColor: const Color(0xFF00D2A0),
                            onChanged: (val) => _toggleLockStatus(student['id'], isPaid),
                          ),
                        ),
                        const Divider(color: Color(0xFF232B42)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(isPaid ? "एक्सेस: अनलॉक ✅" : "एक्सेस: लॉक 🔒", style: TextStyle(color: isPaid ? const Color(0xFF00D2A0) : const Color(0xFFFF5252), fontWeight: FontWeight.bold)),
                            TextButton.icon(
                              onPressed: () => _updateFlipkartCard(student['id']),
                              icon: const Icon(Icons.card_giftcard, color: Color(0xFFFFD77A)),
                              label: const Text("Flipkart Card भेजें", style: TextStyle(color: Color(0xFFFFD77A))),
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
