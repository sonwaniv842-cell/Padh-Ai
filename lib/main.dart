import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

void main() => runApp(const PadhAiApp());

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
        colorScheme: ColorScheme.fromSeed(
          seedColor: C.primary,
          primary: C.primary,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final FlutterTts _tts = FlutterTts();
  final ImagePicker _picker = ImagePicker();
  late final AnimationController _line;

  bool _scanning = false;
  bool _speaking = false;
  File? _image;
  String _answer = '';
  final List<String> _history = [];

  @override
  void initState() {
    super.initState();
    _line = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage('hi-IN');
      await _tts.setSpeechRate(0.45);
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);
      await _tts.awaitSpeakCompletion(true);
    } catch (_) {}
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _speaking = false);
    });
    _tts.setCancelHandler(() {
      if (mounted) setState(() => _speaking = false);
    });
  }

  @override
  void dispose() {
    _tts.stop();
    _line.dispose();
    super.dispose();
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.all(14),
        ),
      );
  }

  Future<void> _speak(String text) async {
    if (text.trim().isEmpty) return;
    await _tts.stop();
    final clean = text
        .replaceAll(RegExp(r'[•\-\*_#`~]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (mounted) setState(() => _speaking = true);
    await _tts.speak(clean);
    if (mounted) setState(() => _speaking = false);
  }

  Future<void> _stop() async {
    await _tts.stop();
    if (mounted) setState(() => _speaking = false);
  }

  Future<void> _scan(ImageSource source) async {
    await _stop();

    XFile? shot;
    try {
      shot = await _picker.pickImage(
        source: source,
        imageQuality: 88,
        maxWidth: 1600,
      );
    } catch (_) {
      _snack('कैमरा नहीं खुल पाया 😕', Colors.red);
      return;
    }
    if (shot == null) return;

    final path = shot.path;

    setState(() {
      _image = File(path);
      _scanning = true;
      _answer = '';
    });
    _line.repeat(reverse: true);

    String text = '';
    try {
      final recognizer =
          TextRecognizer(script: TextRecognitionScript.devanagiri);
      final result =
          await recognizer.processImage(InputImage.fromFilePath(path));
      text = result.text.trim();
      await recognizer.close();
    } catch (_) {
      text = '';
    }

    if (!mounted) return;
    _line.stop();

    setState(() {
      _scanning = false;
      if (text.isEmpty) {
        _answer = 'कोई टेक्स्ट नहीं मिला 😕\n\n'
            'सुझाव:\n'
            '• अच्छी रोशनी में फोटो लें\n'
            '• किताब को सीधा रखें\n'
            '• थोड़ा पास से फोटो लें';
      } else {
        _answer = text;
        _history.insert(0, text);
        if (_history.length > 30) _history.removeLast();
      }
    });

    if (text.isNotEmpty) _speak(text);
  }

  void _openHistory() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 46,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(18),
              child: Text(
                '🕐  स्कैन इतिहास',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: C.text,
                ),
              ),
            ),
            Expanded(
              child: _history.isEmpty
                  ? const Center(
                      child: Text('अभी कोई इतिहास नहीं है 📭',
                          style: TextStyle(color: C.grey)),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _history.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: C.bg,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                _history[i],
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(height: 1.5),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.volume_up_rounded,
                                  color: C.primary),
                              onPressed: () => _speak(_history[i]),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _header(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
                child: Column(
                  children: [
                    _scanBox(),
                    const SizedBox(height: 16),
                    _buttons(),
                    const SizedBox(height: 22),
                    _result(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 12, 22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [C.primary, C.dark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text('🤖', style: TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Padh-Ai',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.bold)),
                Text('आपका स्मार्ट एआई टीचर 📚',
                    style: TextStyle(color: Colors.white70, fontSize: 12.5)),
              ],
            ),
          ),
          if (_speaking)
            IconButton(
              icon: const Icon(Icons.stop_circle_rounded,
                  color: Colors.white, size: 26),
              onPressed: _stop,
            ),
          IconButton(
            icon: const Icon(Icons.history_rounded,
                color: Colors.white, size: 24),
            onPressed: _openHistory,
          ),
        ],
      ),
    );
  }

  Widget _scanBox() {
    return Container(
      height: 235,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF241C3F), Color(0xFF13102A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x336C4CE0),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_image != null)
              Opacity(
                opacity: 0.5,
                child: Image.file(_image!, fit: BoxFit.cover),
              ),
            _corner(top: 18, left: 18, tl: true),
            _corner(top: 18, right: 18, tr: true),
            _corner(bottom: 18, left: 18, bl: true),
            _corner(bottom: 18, right: 18, br: true),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedScale(
                    scale: _scanning ? 1.12 : 1.0,
                    duration: const Duration(milliseconds: 400),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: const BoxDecoration(
                        color: Color(0x2E00D2A0),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _scanning
                            ? Icons.document_scanner_rounded
                            : Icons.camera_alt_rounded,
                        size: 42,
                        color: C.accent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _scanning
                        ? 'पढ़ा जा रहा है… रुकें'
                        : 'किताब या प्रश्न के सामने\nकैमरा लाएं',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                      shadows: [Shadow(blurRadius: 8, color: Colors.black)],
                    ),
                  ),
                ],
              ),
            ),
            if (_scanning)
              AnimatedBuilder(
                animation: _line,
                builder: (_, __) => Positioned(
                  top: 20 + _line.value * 185,
                  left: 24,
                  right: 24,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: const LinearGradient(
                        colors: [
                          Colors.transparent,
                          C.accent,
                          Colors.transparent
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _corner({
    double? top,
    double? bottom,
    double? left,
    double? right,
    bool tl = false,
    bool tr = false,
    bool bl = false,
    bool br = false,
  }) {
    const side = BorderSide(color: C.accent, width: 3);
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          border: Border(
            top: (tl || tr) ? side : BorderSide.none,
            bottom: (bl || br) ? side : BorderSide.none,
            left: (tl || bl) ? side : BorderSide.none,
            right: (tr || br) ? side : BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buttons() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _scanning ? null : () => _scan(ImageSource.camera),
              icon: _scanning
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                    )
                  : const Icon(Icons.camera_alt_rounded),
              label: Text(
                _scanning ? 'पढ़ रहे हैं…' : 'कैमरा से स्कैन',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: C.accent,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade400,
                elevation: 0,
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
              elevation: 0,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: const Icon(Icons.photo_library_rounded, size: 24),
          ),
        ),
      ],
    );
  }

  Widget _result() {
    if (_answer.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Column(
          children: [
            Text('🔍', style: TextStyle(fontSize: 42)),
            SizedBox(height: 12),
            Text('अभी कुछ स्कैन नहीं किया',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: C.text)),
            SizedBox(height: 6),
            Text('हरे बटन से किताब का फोटो लें',
                style: TextStyle(fontSize: 13, color: C.grey)),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: C.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome_rounded,
                    color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              const Text('AI टीचर का उत्तर',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: C.text)),
            ],
          ),
          const Divider(height: 24),
          SelectableText(
            _answer,
            style: const TextStyle(fontSize: 15.5, height: 1.7, color: C.text),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _speaking ? _stop() : _speak(_answer),
                  icon: Icon(_speaking
                      ? Icons.stop_circle_rounded
                      : Icons.volume_up_rounded),
                  label: Text(_speaking ? 'रोकें' : 'सुनें'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _speaking ? Colors.red : C.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _answer));
                    _snack('📋 कॉपी हो गया!', C.primary);
                  },
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('कॉपी'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: C.grey,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
