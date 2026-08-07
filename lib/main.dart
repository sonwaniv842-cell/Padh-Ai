import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const PadhAiApp());
}

/// ---------------- रंग (Colors) ----------------
class AppColors {
  static const primary = Color(0xFF6C4CE0);
  static const primaryDark = Color(0xFF4A2FB5);
  static const accent = Color(0xFF00D2A0);
  static const bg = Color(0xFFF4F1FF);
  static const card = Colors.white;
  static const textDark = Color(0xFF231A45);
  static const textGrey = Color(0xFF7A7492);
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
        scaffoldBackgroundColor: AppColors.bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
        ),
        fontFamily: 'Roboto',
      ),
      home: const HomeScreen(),
    );
  }
}

/// ---------------- प्रश्न बैंक ----------------
class QA {
  final String topic;
  final String emoji;
  final String question;
  final String answer;
  final Color color;

  const QA(this.topic, this.emoji, this.question, this.answer, this.color);
}

const List<QA> kQuestionBank = [
  QA('अक्षर', '🍎', "'A' फॉर क्या होता है?",
      "• 'A' फॉर Apple (सेब) होता है!\n• सेब एक स्वादिष्ट और सेहतमंद फल है।\n• स्पेलिंग: A - P - P - L - E",
      Color(0xFFFF6B6B)),
  QA('अक्षर', '⚽', "'B' फॉर क्या होता है?",
      "• 'B' फॉर Ball (गेंद) होता है!\n• गेंद गोल होती है और उससे खेला जाता है।\n• स्पेलिंग: B - A - L - L",
      Color(0xFF4D96FF)),
  QA('अक्षर', '🐱', "'C' फॉर क्या होता है?",
      "• 'C' फॉर Cat (बिल्ली) होता है!\n• बिल्ली म्याऊँ-म्याऊँ करती है।\n• स्पेलिंग: C - A - T",
      Color(0xFFFFA45B)),
  QA('गिनती', '5️⃣', "5 के बाद कौन सी संख्या आती है?",
      "• 5 के बाद 6 आती है।\n• गिनती: 1, 2, 3, 4, 5, 6, 7...\n• 6 को हिंदी में 'छह' कहते हैं।",
      Color(0xFF9B5DE5)),
  QA('गणित', '➕', "7 + 5 = ?",
      "• उत्तर है 12\n• तरीका: 7 में 5 जोड़ें\n• 7 → 8, 9, 10, 11, 12\n• इसलिए 7 + 5 = 12",
      Color(0xFF00BBF9)),
  QA('गणित', '✖️', "6 × 4 = ?",
      "• उत्तर है 24\n• 6 को 4 बार जोड़ें: 6+6+6+6 = 24\n• पहाड़ा: 6×1=6, 6×2=12, 6×3=18, 6×4=24",
      Color(0xFFF15BB5)),
  QA('विज्ञान', '🌞', "सूर्य क्या है?",
      "• सूर्य एक तारा (Star) है।\n• यह हमें रोशनी और गर्मी देता है।\n• सूर्य के बिना धरती पर जीवन संभव नहीं।",
      Color(0xFFFFB703)),
  QA('विज्ञान', '💧', "पानी का सूत्र क्या है?",
      "• पानी का सूत्र H₂O है।\n• इसमें 2 हाइड्रोजन और 1 ऑक्सीजन होता है।\n• पानी जीवन के लिए बहुत ज़रूरी है।",
      Color(0xFF06AED5)),
  QA('हिंदी', '📖', "'क' से कौन सा शब्द बनता है?",
      "• 'क' से कमल बनता है।\n• कमल एक सुंदर फूल है।\n• यह भारत का राष्ट्रीय फूल है।",
      Color(0xFFEF476F)),
  QA('विज्ञान', '🇮🇳', "भारत की राजधानी क्या है?",
      "• भारत की राजधानी नई दिल्ली है।\n• यहाँ संसद भवन और राष्ट्रपति भवन हैं।\n• दिल्ली उत्तर भारत में स्थित है।",
      Color(0xFF118AB2)),
];

