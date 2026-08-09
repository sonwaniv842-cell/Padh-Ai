import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:ui';

// --- ग्लोबल सेटिंग्स ---
String globalAppFee = "50";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://tyonurrbwdjqfrmqrgpk.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR5b251cnJid2RqcWZybXFyZ3BrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODYxNzMzODMsImV4cCI6MjEwMTc0OTM4M30.95tDST7gwxemb2w2SS71arWh77omlFf0ezPwkTun2cM',
  );
  runApp(const PadhAIApp());
}

// --- प्रीमियम थीम कलर्स ---
class AppColors {
  static const Color bg = Color(0xFF0F172A); // गहरा इंडिगो
  static const Color cardBg = Color(0xFF1E293B); // हल्का कार्ड कलर
  static const Color accent = Color(0xFF6366F1); // वाइब्रेंट पर्पल
  static const Color success = Color(0xFF10B981); // चमकीला हरा
  static const Color textMain = Colors.white;
  static const Color textSub = Color(0xFF94A3B8);
}

class PadhAIApp extends StatelessWidget {
  const PadhAIApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Padh AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: AppColors.bg,
        primaryColor: AppColors.accent,
      ),
      home: const AuthScreen(),
    );
  }
}

// --- मॉडर्न ग्लास कार्ड डिजाइन ---
class GlassCard extends StatelessWidget {
  final Widget child;
  final Color? glowColor;
  const GlassCard({super.key, required this.child, this.glowColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg.withOpacity(0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: glowColor?.withOpacity(0.3) ?? Colors.white.withOpacity(0.1)),
        boxShadow: [
          if (glowColor != null)
            BoxShadow(color: glowColor!.withOpacity(0.1), blurRadius: 20, spreadRadius: 2)
        ],
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(24), child: child),
    );
  }
}

// --- 1. ऑथेंटिकेशन स्क्रीन (प्रीमियम लुक) ---
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isAdmin = false;
  bool isRegister = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // बैकग्राउंड ग्लो इफेक्ट
          Positioned(top: -100, right: -100, child: _blurCircle(AppColors.accent)),
          Positioned(bottom: -100, left: -100, child: _blurCircle(Colors.blue)),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  _buildHeaderToggle(),
                  const SizedBox(height: 40),
                  _buildLogo(),
                  const SizedBox(height: 16),
                  const Text("Padh AI", style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, letterSpacing: 2)),
                  Text(isAdmin ? "ADMIN CONTROL" : "SMART LEARNING", style: const TextStyle(color: AppColors.textSub, letterSpacing: 1.5)),
                  const SizedBox(height: 50),
                  _buildInputs(),
                  const SizedBox(height: 30),
                  _buildMainButton(),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => setState(() => isRegister = !isRegister),
                    child: Text(isRegister ? "Already have account? Login" : "New student? Register here", style: const TextStyle(color: AppColors.accent)),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _blurCircle(Color color) => Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.15)), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50), child: Container()));

  Widget _buildHeaderToggle() {
    return Align(
      alignment: Alignment.topRight,
      child: ActionChip(
        backgroundColor: isAdmin ? Colors.amber.withOpacity(0.2) : AppColors.accent.withOpacity(0.2),
        side: BorderSide(color: isAdmin ? Colors.amber : AppColors.accent),
        label: Text(isAdmin ? "ADMIN" : "STUDENT", style: TextStyle(color: isAdmin ? Colors.amber : AppColors.accent, fontWeight: FontWeight.bold)),
        onPressed: () => setState(() => isAdmin = !isAdmin),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [AppColors.accent, Colors.blueAccent]), boxShadow: [BoxShadow(color: AppColors.accent.withOpacity(0.5), blurRadius: 20)]),
      child: const Icon(Icons.auto_awesome_rounded, size: 50, color: Colors.white),
    );
  }

  Widget _buildInputs() {
    return Column(
      children: [
        _customField("Email Address", Icons.alternate_email_rounded, _emailController),
        const SizedBox(height: 16),
        _customField("Password", Icons.lock_open_rounded, _passwordController, obscure: true),
      ],
    );
  }

  Widget _customField(String label, IconData icon, TextEditingController ctrl, {bool obscure = false}) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.accent),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: AppColors.accent)),
      ),
    );
  }

  Widget _buildMainButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
        onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen(isAdmin: isAdmin))),
        child: Text(isRegister ? "CREATE ACCOUNT" : "LOGIN", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
    );
  }
}

// --- 2. होम स्क्रीन (डैशबोर्ड - इमेज 3 के स्टाइल में) ---
class HomeScreen extends StatelessWidget {
  final bool isAdmin;
  const HomeScreen({super.key, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isAdmin ? "Admin Dashboard" : "Student Dashboard", style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.logout))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWalletCard(),
            const SizedBox(height: 30),
            const Text("AI Report Card", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildScoreCard(), // 98/100 वाला कार्ड
            const SizedBox(height: 30),
            const Text("Modules", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletCard() {
    return GlassCard(
      glowColor: AppColors.accent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.accent, Colors.blue.shade900])),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isAdmin ? "TOTAL EARNINGS" : "MY WALLET", style: const TextStyle(color: Colors.white70, fontSize: 14)),
                const Text("₹ 1,250.00", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
              ],
            ),
            const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCard() {
    return GlassCard(
      glowColor: AppColors.success,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("WEEKLY AI EVALUATION", style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 12)),
                  SizedBox(height: 8),
                  Text("साप्ताहिक परीक्षा परिणाम", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text("AI द्वारा जाँचित परिणाम लाइव है।", style: TextStyle(color: AppColors.textSub, fontSize: 13)),
                ],
              ),
            ),
            // सर्कुलर स्कोर UI (इमेज 3 की तरह)
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(width: 80, height: 80, child: CircularProgressIndicator(value: 0.98, strokeWidth: 8, color: AppColors.success, backgroundColor: Colors.white10)),
                const Column(
                  children: [
                    Text("98", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.success)),
                    Text("/100", style: TextStyle(fontSize: 10, color: AppColors.textSub)),
                  ],
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _moduleItem("Rewards", Icons.card_giftcard_rounded, Colors.pinkAccent),
        _moduleItem("Math Quiz", Icons.calculate_rounded, Colors.orangeAccent),
        _moduleItem("Pahada", Icons.menu_book_rounded, Colors.tealAccent),
        _moduleItem("AI Help", Icons.psychology_rounded, Colors.amber),
      ],
    );
  }

  Widget _moduleItem(String title, IconData icon, Color color) {
    return GlassCard(
      child: InkWell(
        onTap: () {},
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 30)),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
