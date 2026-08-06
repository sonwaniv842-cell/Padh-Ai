import 'package:flutter/material.dart';

void main() {
  runApp(const PadhAiApp());
}

class PadhAiApp extends StatelessWidget {
  const PadhAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Padh-Ai',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}

// ==========================================
// 1. लॉगिन स्क्रीन (Login, PIN & OTP Security)
// ==========================================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();

  void _handleLogin() {
    String phone = _phoneController.text.trim();
    String pin = _pinController.text.trim();

    if (phone == "admin" && pin == "1234") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
      );
    } else if (phone.length == 10 && pin.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => StudyLobbyScreen(studentName: "अभिषेक", phone: phone)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('कृपया सही मोबाइल नंबर और पिन दर्ज करें!')),
      );
    }
  }

  void _showForgotPinDialog() {
    final TextEditingController _otpPhoneController = TextEditingController();
    final TextEditingController _otpController = TextEditingController();
    final TextEditingController _newPinController = TextEditingController();
    bool otpSent = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('🔐 पिन रीसेट (OTP Verification)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _otpPhoneController,
                decoration: const InputDecoration(
                  labelText: 'अपना रजिस्टर्ड मोबाइल नंबर',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 10),
              if (otpSent) ...[
                TextField(
                  controller: _otpController,
                  decoration: const InputDecoration(
                    labelText: '6-अंकों का OTP दर्ज करें',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _newPinController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'नया सुरक्षा पिन (PIN)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('रद्द करें'),
            ),
            ElevatedButton(
              onPressed: () {
                if (!otpSent) {
                  if (_otpPhoneController.text.length == 10) {
                    setStateDialog(() {
                      otpSent = true;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('📲 OTP आपके व्हाट्सएप और मोबाइल नंबर पर भेज दिया गया है!')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('कृपया सही 10 अंकों का मोबाइल नंबर दर्ज करें।')),
                    );
                  }
                } else {
                  if (_otpController.text.isNotEmpty && _newPinController.text.isNotEmpty) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('✅ आपका नया पिन सफलतापूर्वक सेट हो गया है! अब नए पिन से लॉगिन करें।')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('कृपया OTP और नया पिन दोनों भरें।')),
                    );
                  }
                }
              },
              child: Text(otpSent ? 'पिन बदलें' : 'OTP भेजें'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Padh-Ai - लॉगिन')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '🎓 Padh-Ai वर्चुअल स्कूल में आपका स्वागत है',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'मोबाइल नंबर या एडमिन आईडी',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _pinController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'सुरक्षा पिन (PIN)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 25),
            ElevatedButton(
              onPressed: _handleLogin,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
              child: const Text('लॉगिन करें', style: TextStyle(fontSize: 18)),
            ),
            TextButton(
              onPressed: _showForgotPinDialog,
              child: const Text('पिन भूल गए? (Forgot PIN / OTP)'),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 2. स्टडी लॉबी स्क्रीन (Prayer, Time-Wish, Jokes & Study Lock)
// ==========================================
class StudyLobbyScreen extends StatefulWidget {
  final String studentName;
  final String phone;

  const StudyLobbyScreen({super.key, required this.studentName, required this.phone});

  @override
  State<StudyLobbyScreen> createState() => _StudyLobbyScreenState();
}

class _StudyLobbyScreenState extends State<StudyLobbyScreen> {
  bool isStudyingLocked = true;
  String aiMessage = "";

  @override
  void initState() {
    super.initState();
    _startClassRoutine();
  }

  void _startClassRoutine() {
    int hour = DateTime.now().hour;
    String greeting = hour < 12 ? "गुड मॉर्निंग" : (hour < 17 ? "गुड आफ्टरनून" : "गुड इवनिंग");
    
    setState(() {
      aiMessage = "🙏 प्रार्थना: 'तुम ही हो बंधु सखा तुम ही...'\n\n"
                  "🤖 AI टीचर: $greeting बच्चों! अरे ${widget.studentName}, कैसे हो?\n"
                  "अरे ${widget.studentName}, खाना-वाना खाया? क्या-क्या खाए? अकेले-अकेले खा लिए, मुझे नहीं खिलाओगे? हा हा हा! 🤣\n\n"
                  "चलो आज नर्सरी से 12वीं तक के मजेदार सफर में पढ़ाई शुरू करते हैं!";
    });
  }

  void _unlockAppWithPin() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('पैरेंट लॉक (Study Lock)'),
        content: const TextField(
          obscureText: true,
          decoration: InputDecoration(labelText: 'पैरेंट पिन दर्ज करें'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                isStudyingLocked = false;
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('🔓 स्टडी लॉक हटा दिया गया है।')),
              );
            },
            child: const Text('अनलॉक करें'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (isStudyingLocked) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('⚠️ स्टडी लॉक चालू है! पढ़ाई छोड़कर बाहर नहीं जा सकते।')),
          );
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Padh-Ai लाइव क्लास (${widget.studentName})'),
          actions: [
            IconButton(
              icon: Icon(isStudyingLocked ? Icons.lock : Icons.lock_open),
              onPressed: _unlockAppWithPin,
              tooltip: 'स्टडी लॉक स्टेटस',
            )
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.security, color: Colors.indigo),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'सुरक्षा मोड एक्टिव है: बच्चा रील या अन्य ऐप नहीं चला सकता।',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.indigo.shade200),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      aiMessage,
                      style: const TextStyle(fontSize: 18, height: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('🎤 लाइव एआई टीचर सुन रहा है... बोलिए!')),
                  );
                },
                icon: const Icon(Icons.mic),
                label: const Text('एआई टीचर से बात करें (Live Voice)'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 3. एडमिन डैशबोर्ड (Wallet, Fee, Emergency & Attendance)
// ==========================================
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  double examFee = 50.0;
  bool membershipEnabled = false;
  int activeStudentsCount = 1000;
  int onlineNowCount = 245;

  void _triggerEmergencyStop() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🚨 इमरजेंसी ब्रेक (Emergency Stop)'),
        content: const Text('क्या आप वाकई सभी लाइव क्लासेस तुरंत रोकना चाहते हैं? बच्चों की स्क्रीन पर इमरजेंसी नोटिफिकेशन चला जाएगा।'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('रद्द करें'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('⚠️ इमरजेंसी नोटिफिकेशन सभी बच्चों को भेज दिया गया: "माफ कीजिए, इमरजेंसी इज रियल..."')),
              );
            },
            child: const Text('इमरजेंसी लागू करें'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🛡️ एडमिन मास्टर कंट्रोल पैनल'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text('कुल एक्टिव बच्चे', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('$activeStudentsCount', style: const TextStyle(fontSize: 22, color: Colors.indigo)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Card(
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text('अभी ऑनलाइन', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('$onlineNowCount', style: const TextStyle(fontSize: 22, color: Colors.green)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _triggerEmergencyStop,
            icon: const Icon(Icons.warning_amber_rounded),
            label: const Text('इमरजेंसी क्लास स्टॉप बटन'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(50),
            ),
          ),
          const Divider(height: 40),
          const Text('💰 फीस और बिज़नेस सेटिंग्स', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          TextField(
            decoration: InputDecoration(
              labelText: 'मासिक परीक्षा फीस (₹)',
              border: const OutlineInputBorder(),
              hintText: examFee.toString(),
            ),
            keyboardType: TextInputType.number,
            onSubmitted: (val) {
              setState(() {
                examFee = double.tryParse(val) ?? 50.0;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('परीक्षा फीस बदलकर ₹$examFee कर दी गई है!')),
              );
            },
          ),
          const SizedBox(height: 10),
          SwitchListTile(
            title: const Text('मेंबरशिप मोड (Membership Mode)'),
            subtitle: const Text('भविष्य के लिए मेंबरशिप चालू/बंद करें'),
            value: membershipEnabled,
            onChanged: (val) {
              setState(() {
                membershipEnabled = val;
              });
            },
          ),
          const Divider(height: 40),
          const Text('📋 छात्र सूची और लॉगिन टाइम-ट्रैकर', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            itemBuilder: (context, index) {
              List<String> sampleStudents = ['अभिषेक', 'राहुल', 'शुभम'];
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(sampleStudents[index]),
                  subtitle: const Text('Login: 10:00 AM | Exit: 11:30 AM (1.5 Hours Studied)'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('${sampleStudents[index]} की प्रोग्रेस'),
                        content: const Text('यह बच्चा रोज नियमित रूप से पढ़ाई कर रहा है। इसके पिछले एग्जाम में A+ ग्रेड आए हैं और डिजिटल मार्कशीट जारी की जा चुकी है।'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('बंद करें'))
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