/// ---------------- मुख्य स्क्रीन ----------------
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _lineCtrl;
  late AnimationController _fadeCtrl;

  bool _isScanning = false;
  QA? _result;
  String _selectedTopic = 'सभी';
  int _counter = 0;
  final List<QA> _history = [];

  final List<String> _topics = ['सभी', 'अक्षर', 'गिनती', 'गणित', 'विज्ञान', 'हिंदी'];

  @override
  void initState() {
    super.initState();
    _lineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _lineCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _startScan() {
    setState(() {
      _isScanning = true;
      _result = null;
    });
    _lineCtrl.repeat(reverse: true);
    _fadeCtrl.reset();

    Future.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) return;

      final pool = _selectedTopic == 'सभी'
          ? kQuestionBank
          : kQuestionBank.where((q) => q.topic == _selectedTopic).toList();
      final list = pool.isEmpty ? kQuestionBank : pool;
      final qa = list[_counter % list.length];
      _counter++;

      _lineCtrl.stop();
      setState(() {
        _isScanning = false;
        _result = qa;
        _history.insert(0, qa);
      });
      _fadeCtrl.forward();

      _snack('🔊 एआई टीचर बोलकर समझा रहे हैं...', AppColors.accent);
    });
  }

  void _snack(String msg, Color c) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: c,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(14),
        duration: const Duration(seconds: 2),
      ));
  }

  void _openHistory() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
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
              child: Text('🕐  स्कैन इतिहास',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark)),
            ),
            Expanded(
              child: _history.isEmpty
                  ? const Center(
                      child: Text('अभी कोई इतिहास नहीं है 📭',
                          style: TextStyle(color: AppColors.textGrey)))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _history.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final h = _history[i];
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: h.color.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: h.color.withOpacity(0.25)),
                          ),
                          child: Row(
                            children: [
                              Text(h.emoji, style: const TextStyle(fontSize: 26)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(h.question,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textDark)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
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
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopicChips(),
                    const SizedBox(height: 18),
                    _buildScannerBox(),
                    const SizedBox(height: 18),
                    _buildScanButton(),
                    const SizedBox(height: 24),
                    _buildResultSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ---------- हेडर ----------
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
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
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text('🤖', style: TextStyle(fontSize: 26)),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Padh-Ai',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5)),
                Text('आपका स्मार्ट एआई टीचर 📚',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          _circleBtn(Icons.history_rounded, _openHistory),
          const SizedBox(width: 8),
          _circleBtn(Icons.info_outline_rounded, () {
            _snack('Padh-Ai v1.0 — बच्चों के लिए बनाया गया ❤️',
                AppColors.primary);
          }),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.white.withOpacity(0.18),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }

  /// ---------- टॉपिक चिप्स ----------
  Widget _buildTopicChips() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _topics.length,
        separatorBuilder: (_, __) => const SizedBox(width: 9),
        itemBuilder: (_, i) {
          final t = _topics[i];
          final sel = t == _selectedTopic;
          return GestureDetector(
            onTap: () => setState(() => _selectedTopic = t),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: sel
                    ? const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark])
                    : null,
                color: sel ? null : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                    color: sel ? Colors.transparent : Colors.grey.shade300),
                boxShadow: sel
                    ? [
                        BoxShadow(
                            color: AppColors.primary.withOpacity(0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4))
                      ]
                    : null,
              ),
              child: Text(t,
                  style: TextStyle(
                      color: sel ? Colors.white : AppColors.textGrey,
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
            ),
          );
        },
      ),
    );
  }

  /// ---------- स्कैनर बॉक्स ----------
  Widget _buildScannerBox() {
    return Container(
      height: 230,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF241C3F), Color(0xFF13102A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 22,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            // चारों कोने के ब्रैकेट
            _corner(top: 18, left: 18, tl: true),
            _corner(top: 18, right: 18, tr: true),
            _corner(bottom: 18, left: 18, bl: true),
            _corner(bottom: 18, right: 18, br: true),

            // बीच का कंटेंट
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedScale(
                    scale: _isScanning ? 1.15 : 1.0,
                    duration: const Duration(milliseconds: 400),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isScanning
                            ? Icons.document_scanner_rounded
                            : Icons.camera_alt_rounded,
                        size: 44,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _isScanning
                        ? 'स्कैन हो रहा है... कृपया रुकें'
                        : 'किताब या प्रश्न के सामने\nकैमरा लाएं',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // चलती हुई स्कैन लाइन
            if (_isScanning)
              AnimatedBuilder(
                animation: _lineCtrl,
                builder: (_, __) {
                  return Positioned(
                    top: 20 + _lineCtrl.value * 180,
                    left: 24,
                    right: 24,
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        gradient: const LinearGradient(colors: [
                          Colors.transparent,
                          AppColors.accent,
                          Colors.transparent,
                        ]),
                        boxShadow: [
                          BoxShadow(
                              color: AppColors.accent.withOpacity(0.7),
                              blurRadius: 14)
                        ],
                      ),
                    ),
                  );
                },
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
    const c = AppColors.accent;
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
            top: (tl || tr)
                ? const BorderSide(color: c, width: 3)
                : BorderSide.none,
            bottom: (bl || br)
                ? const BorderSide(color: c, width: 3)
                : BorderSide.none,
            left: (tl || bl)
                ? const BorderSide(color: c, width: 3)
                : BorderSide.none,
            right: (tr || br)
                ? const BorderSide(color: c, width: 3)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }

  /// ---------- स्कैन बटन ----------
  Widget _buildScanButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: _isScanning
                ? [Colors.grey.shade400, Colors.grey.shade500]
                : [const Color(0xFF00D2A0), const Color(0xFF00A97F)],
          ),
          boxShadow: _isScanning
              ? null
              : [
                  BoxShadow(
                    color: AppColors.accent.withOpacity(0.45),
                    blurRadius: 16,
                    offset: const Offset(0, 7),
                  )
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: _isScanning ? null : _startScan,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isScanning)
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.6, color: Colors.white),
                    )
                  else
                    const Icon(Icons.qr_code_scanner_rounded,
                        color: Colors.white, size: 25),
                  const SizedBox(width: 12),
                  Text(
                    _isScanning ? 'स्कैन हो रहा है...' : 'प्रश्न स्कैन करें',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// ---------- रिजल्ट ----------
  Widget _buildResultSection() {
    if (_result == null) {
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
            Text('🔍', style: TextStyle(fontSize: 44)),
            SizedBox(height: 14),
            Text('अभी कोई प्रश्न स्कैन नहीं किया गया',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark)),
            SizedBox(height: 6),
            Text('ऊपर हरे बटन को दबाकर शुरू करें!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textGrey)),
          ],
        ),
      );
    }

    final r = _result!;
    return FadeTransition(
      opacity: _fadeCtrl,
      child: SlideTransition(
        position: Tween<Offset>(
                begin: const Offset(0, 0.12), end: Offset.zero)
            .animate(CurvedAnimation(
                parent: _fadeCtrl, curve: Curves.easeOutCubic)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // प्रश्न कार्ड
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 14,
                      offset: const Offset(0, 5))
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: r.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(r.emoji, style: const TextStyle(fontSize: 30)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: r.color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(r.topic,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: r.color)),
                        ),
                        const SizedBox(height: 8),
                        Text(r.question,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                                height: 1.35)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // उत्तर कार्ड
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    r.color.withOpacity(0.10),
                    r.color.withOpacity(0.03),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: r.color.withOpacity(0.3), width: 1.4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: r.color,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.auto_awesome_rounded,
                            color: Colors.white, size: 17),
                      ),
                      const SizedBox(width: 10),
                      const Text('AI टीचर का उत्तर',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(r.answer,
                      style: const TextStyle(
                          fontSize: 15.5,
                          height: 1.75,
                          color: AppColors.textDark)),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _actionBtn(
                          icon: Icons.volume_up_rounded,
                          label: 'सुनें',
                          color: r.color,
                          onTap: () => _snack(
                              '🔊 एआई टीचर बोल रहे हैं...', r.color),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _actionBtn(
                          icon: Icons.copy_rounded,
                          label: 'कॉपी',
                          color: AppColors.textGrey,
                          filled: false,
                          onTap: () {
                            Clipboard.setData(
                                ClipboardData(text: '${r.question}\n\n${r.answer}'));
                            _snack('📋 उत्तर कॉपी हो गया!', AppColors.primary);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool filled = true,
  }) {
    return Material(
      color: filled ? color : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: filled ? null : Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 19, color: filled ? Colors.white : color),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                      color: filled ? Colors.white : color,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}
