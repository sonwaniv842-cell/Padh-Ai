import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// 🔴🔴 यहाँ अपना नंबर डालें (यही एडमिन होगा) 🔴🔴
const List<String> kAdminPhones = [
  '+919999900001',   // टेस्ट नंबर
  '+919826000000',   // ⬅️ अपना असली नंबर यहाँ बदलें
];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const PadhAiApp());
}

/* ─────────────── रंग ─────────────── */
class C {
  static const primary = Color(0xFF6C4CE0);
  static const dark = Color(0xFF4A2FB5);
  static const accent = Color(0xFF00D2A0);
  static const bg = Color(0xFFF4F1FF);
  static const text = Color(0xFF231A45);
  static const grey = Color(0xFF7A7492);
}

class PadhAiApp extends StatelessWidget {
  const PadhAiApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Padh-Ai',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: C.bg,
        colorScheme:
            ColorScheme.fromSeed(seedColor: C.primary, primary: C.primary),
      ),
      home: const AuthGate(),
    );
  }
}

/* ─────────────── मददगार ─────────────── */
String hashPin(String pin) =>
    sha256.convert(utf8.encode('padhai_$pin')).toString();

void snack(BuildContext c, String m, Color col) {
  ScaffoldMessenger.of(c)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(m, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: col,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.all(14),
    ));
}

Widget gradientBg({required Widget child}) => Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [C.primary, C.dark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: child,
    );

/* ─────────────── AUTH GATE ─────────────── */
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        if (snap.data == null) return const LoginScreen();
        return PinGate(user: snap.data!);
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        body: gradientBg(
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('🤖', style: TextStyle(fontSize: 64)),
                SizedBox(height: 16),
                Text('Padh-Ai',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold)),
                SizedBox(height: 24),
                CircularProgressIndicator(color: Colors.white),
              ],
            ),
          ),
        ),
      );
}

/* ─────────────── लॉगिन (फोन + OTP) ─────────────── */
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phone = TextEditingController();
  final _otp = TextEditingController();
  bool _sent = false, _busy = false;
  String? _verId;
  int? _resendToken;

  Future<void> _sendOtp() async {
    final d = _phone.text.trim();
    if (d.length != 10) {
      snack(context, '10 अंकों का सही नंबर डालें', Colors.red);
      return;
    }
    setState(() => _busy = true);
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: '+91$d',
      timeout: const Duration(seconds: 60),
      forceResendingToken: _resendToken,
      verificationCompleted: (cred) async => _signIn(cred),
      verificationFailed: (e) {
        setState(() => _busy = false);
        snack(context, 'गड़बड़: ${e.message}', Colors.red);
      },
      codeSent: (id, token) {
        setState(() {
          _verId = id;
          _resendToken = token;
          _sent = true;
          _busy = false;
        });
        snack(context, '📩 OTP भेज दिया गया', C.accent);
      },
      codeAutoRetrievalTimeout: (id) => _verId = id,
    );
  }

  Future<void> _verify() async {
    if (_otp.text.trim().length < 6) {
      snack(context, '6 अंकों का OTP डालें', Colors.red);
      return;
    }
    setState(() => _busy = true);
    try {
      final cred = PhoneAuthProvider.credential(
          verificationId: _verId!, smsCode: _otp.text.trim());
      await _signIn(cred);
    } catch (e) {
      setState(() => _busy = false);
      snack(context, 'OTP गलत है ❌', Colors.red);
    }
  }

  Future<void> _signIn(PhoneAuthCredential cred) async {
    try {
      final res = await FirebaseAuth.instance.signInWithCredential(cred);
      final u = res.user!;
      final ref = FirebaseFirestore.instance.collection('users').doc(u.uid);
      final snapDoc = await ref.get();
      if (!snapDoc.exists) {
        await ref.set({
          'phone': u.phoneNumber,
          'name': '',
          'role': kAdminPhones.contains(u.phoneNumber) ? 'admin' : 'user',
          'pinHash': null,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
        });
      } else {
        await ref.update({'lastLogin': FieldValue.serverTimestamp()});
      }
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        snack(context, 'लॉगिन नहीं हुआ: $e', Colors.red);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: gradientBg(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              const SizedBox(height: 30),
              const Text('🤖', style: TextStyle(fontSize: 60)),
              const SizedBox(height: 10),
              const Text('Padh-Ai',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold)),
              const Text('आपका स्मार्ट एआई टीचर 📚',
                  style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 34),
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26)),
                child: Column(children: [
                  Text(_sent ? '🔑 OTP डालें' : '📱 मोबाइल नंबर',
                      style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: C.text)),
                  const SizedBox(height: 6),
                  Text(
                      _sent
                          ? '+91 ${_phone.text} पर भेजा गया'
                          : 'OTP से सुरक्षित लॉगिन करें',
                      style: const TextStyle(fontSize: 12.5, color: C.grey)),
                  const SizedBox(height: 20),
                  if (!_sent)
                    TextField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      style: const TextStyle(
                          fontSize: 19, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        prefixText: '+91  ',
                        counterText: '',
                        hintText: '9876543210',
                        filled: true,
                        fillColor: C.bg,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none),
                      ),
                    )
                  else
                    TextField(
                      controller: _otp,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 9),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: '••••••',
                        filled: true,
                        fillColor: C.bg,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none),
                      ),
                    ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _busy ? null : (_sent ? _verify : _sendOtp),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: C.accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _busy
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5))
                          : Text(_sent ? 'सत्यापित करें ✓' : 'OTP भेजें →',
                              style: const TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  if (_sent) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                            onPressed: () => setState(() {
                                  _sent = false;
                                  _otp.clear();
                                }),
                            child: const Text('◀ नंबर बदलें')),
                        TextButton(
                            onPressed: _busy ? null : _sendOtp,
                            child: const Text('OTP दोबारा भेजें')),
                      ],
                    ),
                  ],
                ]),
              ),
              const SizedBox(height: 20),
              const Text('🔒 आपका डेटा पूरी तरह सुरक्षित है',
                  style: TextStyle(color: Colors.white60, fontSize: 12)),
            ]),
          ),
        ),
      ),
    );
  }
}

