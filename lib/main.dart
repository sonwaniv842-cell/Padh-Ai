import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ग्लोबल फीस राशि (एडमिन द्वारा परिवर्तन योग्य)
String globalAppFee = "50";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://tyonurrbwdjqfrmqrgpk.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR5b251cnJid2RqcWZybXFyZ3BrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODYxNzMzODMsImV4cCI6MjEwMTc0OTM4M30.95tDST7gwxemb2w2SS71arWh77omlFf0ezPwkTun2cM',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Padh AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D1117),
        primaryColor: Colors.deepPurpleAccent,
      ),
      home: const AuthScreen(),
    );
  }
}

// --- 1. ऑथेंटिकेशन स्क्रीन (लॉगिन / एडमिन / रजिस्टर / नियम व स्पीकर) ---
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isAdmin = false;
  bool isRegister = false;
  bool termsAccepted = false;

  final _studentNameController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  void _speakTerms() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 6),
        content: Row(
          children: [
            const Icon(Icons.volume_up, color: Colors.amberAccent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '🔊 "अभिभावक ध्यान दें: आपसे लिए जाने वाले ₹$globalAppFee का एक भी रुपया हमारी जेब में नहीं जाता। यह पूरी राशि फ्लिपकार्ट से आपके बच्चे का गिफ्ट और पुरुस्कार खरीदने में लगाई जाती है।"',
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Row(
          children: [
            Icon(Icons.gavel, color: Colors.amberAccent),
            SizedBox(width: 8),
            Text('नियम एवं शर्तें (Terms & Conditions)', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '1. Padh AI में ली जाने वाली ₹$globalAppFee की फीस का ₹1 भी एडमिन या कंपनी की जेब में नहीं जाता।\n\n'
              '2. यह पूरी राशि आपके बच्चे के लिए Flipkart / ऑनलाइन माध्यम से आकर्षक गिफ्ट, मेडल और पुरुस्कार खरीदने में उपयोग की जाती है।\n\n'
              '3. परिणाम घोषित होने के बाद गिफ्ट सीधे छात्र के दिए गए पते पर भेजा जाता है।',
              style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _speakTerms,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade800),
              icon: const Icon(Icons.volume_up, color: Colors.white),
              label: const Text('🔊 बोलकर नियम सुनें (माता-पिता के लिए)', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('समझ गया / समझ गई'),
          )
        ],
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (isRegister && !termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('कृपया नियम व शर्तें स्वीकार करें!')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (isRegister) {
        final response = await Supabase.instance.client.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        if (response.user != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('रजिस्ट्रेशन सफल रहा! 🎉')),
          );
          _navigateToHome();
        }
      } else {
        final response = await Supabase.instance.client.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        if (response.user != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('लॉगिन सफल रहा! 🎉')),
          );
          _navigateToHome();
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = "कनेक्शन सूचना: $e";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen(isAdmin: isAdmin)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      isAdmin = !isAdmin;
                      isRegister = false;
                      _errorMessage = null;
                    });
                  },
                  icon: Icon(
                    isAdmin ? Icons.person : Icons.admin_panel_settings,
                    color: Colors.tealAccent,
                    size: 20,
                  ),
                  label: Text(
                    isAdmin ? 'स्टूडेंट लॉगिन' : 'Admin Login',
                    style: const TextStyle(
                      color: Colors.tealAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Container(
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Image.asset(
                  'assets/padh-ai-logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    decoration: BoxDecoration(
                      color: isAdmin ? Colors.amber.shade700 : Colors.teal.shade400,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Icon(
                      isAdmin ? Icons.key : Icons.smart_toy,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                isAdmin ? 'Padh AI Admin' : 'Padh AI',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 30),

              if (isRegister) ...[
                _buildTextField(_studentNameController, 'छात्र का नाम (ऐच्छिक)', Icons.person_outline),
                const SizedBox(height: 16),
                _buildTextField(_fatherNameController, 'पिता/अभिभावक का नाम (ऑप्शनल)', Icons.family_restroom),
                const SizedBox(height: 16),
                _buildTextField(_whatsappController, 'WhatsApp नंबर (ऑप्शनल)', Icons.phone_android),
                const SizedBox(height: 16),
              ],

              _buildTextField(
                _emailController,
                isAdmin ? 'एडमिन ईमेल' : 'ईमेल आईडी',
                Icons.alternate_email,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                _passwordController,
                'पासवर्ड',
                Icons.lock_outline,
                isPassword: true,
              ),
              const SizedBox(height: 12),

              if (isRegister) ...[
                Row(
                  children: [
                    Checkbox(
                      value: termsAccepted,
                      activeColor: Colors.teal,
                      onChanged: (val) => setState(() => termsAccepted = val ?? false),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: _showTermsDialog,
                        child: Text(
                          'मैं ₹$globalAppFee फ्लिपकार्ट उपहार एवं नियम स्वीकार करता/करती हूँ 📜',
                          style: const TextStyle(color: Colors.tealAccent, fontSize: 12, decoration: TextDecoration.underline),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.volume_up, color: Colors.amberAccent),
                      onPressed: _speakTerms,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: const Text(
                    'पासवर्ड भूल गए? (Reset Password)',
                    style: TextStyle(color: Colors.amber, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              if (!isRegister)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'लॉगिन करें',
                                style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(width: 8),
                              Text('🚀', style: TextStyle(fontSize: 18)),
                            ],
                          ),
                  ),
                ),

              const SizedBox(height: 16),

              if (!isAdmin)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      isRegister = !isRegister;
                      _errorMessage = null;
                    });
                  },
                  child: Text(
                    isRegister ? 'पहले से अकाउंट है? लॉगिन करें' : 'नया अकाउंट बनाना है? रजिस्टर करें',
                    style: const TextStyle(
                      color: Colors.tealAccent,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

              if (isRegister) ...[
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'रजिस्टर करें 📝',
                            style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],

              if (_errorMessage != null) ...[
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        prefixIcon: Icon(icon, color: const Color(0xFF818CF8)),
        filled: true,
        fillColor: const Color(0xFF1E293B),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
        ),
      ),
    );
  }
}

// --- 2. होम स्क्रीन (डैशबोर्ड - एडमिन फीस कंट्रोल, उपहार, स्पीकर, रिजल्ट) ---
class HomeScreen extends StatefulWidget {
  final bool isAdmin;
  const HomeScreen({super.key, required this.isAdmin});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String adminUpiId = "sonwaniv842@okaxis";

  String resultExamTitle = "साप्ताहिक AI मूल्यांकन परीक्षा";
  String topperName = "विशाल कुमार (98/100) - AI द्वारा जाँचित";
  bool isResultPublished = true;
  String announceTimer = "तुरंत घोषित";

  void _speakParentMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 6),
        content: Row(
          children: [
            const Icon(Icons.volume_up, color: Colors.amberAccent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '🔊 "अभिभावक जी, ₹$globalAppFee की फीस पूरी तरह सुरक्षित है। यह पैसा आपके बच्चे के फ्लिपकार्ट गिफ्ट के लिए इस्तेमाल किया जाता है।"'
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openFeeControlDialog() {
    final feeController = TextEditingController(text: globalAppFee);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Row(
          children: [
            Icon(Icons.tune, color: Colors.amberAccent),
            SizedBox(width: 8),
            Text('⚙️ फीस व गिफ्ट राशि सेटअप', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'यहाँ से आप छात्र की फीस राशि बढ़ा या घटा सकते हैं:',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: feeController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'फीस राशि (₹)',
                labelStyle: TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Color(0xFF0F172A),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('रद्द करें', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                globalAppFee = feeController.text.trim();
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('फीस राशि बढ़ाकर/घटाकर ₹$globalAppFee सेट कर दी गई है! 🎉')),
              );
            },
            child: const Text('सेव करें'),
          )
        ],
      ),
    );
  }

  void _openAiResultPublishDialog() {
    final examController = TextEditingController(text: resultExamTitle);
    final topperController = TextEditingController(text: topperName);
    String selectedHours = "0";

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.amberAccent),
              SizedBox(width: 8),
              Text('AI 1-क्लिक रिजल्ट घोषणा', style: TextStyle(color: Colors.white, fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🤖 AI द्वारा उत्तर-पुस्तिकाएं जांच ली गई हैं।', style: TextStyle(color: Colors.tealAccent, fontSize: 13)),
              const SizedBox(height: 12),
              TextField(
                controller: examController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'परीक्षा का नाम', labelStyle: TextStyle(color: Colors.grey)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: topperController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'AI द्वारा घोषित टॉपर', labelStyle: TextStyle(color: Colors.grey)),
              ),
              const SizedBox(height: 16),
              const Text('घोषणा का समय चुनें (Timer):', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButton<String>(
                value: selectedHours,
                dropdownColor: const Color(0xFF0F172A),
                isExpanded: true,
                style: const TextStyle(color: Colors.amberAccent),
                items: const [
                  DropdownMenuItem(value: "0", child: Text("🚀 1-क्लिक (तुरंत लाइव घोषित करें)")),
                  DropdownMenuItem(value: "24", child: Text("⏱️ 24 घंटे में ऑटो-पब्लिश करें")),
                  DropdownMenuItem(value: "48", child: Text("⏱️ 48 घंटे में ऑटो-पब्लिश करें")),
                ],
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedHours = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('रद्द करें', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  resultExamTitle = examController.text.trim();
                  topperName = topperController.text.trim();
                  announceTimer = selectedHours == "0" ? "तुरंत घोषित" : "$selectedHours घंटे का टाइमर लागू";
                  isResultPublished = true;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('AI परिणाम ($announceTimer) सेट हो गया है! 📢🎉')),
                );
              },
              child: const Text('घोषित करें 📢'),
            ),
          ],
        ),
      ),
    );
  }

  void _openQrDialog() {
    final upiController = TextEditingController(text: adminUpiId);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(
          widget.isAdmin ? '🔲 एडमिन UPI QR कंट्रोल' : '💳 एडमिन UPI QR कोड',
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.isAdmin) ...[
              const Text('अपना UPI ID दर्ज करें जो छात्रों को दिखेगा:', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 12),
              TextField(
                controller: upiController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'एडमिन UPI ID',
                  labelStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.qr_code_2, size: 160, color: Colors.black87),
              ),
              const SizedBox(height: 12),
              Text('UPI ID: $adminUpiId', style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _speakParentMessage,
                icon: const Icon(Icons.volume_up, color: Colors.white),
                label: Text('🔊 ₹$globalAppFee का प्रयोग (माता-पिता के लिए बोलें)'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade900),
              )
            ]
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('बंद करें', style: TextStyle(color: Colors.grey)),
          ),
          if (widget.isAdmin)
            ElevatedButton(
              onPressed: () {
                setState(() {
                  adminUpiId = upiController.text.trim();
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('एडमिन UPI QR अपडेट कर दिया गया है! 🎉')),
                );
              },
              child: const Text('सेव करें'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isAdmin ? 'Padh AI - Admin Dashboard' : 'Padh AI - Student Home'),
        backgroundColor: const Color(0xFF1E293B),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Supabase.instance.client.auth.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const AuthScreen()),
              );
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: widget.isAdmin 
                      ? [Colors.amber.shade900, Colors.deepOrange.shade800]
                      : [Colors.deepPurple, Colors.indigo],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.isAdmin ? 'स्वागत है, एडमिन सर! 👋' : 'नमस्ते छात्र! Padh AI में स्वागत है 📚',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      IconButton(
                        icon: const Icon(Icons.volume_up, color: Colors.amberAccent, size: 28),
                        onPressed: _speakParentMessage,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              widget.isAdmin ? Icons.account_balance : Icons.account_balance_wallet,
                              color: Colors.amberAccent,
                              size: 28,
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.isAdmin ? 'Admin Earnings Wallet' : 'Student Wallet',
                                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                                ),
                                const Text(
                                  '₹ 0.00',
                                  style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 20),
                                ),
                              ],
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: _openQrDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.tealAccent.shade700,
                            foregroundColor: Colors.white,
                          ),
                          icon: Icon(widget.isAdmin ? Icons.edit : Icons.qr_code, size: 18),
                          label: Text(widget.isAdmin ? 'QR बदलें' : 'पे करें'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (isResultPublished) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amberAccent.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Colors.amber,
                      child: Icon(Icons.auto_awesome, color: Colors.black),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(resultExamTitle, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber, fontSize: 14)),
                              const Text('LIVE 🔴', style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(topperName, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            const Text(
              'मुख्य फीचर्स (Modules)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 16),

            _buildFeatureCard(
              context,
              title: '🎁 फ्लिपकार्ट उपहार व पुरुस्कार (Transparent ₹$globalAppFee)',
              description: '₹$globalAppFee से मिलने वाले उपहार की ट्रैकिंग व नियम।',
              icon: Icons.card_giftcard,
              color: Colors.pinkAccent,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (c) => AlertDialog(
                    backgroundColor: const Color(0xFF1E293B),
                    title: const Text('🎁 फ्लिपकार्ट उपहार मॉडल', style: TextStyle(color: Colors.white)),
                    content: Text(
                      'आपके ₹$globalAppFee से खरीदा गया गिफ्ट Flipkart / ऑनलाइन के माध्यम से सीधे आपके घर भेजा जाएगा। ₹1 भी एडमिन की जेब में नहीं जाता।',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    actions: [
                      ElevatedButton.icon(
                        onPressed: _speakParentMessage,
                        icon: const Icon(Icons.volume_up),
                        label: const Text('🔊 नियम बोलकर सुनें'),
                      )
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            if (widget.isAdmin) ...[
              _buildFeatureCard(
                context,
                title: '⚙️ फीस व गिफ्ट राशि कंट्रोल (कम/ज्यादा करें)',
                description: 'वर्तमान फीस: ₹$globalAppFee (यहाँ से बदलें)।',
                icon: Icons.tune,
                color: Colors.purpleAccent,
                onTap: _openFeeControlDialog,
              ),
              const SizedBox(height: 16),

              _buildFeatureCard(
                context,
                title: '🤖 AI 1-क्लिक रिजल्ट घोषणा (24h/48h Timer)',
                description: 'AI द्वारा जाँचें गए नतीजों को 1 क्लिक में पब्लिश करें।',
                icon: Icons.auto_awesome_sharp,
                color: Colors.amber,
                onTap: _openAiResultPublishDialog,
              ),
              const SizedBox(height: 16),

              _buildFeatureCard(
                context,
                title: '🔲 एडमिन बारकोड व UPI QR सेटअप',
                description: 'छात्रों के भुगतान के लिए अपना QR कोड अपडेट करें।',
                icon: Icons.qr_code_scanner,
                color: Colors.emerald,
                onTap: _openQrDialog,
              ),
              const SizedBox(height: 16),
            ],

            _buildFeatureCard(
              context,
              title: '📖 डिजिटल पहाड़ा (Interactive)',
              description: '1 से 20 तक का डिजिटल पहाड़ा सीखें।',
              icon: Icons.calculate,
              color: Colors.orangeAccent,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PahadaScreen()),
                );
              },
            ),
            const SizedBox(height: 16),

            _buildFeatureCard(
              context,
              title: '🌐 ऑनलाइन पहाड़ा (Online View)',
              description: 'इंटरनेट के जरिए ऑनलाइन टेबल्स देखें।',
              icon: Icons.language,
              color: Colors.blueAccent,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ऑनलाइन पहाड़ा पेज खुल रहा है...')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      color: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
        subtitle: Text(description, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 18),
        onTap: onTap,
      ),
    );
  }
}

// --- 3. डिजिटल पहाड़ा स्क्रीन ---
class PahadaScreen extends StatefulWidget {
  const PahadaScreen({super.key});

  @override
  State<PahadaScreen> createState() => _PahadaScreenState();
}

class _PahadaScreenState extends State<PahadaScreen> {
  int selectedNumber = 2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$selectedNumber का डिजिटल पहाड़ा'),
        backgroundColor: const Color(0xFF1E293B),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 20,
              itemBuilder: (context, index) {
                int number = index + 1;
                bool isSelected = number == selectedNumber;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedNumber = number;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.deepPurpleAccent : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? Colors.white : Colors.transparent),
                    ),
                    child: Center(
                      child: Text(
                        '$number',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 10,
              itemBuilder: (context, index) {
                int multiplier = index + 1;
                int result = selectedNumber * multiplier;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$selectedNumber  ×  $multiplier',
                        style: const TextStyle(fontSize: 20, color: Colors.tealAccent, fontWeight: FontWeight.bold),
                      ),
                      const Text('=', style: TextStyle(fontSize: 20, color: Colors.white)),
                      Text(
                        '$result',
                        style: const TextStyle(fontSize: 22, color: Colors.amberAccent, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