/* ─────────────── PIN GATE ─────────────── */
class PinGate extends StatefulWidget {
  final User user;
  const PinGate({super.key, required this.user});
  @override
  State<PinGate> createState() => _PinGateState();
}

class _PinGateState extends State<PinGate> {
  bool _unlocked = false;

  @override
  Widget build(BuildContext context) {
    final ref =
        FirebaseFirestore.instance.collection('users').doc(widget.user.uid);
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: ref.snapshots(),
      builder: (_, snap) {
        if (!snap.hasData) return const SplashScreen();
        final data = snap.data!.data();
        if (data == null) return const SplashScreen();

        final pinHash = data['pinHash'];
        final role = (data['role'] ?? 'user') as String;

        if (pinHash == null) {
          return SetPinScreen(uid: widget.user.uid, isReset: false);
        }
        if (!_unlocked) {
          return EnterPinScreen(
            uid: widget.user.uid,
            pinHash: pinHash as String,
            phone: data['phone'] ?? '',
            onOk: () => setState(() => _unlocked = true),
          );
        }
        return HomeScreen(role: role, phone: data['phone'] ?? '');
      },
    );
  }
}

/* ─────────────── PIN बनाएं ─────────────── */
class SetPinScreen extends StatefulWidget {
  final String uid;
  final bool isReset;
  const SetPinScreen({super.key, required this.uid, required this.isReset});
  @override
  State<SetPinScreen> createState() => _SetPinScreenState();
}

class _SetPinScreenState extends State<SetPinScreen> {
  final _p1 = TextEditingController();
  final _p2 = TextEditingController();
  bool _busy = false;

  Future<void> _save() async {
    if (_p1.text.length != 4) {
      snack(context, '4 अंकों का PIN डालें', Colors.red);
      return;
    }
    if (_p1.text != _p2.text) {
      snack(context, 'दोनों PIN अलग हैं ❌', Colors.red);
      return;
    }
    setState(() => _busy = true);
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .update({'pinHash': hashPin(_p1.text)});
    if (!mounted) return;
    snack(context, '✅ PIN सेट हो गया!', C.accent);
    if (widget.isReset) Navigator.of(context).pop();
  }

  Widget _box(TextEditingController c, String h) => TextField(
        controller: c,
        keyboardType: TextInputType.number,
        maxLength: 4,
        obscureText: true,
        textAlign: TextAlign.center,
        style: const TextStyle(
            fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 14),
        decoration: InputDecoration(
          counterText: '',
          hintText: h,
          filled: true,
          fillColor: C.bg,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: gradientBg(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              const SizedBox(height: 40),
              const Text('🔐', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 12),
              Text(widget.isReset ? 'नया PIN बनाएं' : 'अपना PIN बनाएं',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text('हर बार ऐप खोलते समय यही PIN लगेगा',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26)),
                child: Column(children: [
                  _box(_p1, '••••'),
                  const SizedBox(height: 14),
                  _box(_p2, 'दोबारा'),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _busy ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: C.accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _busy
                          ? const CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5)
                          : const Text('PIN सुरक्षित करें ✓',
                              style: TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

/* ─────────────── PIN डालें ─────────────── */
class EnterPinScreen extends StatefulWidget {
  final String uid, pinHash, phone;
  final VoidCallback onOk;
  const EnterPinScreen({
    super.key,
    required this.uid,
    required this.pinHash,
    required this.phone,
    required this.onOk,
  });
  @override
  State<EnterPinScreen> createState() => _EnterPinScreenState();
}

class _EnterPinScreenState extends State<EnterPinScreen> {
  final _pin = TextEditingController();
  int _wrong = 0;

  void _check() {
    if (hashPin(_pin.text) == widget.pinHash) {
      widget.onOk();
    } else {
      setState(() => _wrong++);
      _pin.clear();
      snack(context, 'गलत PIN ❌ ($_wrong बार)', Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: gradientBg(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              const SizedBox(height: 50),
              const Text('🔒', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 12),
              const Text('PIN डालें',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(widget.phone,
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26)),
                child: Column(children: [
                  TextField(
                    controller: _pin,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    obscureText: true,
                    autofocus: true,
                    textAlign: TextAlign.center,
                    onChanged: (v) {
                      if (v.length == 4) _check();
                    },
                    style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 16),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '••••',
                      filled: true,
                      fillColor: C.bg,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    icon: const Icon(Icons.lock_reset_rounded, size: 19),
                    label: const Text('PIN भूल गए? OTP से बदलें'),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => ForgotPinScreen(
                              uid: widget.uid, phone: widget.phone)),
                    ),
                  ),
                  const Divider(height: 26),
                  TextButton.icon(
                    icon: const Icon(Icons.logout_rounded,
                        size: 18, color: Colors.red),
                    label: const Text('दूसरे नंबर से लॉगिन',
                        style: TextStyle(color: Colors.red)),
                    onPressed: () => FirebaseAuth.instance.signOut(),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

/* ─────────────── PIN भूल गए (OTP से) ─────────────── */
class ForgotPinScreen extends StatefulWidget {
  final String uid, phone;
  const ForgotPinScreen({super.key, required this.uid, required this.phone});
  @override
  State<ForgotPinScreen> createState() => _ForgotPinScreenState();
}

class _ForgotPinScreenState extends State<ForgotPinScreen> {
  final _otp = TextEditingController();
  bool _busy = false, _sent = false;
  String? _verId;

  @override
  void initState() {
    super.initState();
    _send();
  }

  Future<void> _send() async {
    setState(() => _busy = true);
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: widget.phone,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (_) {},
      verificationFailed: (e) {
        setState(() => _busy = false);
        snack(context, 'गड़बड़: ${e.message}', Colors.red);
      },
      codeSent: (id, _) {
        setState(() {
          _verId = id;
          _sent = true;
          _busy = false;
        });
        snack(context, '📩 OTP भेज दिया', C.accent);
      },
      codeAutoRetrievalTimeout: (id) => _verId = id,
    );
  }

  Future<void> _verify() async {
    setState(() => _busy = true);
    try {
      final cred = PhoneAuthProvider.credential(
          verificationId: _verId!, smsCode: _otp.text.trim());
      await FirebaseAuth.instance.currentUser!
          .reauthenticateWithCredential(cred);
      if (!mounted) return;
      setState(() => _busy = false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) => SetPinScreen(uid: widget.uid, isReset: true)),
      );
    } catch (e) {
      setState(() => _busy = false);
      snack(context, 'OTP गलत है ❌', Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PIN रीसेट करें'),
        backgroundColor: C.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          const SizedBox(height: 20),
          const Text('🔑', style: TextStyle(fontSize: 54)),
          const SizedBox(height: 14),
          Text('${widget.phone} पर OTP भेजा गया',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: C.grey)),
          const SizedBox(height: 24),
          TextField(
            controller: _otp,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 9),
            decoration: InputDecoration(
              counterText: '',
              hintText: '••••••',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: (_busy || !_sent) ? null : _verify,
              style: ElevatedButton.styleFrom(
                backgroundColor: C.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: _busy
                  ? const CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5)
                  : const Text('सत्यापित करें ✓',
                      style:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ),
          ),
          TextButton(onPressed: _busy ? null : _send, child: const Text('दोबारा भेजें')),
        ]),
      ),
    );
  }
}

/* ─────────────── होम (स्कैनर) ─────────────── */
class HomeScreen extends StatefulWidget {
  final String role, phone;
  const HomeScreen({super.key, required this.role, required this.phone});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  final FlutterTts _tts = FlutterTts();
  final ImagePicker _picker = ImagePicker();
  late AnimationController _line;

  bool _scanning = false, _speaking = false;
  File? _img;
  String _question = '', _answer = '';

  bool get isAdmin => widget.role == 'admin';

  @override
  void initState() {
    super.initState();
    _line = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400));
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage('hi-IN');
      await _tts.setSpeechRate(0.45);
      await _tts.setPitch(1.0);
      await _tts.awaitSpeakCompletion(true);
    } catch (_) {}
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _speaking = false);
    });
  }

  @override
  void dispose() {
    _tts.stop();
    _line.dispose();
    super.dispose();
  }

  Future<void> _speak(String t) async {
    if (t.trim().isEmpty) return;
    await _tts.stop();
    setState(() => _speaking = true);
    await _tts.speak(t.replaceAll(RegExp(r'[•\-\*_#`]'), ' '));
    if (mounted) setState(() => _speaking = false);
  }

  Future<void> _scan(ImageSource src) async {
    await _tts.stop();
    XFile? shot;
    try {
      shot = await _picker.pickImage(
          source: src, imageQuality: 88, maxWidth: 1600);
    } catch (_) {
      snack(context, 'कैमरा नहीं खुला 😕', Colors.red);
      return;
    }
    if (shot == null) return;

    setState(() {
      _img = File(shot!.path);
      _scanning = true;
      _answer = '';
      _question = '';
    });
    _line.repeat(reverse: true);

    String text = '';
    try {
      final rec = TextRecognizer(script: TextRecognitionScript.devanagiri);
      final res = await rec.processImage(InputImage.fromFilePath(shot.path));
      text = res.text.trim();
      await rec.close();
    } catch (_) {}

    if (!mounted) return;
    _line.stop();
    setState(() {
      _scanning = false;
      _question = text.isEmpty ? 'कोई टेक्स्ट नहीं मिला 😕' : '📖 पढ़ा गया';
      _answer = text.isEmpty ? 'कृपया साफ़ रोशनी में दोबारा फोटो लें।' : text;
    });

    if (text.isNotEmpty) {
      _speak(text);
      FirebaseFirestore.instance.collection('scans').add({
        'uid': FirebaseAuth.instance.currentUser!.uid,
        'phone': widget.phone,
        'text': text.length > 500 ? text.substring(0, 500) : text,
        'at': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _drawer(),
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          _header(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
              child: Column(children: [
                _scanBox(),
                const SizedBox(height: 16),
                _buttons(),
                const SizedBox(height: 22),
                _result(),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _drawer() => Drawer(
        child: ListView(padding: EdgeInsets.zero, children: [
          DrawerHeader(
            decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [C.primary, C.dark])),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text('🤖', style: TextStyle(fontSize: 34)),
                  const SizedBox(height: 8),
                  Text(widget.phone,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold)),
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(isAdmin ? '👑 एडमिन' : '🎓 विद्यार्थी',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12)),
                  ),
                ]),
          ),
          if (isAdmin)
            ListTile(
              leading: const Icon(Icons.admin_panel_settings, color: C.primary),
              title: const Text('एडमिन पैनल'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AdminPanel()));
              },
            ),
          ListTile(
            leading: const Icon(Icons.lock_reset, color: C.primary),
            title: const Text('PIN बदलें'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ForgotPinScreen(
                        uid: FirebaseAuth.instance.currentUser!.uid,
                        phone: widget.phone)),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('लॉगआउट', style: TextStyle(color: Colors.red)),
            onTap: () => FirebaseAuth.instance.signOut(),
          ),
        ]),
      );

  Widget _header() => Container(
        padding: const EdgeInsets.fromLTRB(8, 8, 16, 22),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              colors: [C.primary, C.dark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30)),
        ),
        child: Row(children: [
          Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu_rounded, color: Colors.white),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
          const Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Padh-Ai',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  Text('आपका स्मार्ट एआई टीचर 📚',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                ]),
          ),
          if (_speaking)
            IconButton(
              icon: const Icon(Icons.stop_circle, color: Colors.white),
              onPressed: () async {
                await _tts.stop();
                setState(() => _speaking = false);
              },
            ),
        ]),
      );

  Widget _scanBox() => Container(
        height: 230,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF241C3F), Color(0xFF13102A)]),
          borderRadius: BorderRadius.circular(26),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Stack(fit: StackFit.expand, children: [
            if (_img != null)
              Opacity(opacity: .5, child: Image.file(_img!, fit: BoxFit.cover)),
            Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                      color: C.accent.withOpacity(.18),
                      shape: BoxShape.circle),
                  child: Icon(
                      _scanning
                          ? Icons.document_scanner_rounded
                          : Icons.camera_alt_rounded,
                      size: 42,
                      color: C.accent),
                ),
                const SizedBox(height: 14),
                Text(
                    _scanning
                        ? 'पढ़ा जा रहा है…'
                        : 'किताब के सामने कैमरा लाएं',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
              ]),
            ),
            if (_scanning)
              AnimatedBuilder(
                animation: _line,
                builder: (_, __) => Positioned(
                  top: 20 + _line.value * 180,
                  left: 24,
                  right: 24,
                  child: Container(height: 3, color: C.accent),
                ),
              ),
          ]),
        ),
      );

  Widget _buttons() => Row(children: [
        Expanded(
          child: SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _scanning ? null : () => _scan(ImageSource.camera),
              icon: const Icon(Icons.camera_alt_rounded),
              label: Text(_scanning ? 'पढ़ रहे हैं…' : 'कैमरा से स्कैन',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: C.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          height: 56,
          width: 56,
          child: ElevatedButton(
            onPressed: _scanning ? null : () => _scan(ImageSource.gallery),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: C.primary,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
            ),
            child: const Icon(Icons.photo_library_rounded),
          ),
        ),
      ]);

  Widget _result() {
    if (_answer.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        width: double.infinity,
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(22)),
        child: const Column(children: [
          Text('🔍', style: TextStyle(fontSize: 42)),
          SizedBox(height: 12),
          Text('अभी कुछ स्कैन नहीं किया',
              style: TextStyle(fontWeight: FontWeight.bold, color: C.text)),
        ]),
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(22)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_question,
            style: const TextStyle(fontWeight: FontWeight.bold, color: C.text)),
        const Divider(height: 22),
        SelectableText(_answer, style: const TextStyle(height: 1.6)),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _speaking ? _tts.stop() : _speak(_answer),
              icon: Icon(_speaking
                  ? Icons.stop_circle_rounded
                  : Icons.volume_up_rounded),
              label: Text(_speaking ? 'रोकें' : 'सुनें'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _speaking ? Colors.red : C.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _answer));
                snack(context, '📋 कॉपी हो गया', C.primary);
              },
              icon: const Icon(Icons.copy_rounded),
              label: const Text('कॉपी'),
            ),
          ),
        ]),
      ]),
    );
  }
}

/* ─────────────── एडमिन पैनल ─────────────── */
class AdminPanel extends StatelessWidget {
  const AdminPanel({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('👑 एडमिन पैनल'),
        backgroundColor: C.primary,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (_, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data!.docs;
          return ListView(padding: const EdgeInsets.all(16), children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [C.primary, C.dark]),
                  borderRadius: BorderRadius.circular(20)),
              child: Row(children: [
                const Icon(Icons.people, color: Colors.white, size: 34),
                const SizedBox(width: 14),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${docs.length}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold)),
                  const Text('कुल उपयोगकर्ता',
                      style: TextStyle(color: Colors.white70)),
                ]),
              ]),
            ),
            const SizedBox(height: 16),
            ...docs.map((d) {
              final m = d.data();
              final admin = m['role'] == 'admin';
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: admin ? C.primary : C.bg,
                    child: Text(admin ? '👑' : '🎓'),
                  ),
                  title: Text(m['phone'] ?? '-',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(admin ? 'एडमिन' : 'विद्यार्थी'),
                  trailing: Switch(
                    value: admin,
                    activeColor: C.primary,
                    onChanged: (v) => d.reference
                        .update({'role': v ? 'admin' : 'user'}),
                  ),
                ),
              );
            }),
          ]);
        },
      ),
    );
  }
}
