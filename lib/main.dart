import 'dart:async';
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
  runApp(const MedReviewApp());
}

class MedReviewApp extends StatelessWidget {
  const MedReviewApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'N.R.R. (ADZU)',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF8f4f5a),
        scaffoldBackgroundColor: const Color(0xFFfff5f7),
        textTheme: GoogleFonts.lexendTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasData) {
            return const MedReviewHome();
          }
          return const AuthScreen();
        },
      ),
    );
  }
}

// --- AUTHENTICATION SCREEN ---
class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLoginMode = true;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  String errorMessage = '';

  Future<void> _submitAuth() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      if (isLoginMode) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFfff5f7),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(30),
              constraints: const BoxConstraints(maxWidth: 480),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFf3e8eb)),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 8))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.local_hospital_rounded, color: Color(0xFF8f4f5a), size: 32),
                      const SizedBox(width: 12),
                      Flexible(child: Text('N.R.R. (ADZU)', style: GoogleFonts.lexend(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF38292d)), overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isLoginMode ? 'Sign in to access your board review hub' : 'Create your student review account',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lexend(fontSize: 13, color: const Color(0xFF8a7378)),
                  ),
                  const SizedBox(height: 30),
                  if (errorMessage.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Text(errorMessage, style: GoogleFonts.lexend(color: Colors.red.shade700, fontSize: 12)),
                    ),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email Address', border: OutlineInputBorder()),
                    style: GoogleFonts.lexend(),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                    style: GoogleFonts.lexend(),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8f4f5a),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: isLoading ? null : _submitAuth,
                    child: isLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(isLoginMode ? 'Sign In' : 'Create Account', style: GoogleFonts.lexend(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        isLoginMode = !isLoginMode;
                        errorMessage = '';
                      });
                    },
                    child: Text(
                      isLoginMode ? 'Don\'t have an account? Sign Up' : 'Already have an account? Sign In',
                      style: GoogleFonts.lexend(color: const Color(0xFF8f4f5a), fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- MAIN REVIEW DASHBOARD & EXAM APP ---
class MedReviewHome extends StatefulWidget {
  const MedReviewHome({Key? key}) : super(key: key);

  @override
  State<MedReviewHome> createState() => _MedReviewHomeState();
}

class _MedReviewHomeState extends State<MedReviewHome> {
  String currentScreen = 'menu';
  String selectedCategoryFilter = 'All';
  String selectedSrsCategoryFilter = 'All';
  
  int currentIndex = 0;
  int score = 0;
  int? selectedOptionIndex;
  List selectedSataIndices = [];
  bool isAnswerLocked = false;
  bool quizFinished = false;
  bool hasScoredCurrentQuestion = false;

  List activeSessionQuestions = [];
  List<String> questionStatuses = [];
  List cachedAllQuestions = [];
  List<String> cachedCategories = ['All'];
  bool isInitialized = false;

  bool soundEnabled = true;
  bool showVisualGifs = true;
  String soundTheme = 'Soft Chime';
  bool activeRecallModeEnabled = false;
  bool isAnswerRevealed = false;
  int selectedQuestionCount = 25;
  
  String selectedTimerMode = 'standard';
  int customTimerMinutes = 45;

  final ValueNotifier<int> remainingSecondsNotifier = ValueNotifier<int>(45 * 60);
  Timer? examTimer;

  bool get isAdmin {
    final user = FirebaseAuth.instance.currentUser;
    return user != null && user.email == 'bhci.indasan@gmail.com';
  }

  final CollectionReference questionsRef =
      FirebaseFirestore.instance.collection('questions');

  @override
  void dispose() {
    examTimer?.cancel();
    remainingSecondsNotifier.dispose();
    super.dispose();
  }

  void _playSound(String type) {
    if (!soundEnabled) return;
    try {
      String soundData = 'UklGRnoGAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YQoGAACBhYqFbF1fdJivrJBhNjVgodDbq2EcHCmS2uHCWxMTCp3H78NdHx0pju3us28kIBwsvd3usmc6IBy93u6zZzoiAcvd7us2c6IBy93u6zZzoiAcvd7us2c6IBy93u6zZzo=';
      final html.AudioElement audio = html.AudioElement('data:audio/wav;base64,$soundData');
      audio.volume = 0.3;
      audio.play();
    } catch (_) {}
  }

  void startTimerConfigured() {
    examTimer?.cancel();
    int totalSecs = 45 * 60;

    if (selectedTimerMode == 'pomodoro') {
      totalSecs = 25 * 60;
    } else if (selectedTimerMode == 'blitz_5') {
      totalSecs = 5 * 60;
    } else if (selectedTimerMode == 'blitz_10') {
      totalSecs = 10 * 60;
    } else if (selectedTimerMode == 'custom') {
      totalSecs = customTimerMinutes * 60;
    } else {
      totalSecs = 45 * 60;
    }

    remainingSecondsNotifier.value = totalSecs;
    examTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSecondsNotifier.value > 0) {
        remainingSecondsNotifier.value--;
      } else {
        timer.cancel();
        _showTimesUpDialog();
      }
    });
  }

  String formatTimer(int seconds) {
    final int mins = seconds ~/ 60;
    final int secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _showTimesUpDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('⏱️ Time\'s Up!', style: GoogleFonts.lexend(fontWeight: FontWeight.bold, color: Colors.red)),
        content: Text('Your allocated review timer has expired.', style: GoogleFonts.lexend()),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8f4f5a)),
            onPressed: () {
              Navigator.pop(context);
              _saveSessionHistory(score, activeSessionQuestions.length, selectedCategoryFilter);
              setState(() {
                quizFinished = true;
              });
            },
            child: const Text('View Results', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _saveSessionHistory(int sessionScore, int totalQuestions, String category) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final double percentage = totalQuestions > 0 ? (sessionScore / totalQuestions) * 100 : 0.0;
    FirebaseFirestore.instance.collection('history').add({
      'userId': user.uid,
      'timestamp': FieldValue.serverTimestamp(),
      'score': sessionScore,
      'total': totalQuestions,
      'percentage': percentage,
      'category': category,
    });
  }

  void _updateSrsProgressInBackground(String docId, bool wasCorrect) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userSrsRef = questionsRef.doc(docId).collection('user_srs').doc(user.uid);
      final docSnap = await userSrsRef.get();
      
      int repetition = 0;
      int intervalDays = 1;

      if (docSnap.exists) {
        final data = docSnap.data() as Map<String, dynamic>;
        repetition = data['srsRepetition'] ?? 0;
        intervalDays = data['srsIntervalDays'] ?? 1;
      }

      if (wasCorrect) {
        repetition++;
        intervalDays = intervalDays * 2;
      } else {
        repetition = 0;
        intervalDays = 1;
      }

      DateTime nextReviewDate = DateTime.now().add(Duration(days: intervalDays));

      userSrsRef.set({
        'srsRepetition': repetition,
        'srsIntervalDays': intervalDays,
        'srsNextReviewDate': Timestamp.fromDate(nextReviewDate),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  void _toggleBookmark(String docId, bool currentStatus) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _playSound('click');
    final userBookmarkRef = questionsRef.doc(docId).collection('user_bookmarks').doc(user.uid);
    
    userBookmarkRef.set({'isBookmarked': !currentStatus}, SetOptions(merge: true));

    setState(() {
      for (var q in cachedAllQuestions) {
        if (q['id'] == docId) {
          q['isBookmarked'] = !currentStatus;
        }
      }
      for (var q in activeSessionQuestions) {
        if (q['id'] == docId) {
          q['isBookmarked'] = !currentStatus;
        }
      }
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(!currentStatus ? '📌 Question bookmarked for your account!' : '📌 Bookmark removed.'),
          duration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  void _showImportDialog(BuildContext context) {
    if (!isAdmin) return;
    final TextEditingController jsonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Paste Chatbot JSON', style: GoogleFonts.lexend(fontWeight: FontWeight.bold, color: const Color(0xFF38292d))),
        content: SizedBox(
          width: 500,
          height: 300,
          child: TextField(
            controller: jsonController,
            maxLines: null,
            expands: true,
            decoration: const InputDecoration(
              hintText: 'Paste your JSON array here (MCQ or SATA A-E)...',
              border: OutlineInputBorder(),
            ),
            style: GoogleFonts.lexend(fontSize: 13),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF8a7378))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8f4f5a)),
            onPressed: () async {
              try {
                final decoded = jsonDecode(jsonController.text) as List;
                final batch = FirebaseFirestore.instance.batch();
                
                for (var item in decoded) {
                  final docRef = questionsRef.doc();
                  Map<String, dynamic> qData = item as Map<String, dynamic>;
                  batch.set(docRef, qData);
                }
                
                await batch.commit();
                Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Successfully imported all questions to Firestore!')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error parsing JSON: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Upload to Firestore', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteQuestion(String docId) async {
    if (!isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Access Denied: Admin only action.')));
      return;
    }

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Question', style: GoogleFonts.lexend(fontWeight: FontWeight.bold)),
        content: Text('Permanently delete this question from Firestore?', style: GoogleFonts.lexend()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await questionsRef.doc(docId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Question deleted.')));
      }
    }
  }

  Future<void> _deleteCategory(String categoryName, List allQuestions) async {
    if (!isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Access Denied: Admin only action.')));
      return;
    }

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Category', style: GoogleFonts.lexend(fontWeight: FontWeight.bold, color: Colors.red)),
        content: Text('Delete category "$categoryName" and ALL its clinical questions permanently?', style: GoogleFonts.lexend()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete Category'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final batch = FirebaseFirestore.instance.batch();
      for (var q in allQuestions) {
        if (q['category'] == categoryName) {
          batch.delete(questionsRef.doc(q['id']));
        }
      }
      await batch.commit();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Category "$categoryName" deleted.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 900 || html.window.navigator.userAgent.contains('Mobi');

        return Scaffold(
          appBar: isMobile
              ? AppBar(
                  backgroundColor: const Color(0xFF38292d),
                  title: Row(
                    children: [
                      const Icon(Icons.local_hospital_rounded, color: Color(0xFFf3e8eb), size: 20),
                      const SizedBox(width: 8),
                      Text('N.R.R. (ADZU)', style: GoogleFonts.lexend(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                  actions: [
                    if (currentScreen == 'exam' || currentScreen == 'srs' || currentScreen == 'bookmarked') ...[
                      ValueListenableBuilder<int>(
                        valueListenable: remainingSecondsNotifier,
                        builder: (context, seconds, child) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text('⏱️ ${formatTimer(seconds)}', style: GoogleFonts.lexend(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.exit_to_app, size: 18),
                        onPressed: () {
                          _playSound('click');
                          examTimer?.cancel();
                          setState(() {
                            currentScreen = 'menu';
                            quizFinished = false;
                          });
                        },
                      ),
                    ],
                  ],
                )
              : null,
          drawer: isMobile ? _buildMobileDrawer() : null,
          body: SafeArea(
            child: RepaintBoundary(
              child: Column(
                children: [
                  if (!isMobile)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [Color(0xFF38292d), Color(0xFF8f4f5a)]),
                        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3))],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.local_hospital_rounded, color: Color(0xFFf3e8eb), size: 24),
                              const SizedBox(width: 12),
                              PopupMenuButton<String>(
                                offset: const Offset(0, 45),
                                color: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                onSelected: (value) async {
                                  if (value == 'menu') {
                                    examTimer?.cancel();
                                    setState(() => currentScreen = 'menu');
                                  } else if (value == 'library') {
                                    examTimer?.cancel();
                                    setState(() => currentScreen = 'library');
                                  } else if (value == 'analytics') {
                                    examTimer?.cancel();
                                    setState(() => currentScreen = 'analytics');
                                  } else if (value == 'settings') {
                                    examTimer?.cancel();
                                    setState(() => currentScreen = 'settings');
                                  } else if (value == 'import') {
                                    _showImportDialog(context);
                                  } else if (value == 'logout') {
                                    await FirebaseAuth.instance.signOut();
                                  }
                                },
                                itemBuilder: (context) => [
                                  PopupMenuItem(value: 'menu', child: Text('🏠 Dashboard Home', style: GoogleFonts.lexend(fontWeight: FontWeight.w500))),
                                  PopupMenuItem(value: 'library', child: Text('📚 Question Library', style: GoogleFonts.lexend(fontWeight: FontWeight.w500))),
                                  PopupMenuItem(value: 'analytics', child: Text('📊 Analytics Dashboard', style: GoogleFonts.lexend(fontWeight: FontWeight.w500))),
                                  PopupMenuItem(value: 'settings', child: Text('⚙️ Settings & Audio', style: GoogleFonts.lexend(fontWeight: FontWeight.w500))),
                                  if (isAdmin) PopupMenuItem(value: 'import', child: Text('☁️ Import Chatbot JSON', style: GoogleFonts.lexend(fontWeight: FontWeight.w500))),
                                  const PopupMenuDivider(),
                                  PopupMenuItem(value: 'logout', child: Text('🚪 Sign Out', style: GoogleFonts.lexend(fontWeight: FontWeight.w500, color: Colors.red))),
                                ],
                                child: Row(
                                  children: [
                                    Text(
                                      'N.R.R. (ADZU)',
                                      style: GoogleFonts.lexend(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18, letterSpacing: 1.2),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(Icons.arrow_drop_down_rounded, color: Colors.white70),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              if (currentScreen == 'exam' || currentScreen == 'srs' || currentScreen == 'bookmarked') ...[
                                ValueListenableBuilder<int>(
                                  valueListenable: remainingSecondsNotifier,
                                  builder: (context, seconds, child) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.white30),
                                      ),
                                      child: Text(
                                        '⏱️ ${formatTimer(seconds)}',
                                        style: GoogleFonts.lexend(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 14),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFe11d48), foregroundColor: Colors.white),
                                  icon: const Icon(Icons.exit_to_app, size: 16),
                                  label: const Text('Exit Session'),
                                  onPressed: () {
                                    _playSound('click');
                                    examTimer?.cancel();
                                    setState(() {
                                      currentScreen = 'menu';
                                      quizFinished = false;
                                    });
                                  },
                                ),
                              ] else ...[
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(color: Colors.white70),
                                  ),
                                  icon: const Icon(Icons.folder_shared_rounded, size: 16),
                                  label: const Text('Question Library'),
                                  onPressed: () {
                                    _playSound('click');
                                    setState(() => currentScreen = 'library');
                                  },
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),

                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: questionsRef.snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting && !isInitialized) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                          return Center(child: Text('Error loading questions: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                        }

                        final docs = snapshot.data?.docs ?? [];

                        cachedAllQuestions = docs.map((d) {
                          final data = d.data() as Map<String, dynamic>;
                          return {
                            'id': d.id,
                            ...data,
                            'isBookmarked': data['isBookmarked'] ?? false,
                            'srsRepetition': data['srsRepetition'] ?? 0,
                            'srsIntervalDays': data['srsIntervalDays'] ?? 1,
                            'srsNextReviewDate': data['srsNextReviewDate'] ?? Timestamp.fromDate(DateTime.now()),
                          };
                        }).toList();

                        cachedCategories = <String>['All', ...cachedAllQuestions.map((q) => q['category']?.toString() ?? 'General').toSet().toList()];
                        isInitialized = true;

                        Widget targetScreen;
                        if (currentScreen == 'menu') {
                          targetScreen = _buildModernDashboard(cachedAllQuestions, cachedCategories, isMobile);
                        } else if (currentScreen == 'library') {
                          targetScreen = _buildLibraryScreen(cachedAllQuestions, cachedCategories, isMobile);
                        } else if (currentScreen == 'analytics') {
                          targetScreen = _buildAnalyticsScreen(isMobile);
                        } else if (currentScreen == 'settings') {
                          targetScreen = _buildSettingsScreen(isMobile);
                        } else {
                          targetScreen = _buildExamScreen(isMobile);
                        }

                        if (isMobile) {
                          return KeyedSubtree(
                            key: ValueKey<String>(currentScreen),
                            child: targetScreen,
                          );
                        }

                        return Row(
                          children: [
                            Container(
                              width: 260,
                              color: Colors.white,
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('NAVIGATION', style: GoogleFonts.lexend(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF8a7378), letterSpacing: 1.2)),
                                  const SizedBox(height: 14),
                                  _sidebarNavItem(Icons.dashboard_rounded, 'Dashboard', 'menu'),
                                  _sidebarNavItem(Icons.library_books_rounded, 'Question Library', 'library'),
                                  _sidebarNavItem(Icons.analytics_rounded, 'Analytics Hub', 'analytics'),
                                  _sidebarNavItem(Icons.settings_rounded, 'Settings & Audio', 'settings'),
                                  const Divider(height: 35),
                                  Text('QUICK STATS', style: GoogleFonts.lexend(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF8a7378), letterSpacing: 1.2)),
                                  const SizedBox(height: 14),
                                  _sidebarStatItem('Total Bank', '${cachedAllQuestions.length} Items'),
                                  _sidebarStatItem('Bookmarked', '${cachedAllQuestions.where((q) => q['isBookmarked'] == true).length} Saved'),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(color: const Color(0xFFfff5f7), borderRadius: BorderRadius.circular(10)),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.verified_user_rounded, color: Color(0xFF8f4f5a), size: 20),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text('Session Active\nStay Signed In', style: GoogleFonts.lexend(fontSize: 11, color: const Color(0xFF38292d), fontWeight: FontWeight.w600)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const VerticalDivider(width: 1, color: Color(0xFFf3e8eb)),
                            Expanded(
                              child: KeyedSubtree(
                                key: ValueKey<String>(currentScreen),
                                child: targetScreen,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileDrawer() {
    return Drawer(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text('N.R.R. (ADZU)', style: GoogleFonts.lexend(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF8f4f5a))),
            const Divider(height: 30),
            ListTile(
              leading: const Icon(Icons.dashboard_rounded, color: Color(0xFF8f4f5a)),
              title: const Text('Dashboard Home'),
              onTap: () {
                Navigator.pop(context);
                setState(() => currentScreen = 'menu');
              },
            ),
            ListTile(
              leading: const Icon(Icons.library_books_rounded, color: Color(0xFF8f4f5a)),
              title: const Text('Question Library'),
              onTap: () {
                Navigator.pop(context);
                setState(() => currentScreen = 'library');
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics_rounded, color: Color(0xFF8f4f5a)),
              title: const Text('Analytics Hub'),
              onTap: () {
                Navigator.pop(context);
                setState(() => currentScreen = 'analytics');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_rounded, color: Color(0xFF8f4f5a)),
              title: const Text('Settings & Audio'),
              onTap: () {
                Navigator.pop(context);
                setState(() => currentScreen = 'settings');
              },
            ),
            if (isAdmin) ...[
              ListTile(
                leading: const Icon(Icons.cloud_upload_rounded, color: Color(0xFF8f4f5a)),
                title: const Text('Import Chatbot JSON'),
                onTap: () {
                  Navigator.pop(context);
                  _showImportDialog(context);
                },
              ),
            ],
            const Divider(height: 30),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                await FirebaseAuth.instance.signOut();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _sidebarNavItem(IconData icon, String label, String screenKey) {
    bool isSelected = currentScreen == screenKey;
    return InkWell(
      onTap: () {
        _playSound('click');
        examTimer?.cancel();
        setState(() => currentScreen = screenKey);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFfdf2f4) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? const Color(0xFF8f4f5a) : const Color(0xFF8a7378), size: 20),
            const SizedBox(width: 12),
            Text(label, style: GoogleFonts.lexend(fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: isSelected ? const Color(0xFF8f4f5a) : const Color(0xFF38292d))),
          ],
        ),
      ),
    );
  }

  Widget _sidebarStatItem(String label, String val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.lexend(fontSize: 12, color: const Color(0xFF8a7378))),
          Text(val, style: GoogleFonts.lexend(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF38292d))),
        ],
      ),
    );
  }

  Widget _buildModernDashboard(List allQuestions, List categories, bool isMobile) {
    final now = DateTime.now();
    
    final srsDueList = allQuestions.where((q) {
      Timestamp? ts = q['srsNextReviewDate'] as Timestamp?;
      bool isDue = ts == null || ts.toDate().isBefore(now) || ts.toDate().isAtSameMomentAs(now);
      if (!isDue) return false;
      if (selectedSrsCategoryFilter != 'All' && q['category'] != selectedSrsCategoryFilter) {
        return false;
      }
      return true;
    }).toList();

    final bookmarkedCount = allQuestions.where((q) => q['isBookmarked'] == true).length;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 18 : 30),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF8f4f5a), Color(0xFF6b3842)]),
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
            ),
            child: isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Welcome to N.R.R. (ADZU) 🩺', style: GoogleFonts.lexend(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 6),
                      Text('No Remedial Reviewer', style: GoogleFonts.lexend(fontSize: 13, color: Colors.white70)),
                      if (isAdmin) ...[
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF8f4f5a)),
                          icon: const Icon(Icons.cloud_upload_rounded),
                          label: const Text('Import Chatbot JSON', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () {
                            _playSound('click');
                            _showImportDialog(context);
                          },
                        ),
                      ],
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Welcome to N.R.R. (ADZU) 🩺', style: GoogleFonts.lexend(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 8),
                          Text('No Remedial Reviewer', style: GoogleFonts.lexend(fontSize: 14, color: Colors.white70)),
                        ],
                      ),
                      if (isAdmin)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF8f4f5a), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
                          icon: const Icon(Icons.cloud_upload_rounded),
                          label: const Text('Import Chatbot JSON', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () {
                            _playSound('click');
                            _showImportDialog(context);
                          },
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 25),
          GridView.count(
            crossAxisCount: isMobile ? 1 : 3,
            crossAxisSpacing: 20,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: isMobile ? 3.5 : 2.8,
            children: [
              _dashboardMetricCard('Total Question Bank', '${allQuestions.length} Items', Icons.dataset_rounded, const Color(0xFF38292d)),
              _dashboardMetricCard('SRS Due Cards', '${srsDueList.length} Due Today', Icons.psychology_rounded, const Color(0xFF9333ea)),
              _dashboardMetricCard('Bookmarked Questions', '$bookmarkedCount Flagged', Icons.bookmark_rounded, Colors.amber.shade800),
            ],
          ),
          const SizedBox(height: 25),
          Container(
            padding: EdgeInsets.all(isMobile ? 16 : 28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFf3e8eb)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🚀 Launch Review Session', style: GoogleFonts.lexend(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF38292d))),
                const SizedBox(height: 16),
                
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: isMobile ? double.infinity : 240,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Card Count per Session:', style: GoogleFonts.lexend(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF8a7378))),
                          const SizedBox(height: 4),
                          DropdownButton<int>(
                            isExpanded: true,
                            value: selectedQuestionCount,
                            items: [10, 25, 50, 100, 9999].map((cnt) {
                              return DropdownMenuItem<int>(
                                value: cnt,
                                child: Text(cnt == 9999 ? 'All Available Items' : '$cnt Items', style: GoogleFonts.lexend(fontSize: 13)),
                              );
                            }).toList(),
                            onChanged: (val) => setState(() => selectedQuestionCount = val!),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: isMobile ? double.infinity : 240,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Timer Mode:', style: GoogleFonts.lexend(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF8a7378))),
                          const SizedBox(height: 4),
                          DropdownButton<String>(
                            isExpanded: true,
                            value: selectedTimerMode,
                            items: const [
                              DropdownMenuItem(value: 'standard', child: Text('Standard (45 mins)', style: TextStyle(fontSize: 13))),
                              DropdownMenuItem(value: 'pomodoro', child: Text('Pomodoro (25 mins)', style: TextStyle(fontSize: 13))),
                              DropdownMenuItem(value: 'blitz_5', child: Text('Blitz Mode (5 mins)', style: TextStyle(fontSize: 13))),
                              DropdownMenuItem(value: 'blitz_10', child: Text('Blitz Mode (10 mins)', style: TextStyle(fontSize: 13))),
                              DropdownMenuItem(value: 'custom', child: Text('Custom Minutes', style: TextStyle(fontSize: 13))),
                            ],
                            onChanged: (val) => setState(() => selectedTimerMode = val!),
                          ),
                        ],
                      ),
                    ),
                    if (selectedTimerMode == 'custom')
                      SizedBox(
                        width: isMobile ? double.infinity : 180,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Custom Minutes:', style: GoogleFonts.lexend(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF8a7378))),
                            const SizedBox(height: 4),
                            TextField(
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                              controller: TextEditingController(text: customTimerMinutes.toString()),
                              onChanged: (val) {
                                customTimerMinutes = int.tryParse(val) ?? 45;
                              },
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: Text('Enable Active Recall Mode (Objective Qs)', style: GoogleFonts.lexend(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF38292d))),
                  subtitle: Text('Hides options behind a recall prompt until revealed', style: GoogleFonts.lexend(fontSize: 11, color: Colors.grey)),
                  value: activeRecallModeEnabled,
                  activeColor: const Color(0xFF8f4f5a),
                  onChanged: (val) => setState(() => activeRecallModeEnabled = val),
                ),
                const Divider(height: 25),

                isMobile
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Subject Filter for Standard Review:', style: GoogleFonts.lexend(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF8a7378))),
                          const SizedBox(height: 6),
                          DropdownButton<String>(
                            isExpanded: true,
                            value: categories.contains(selectedCategoryFilter) ? selectedCategoryFilter : 'All',
                            items: categories.map((cat) {
                              return DropdownMenuItem<String>(value: cat.toString(), child: Text(cat.toString(), style: GoogleFonts.lexend(fontWeight: FontWeight.w500)));
                            }).toList(),
                            onChanged: (val) {
                              _playSound('click');
                              setState(() {
                                selectedCategoryFilter = val!;
                              });
                            },
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Select Subject Filter for Standard Review:', style: GoogleFonts.lexend(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF8a7378))),
                          DropdownButton<String>(
                            value: categories.contains(selectedCategoryFilter) ? selectedCategoryFilter : 'All',
                            items: categories.map((cat) {
                              return DropdownMenuItem<String>(value: cat.toString(), child: Text(cat.toString(), style: GoogleFonts.lexend(fontWeight: FontWeight.w500)));
                            }).toList(),
                            onChanged: (val) {
                              _playSound('click');
                              setState(() {
                                selectedCategoryFilter = val!;
                              });
                            },
                          ),
                        ],
                      ),
                const SizedBox(height: 16),
                isMobile
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Subject Filter for SRS Due Queue:', style: GoogleFonts.lexend(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF9333ea))),
                          const SizedBox(height: 6),
                          DropdownButton<String>(
                            isExpanded: true,
                            value: categories.contains(selectedSrsCategoryFilter) ? selectedSrsCategoryFilter : 'All',
                            items: categories.map((cat) {
                              return DropdownMenuItem<String>(value: cat.toString(), child: Text(cat.toString(), style: GoogleFonts.lexend(fontWeight: FontWeight.w500)));
                            }).toList(),
                            onChanged: (val) {
                              _playSound('click');
                              setState(() {
                                selectedSrsCategoryFilter = val!;
                              });
                            },
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Select Subject Filter for SRS Due Queue:', style: GoogleFonts.lexend(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF9333ea))),
                          DropdownButton<String>(
                            value: categories.contains(selectedSrsCategoryFilter) ? selectedSrsCategoryFilter : 'All',
                            items: categories.map((cat) {
                              return DropdownMenuItem<String>(value: cat.toString(), child: Text(cat.toString(), style: GoogleFonts.lexend(fontWeight: FontWeight.w500)));
                            }).toList(),
                            onChanged: (val) {
                              _playSound('click');
                              setState(() {
                                selectedSrsCategoryFilter = val!;
                              });
                            },
                          ),
                        ],
                      ),
                const SizedBox(height: 22),
                isMobile
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8f4f5a),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: const Text('Start Standard Review', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            onPressed: () {
                              _startStandardReview(allQuestions);
                            },
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF9333ea),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            icon: const Icon(Icons.psychology_rounded),
                            label: Text('Launch SRS (${srsDueList.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            onPressed: () {
                              _startSrsReview(srsDueList);
                            },
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber.shade800,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            icon: const Icon(Icons.bookmark_rounded),
                            label: const Text('Review Bookmarks', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            onPressed: () {
                              _startBookmarkReview(allQuestions);
                            },
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8f4f5a),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 18),
                              ),
                              icon: const Icon(Icons.play_arrow_rounded),
                              label: const Text('Start Standard Review', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              onPressed: () {
                                _startStandardReview(allQuestions);
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF9333ea),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 18),
                              ),
                              icon: const Icon(Icons.psychology_rounded),
                              label: Text('Launch SRS (${srsDueList.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              onPressed: () {
                                _startSrsReview(srsDueList);
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber.shade800,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 18),
                              ),
                              icon: const Icon(Icons.bookmark_rounded),
                              label: const Text('Review Bookmarks', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              onPressed: () {
                                _startBookmarkReview(allQuestions);
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
    );
  }

  void _startStandardReview(List allQuestions) {
    _playSound('click');
    setState(() {
      var filtered = selectedCategoryFilter == 'All'
          ? List.from(allQuestions)
          : allQuestions.where((q) => q['category'] == selectedCategoryFilter).toList();
      
      filtered.shuffle();
      activeSessionQuestions = filtered.take(selectedQuestionCount).toList();

      if (activeSessionQuestions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No questions found for this category.')));
        return;
      }
      
      currentScreen = 'exam';
      currentIndex = 0;
      score = 0;
      selectedOptionIndex = null;
      selectedSataIndices.clear();
      isAnswerLocked = false;
      hasScoredCurrentQuestion = false;
      quizFinished = false;
      isAnswerRevealed = false;
      questionStatuses = List.filled(activeSessionQuestions.length, 'unvisited');
    });
    startTimerConfigured();
  }

  void _startSrsReview(List srsDueList) {
    _playSound('click');
    setState(() {
      var filtered = List.from(srsDueList);
      filtered.shuffle();
      activeSessionQuestions = filtered.take(selectedQuestionCount).toList();

      if (activeSessionQuestions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No Spaced Repetition items due for this category right now!')));
        return;
      }

      currentScreen = 'srs';
      currentIndex = 0;
      score = 0;
      selectedOptionIndex = null;
      selectedSataIndices.clear();
      isAnswerLocked = false;
      hasScoredCurrentQuestion = false;
      quizFinished = false;
      isAnswerRevealed = false;
      questionStatuses = List.filled(activeSessionQuestions.length, 'unvisited');
    });
    startTimerConfigured();
  }

  void _startBookmarkReview(List allQuestions) {
    _playSound('click');
    setState(() {
      var filtered = allQuestions.where((q) => q['isBookmarked'] == true).toList();
      filtered.shuffle();
      activeSessionQuestions = filtered.take(selectedQuestionCount).toList();

      if (activeSessionQuestions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No bookmarked questions saved yet!')));
        return;
      }

      currentScreen = 'bookmarked';
      currentIndex = 0;
      score = 0;
      selectedOptionIndex = null;
      selectedSataIndices.clear();
      isAnswerLocked = false;
      hasScoredCurrentQuestion = false;
      quizFinished = false;
      isAnswerRevealed = false;
      questionStatuses = List.filled(activeSessionQuestions.length, 'unvisited');
    });
    startTimerConfigured();
  }

  Widget _dashboardMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFf3e8eb)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title.toUpperCase(), style: GoogleFonts.lexend(fontSize: 10, color: const Color(0xFF8a7378), fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(value, style: GoogleFonts.lexend(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF38292d))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsScreen(bool isMobile) {
    return Padding(
      padding: EdgeInsets.all(isMobile ? 16 : 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('⚙️ Settings & Preferences', style: GoogleFonts.lexend(fontSize: isMobile ? 18 : 22, fontWeight: FontWeight.bold, color: const Color(0xFF38292d))),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8f4f5a), foregroundColor: Colors.white),
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                label: const Text('Back'),
                onPressed: () {
                  _playSound('click');
                  setState(() => currentScreen = 'menu');
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFf3e8eb)),
              ),
              child: ListView(
                children: [
                  SwitchListTile(
                    title: Text('Enable Sound Effects', style: GoogleFonts.lexend(fontWeight: FontWeight.w600)),
                    subtitle: Text('Play audio feedback on answers and button taps', style: GoogleFonts.lexend(fontSize: 12, color: Colors.grey)),
                    value: soundEnabled,
                    activeColor: const Color(0xFF8f4f5a),
                    onChanged: (val) => setState(() => soundEnabled = val),
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: Text('Show Celebration Visual GIFs', style: GoogleFonts.lexend(fontWeight: FontWeight.w600)),
                    subtitle: Text('Display visual effects on correct answers', style: GoogleFonts.lexend(fontSize: 12, color: Colors.grey)),
                    value: showVisualGifs,
                    activeColor: const Color(0xFF8f4f5a),
                    onChanged: (val) => setState(() => showVisualGifs = val),
                  ),
                  const Divider(),
                  ListTile(
                    title: Text('Audio Theme', style: GoogleFonts.lexend(fontWeight: FontWeight.w600)),
                    subtitle: Text('Choose your preferred feedback audio style', style: GoogleFonts.lexend(fontSize: 12, color: Colors.grey)),
                    trailing: DropdownButton<String>(
                      value: soundTheme,
                      items: ['Soft Chime', 'Modern Pop', 'Subtle Click'].map((theme) {
                        return DropdownMenuItem(value: theme, child: Text(theme, style: GoogleFonts.lexend(fontSize: 13)));
                      }).toList(),
                      onChanged: (val) {
                        setState(() => soundTheme = val!);
                        _playSound('click');
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLibraryScreen(List allQuestions, List categories, bool isMobile) {
    return Padding(
      padding: EdgeInsets.all(isMobile ? 16 : 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text('📚 Question Library (${allQuestions.length} items)', style: GoogleFonts.lexend(fontSize: isMobile ? 18 : 22, fontWeight: FontWeight.bold, color: const Color(0xFF38292d)), overflow: TextOverflow.ellipsis),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8f4f5a), foregroundColor: Colors.white),
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                label: const Text('Back'),
                onPressed: () {
                  _playSound('click');
                  setState(() => currentScreen = 'menu');
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFf3e8eb)),
              ),
              child: ListView.builder(
                itemCount: categories.length - 1,
                itemBuilder: (context, index) {
                  String catName = categories[index + 1];
                  List catQuestions = allQuestions.where((q) => q['category'] == catName).toList();

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 1,
                    child: ExpansionTile(
                      title: Text('$catName (${catQuestions.length} questions)', style: GoogleFonts.lexend(fontWeight: FontWeight.bold, color: const Color(0xFF38292d), fontSize: 14)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isAdmin)
                            IconButton(
                              icon: const Icon(Icons.delete_sweep_rounded, color: Colors.red, size: 20),
                              tooltip: 'Delete Entire Category',
                              onPressed: () => _deleteCategory(catName, allQuestions),
                            ),
                          const Icon(Icons.expand_more_rounded),
                        ],
                      ),
                      children: catQuestions.map((q) {
                        bool isBookmarked = q['isBookmarked'] == true;
                        return ListTile(
                          leading: Icon(isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, color: Colors.amber.shade800, size: 20),
                          title: Text(q['questionText'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.lexend(fontSize: 13, fontWeight: FontWeight.w500)),
                          subtitle: Text('Type: ${q['type'] ?? 'MCQ'}', style: GoogleFonts.lexend(fontSize: 11, color: Colors.grey[600])),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_border, color: Colors.amber.shade800, size: 20),
                                tooltip: 'Toggle Bookmark',
                                onPressed: () => _toggleBookmark(q['id'], isBookmarked),
                              ),
                              if (isAdmin)
                                IconButton(
                                  icon: const Icon(Icons.delete_rounded, color: Colors.red, size: 18),
                                  onPressed: () => _deleteQuestion(q['id']),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

	  Widget _buildAnalyticsScreen(bool isMobile) {
	  final currentUser = FirebaseAuth.instance.currentUser;

	  return Padding(
		padding: EdgeInsets.all(isMobile ? 16 : 30),
		child: Column(
		  crossAxisAlignment: CrossAxisAlignment.start,
		  children: [
			Row(
			  mainAxisAlignment: MainAxisAlignment.spaceBetween,
			  children: [
				Expanded(
				  child: Text('📊 Performance Progression', style: GoogleFonts.lexend(fontSize: isMobile ? 18 : 22, fontWeight: FontWeight.bold, color: const Color(0xFF38292d)), overflow: TextOverflow.ellipsis),
				),
				ElevatedButton.icon(
				  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8f4f5a), foregroundColor: Colors.white),
				  icon: const Icon(Icons.arrow_back_rounded, size: 16),
				  label: const Text('Back'),
				  onPressed: () {
					_playSound('click');
					setState(() => currentScreen = 'menu');
				  },
				),
			  ],
			),
			const SizedBox(height: 20),
			Expanded(
			  child: StreamBuilder<QuerySnapshot>(
				// Fetch all history documents and filter client-side to prevent missing index or field mismatches
				stream: FirebaseFirestore.instance.collection('history').snapshots(),
				builder: (context, snapshot) {
				  if (snapshot.connectionState == ConnectionState.waiting) {
					return const Center(child: CircularProgressIndicator());
				  }

				  final allDocs = snapshot.data?.docs ?? [];
				  
				  // Filter for current user, or show all if testing locally and fields were mismatched
				  final docs = allDocs.where((d) {
					final data = d.data() as Map<String, dynamic>;
					return data['userId'] == null || data['userId'] == currentUser?.uid;
				  }).toList();

				  if (docs.isEmpty) {
					return Center(
					  child: Text('No historical session data recorded for this account yet. Complete a review session to track progress!', 
						style: GoogleFonts.lexend(fontSize: 14, color: const Color(0xFF8a7378)),
						textAlign: TextAlign.center,
					  ),
					);
				  }

				  final sortedDocs = List.from(docs);
				  sortedDocs.sort((a, b) {
					Timestamp? tA = (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
					Timestamp? tB = (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
					if (tA == null || tB == null) return 0;
					return tB.compareTo(tA);
				  });

				  double totalPercentageSum = 0;
				  for (var doc in sortedDocs) {
					final data = doc.data() as Map<String, dynamic>;
					totalPercentageSum += (data['percentage'] ?? 0.0).toDouble();
				  }
				  double overallAverage = totalPercentageSum / sortedDocs.length;

				  return ListView(
					children: [
					  Container(
						padding: const EdgeInsets.all(20),
						decoration: BoxDecoration(
						  color: Colors.white,
						  borderRadius: BorderRadius.circular(14),
						  border: Border.all(color: const Color(0xFFf3e8eb)),
						),
						child: Row(
						  mainAxisAlignment: MainAxisAlignment.spaceAround,
						  children: [
							_analyticsSummaryItem('Total Sessions', '${sortedDocs.length}'),
							_analyticsSummaryItem('Overall Average', '${overallAverage.toStringAsFixed(1)}%'),
						  ],
						),
					  ),
					  const SizedBox(height: 25),
					  Text('Past Session Logs', style: GoogleFonts.lexend(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF38292d))),
					  const SizedBox(height: 14),
					  ...sortedDocs.map((doc) {
						final data = doc.data() as Map<String, dynamic>;
						Timestamp? ts = data['timestamp'] as Timestamp?;
						String dateStr = ts != null ? ts.toDate().toString().substring(0, 16) : 'Just now';
						double pct = (data['percentage'] ?? 0.0).toDouble();

						return Container(
						  margin: const EdgeInsets.only(bottom: 12),
						  padding: const EdgeInsets.all(16),
						  decoration: BoxDecoration(
							color: Colors.white,
							borderRadius: BorderRadius.circular(14),
							border: Border.all(color: const Color(0xFFf3e8eb)),
						  ),
						  child: Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
							  Row(
								mainAxisAlignment: MainAxisAlignment.spaceBetween,
								children: [
								  Expanded(
									child: Text('Subject: ${data['category'] ?? 'General'}', style: GoogleFonts.lexend(fontWeight: FontWeight.bold, color: const Color(0xFF38292d)), overflow: TextOverflow.ellipsis),
								  ),
								  Container(
									padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
									decoration: BoxDecoration(
									  color: pct >= 75 ? const Color(0xFFecfdf5) : const Color(0xFFfef2f2),
									  borderRadius: BorderRadius.circular(8),
									),
									child: Text('${pct.toStringAsFixed(1)}%', style: GoogleFonts.lexend(fontWeight: FontWeight.bold, color: pct >= 75 ? const Color(0xFF065f46) : const Color(0xFF991b1b))),
								  ),
								],
							  ),
							  const SizedBox(height: 6),
							  Row(
								mainAxisAlignment: MainAxisAlignment.spaceBetween,
								children: [
								  Text('Completed: $dateStr', style: GoogleFonts.lexend(fontSize: 11, color: const Color(0xFF8a7378))),
								  Text('Score: ${data['score'] ?? 0}/${data['total'] ?? 0}', style: GoogleFonts.lexend(fontSize: 12, fontWeight: FontWeight.w600)),
								],
							  ),
							],
						  ),
						);
					  }).toList(),
					],
				  );
				},
			  ),
			),
		  ],
		),
	  );
	}

  Widget _analyticsSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(label.toUpperCase(), style: GoogleFonts.lexend(fontSize: 11, color: const Color(0xFF8a7378), fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(value, style: GoogleFonts.lexend(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF8f4f5a))),
      ],
    );
  }

  Widget _buildExamScreen(bool isMobile) {
    if (activeSessionQuestions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('No questions in current session.', style: GoogleFonts.lexend(fontSize: 16)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => setState(() => currentScreen = 'menu'),
              child: const Text('Return to Menu'),
            ),
          ],
        ),
      );
    }

    if (quizFinished) {
      return _buildResultsScreen(activeSessionQuestions.length);
    }

    final currentQ = activeSessionQuestions[currentIndex];
    final options = currentQ['options'] ?? [];
    final String qType = (currentQ['type'] ?? 'MCQ').toString().toUpperCase();
    final String docId = currentQ['id'] ?? '';
    final bool isBookmarked = currentQ['isBookmarked'] == true;

    Widget questionContent = Container(
      padding: EdgeInsets.all(isMobile ? 16 : 30),
      color: Colors.white,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Question ${currentIndex + 1}', style: GoogleFonts.lexend(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF38292d))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: qType == 'SATA' ? const Color(0xFF9333ea) : const Color(0xFF8f4f5a), 
                    borderRadius: BorderRadius.circular(4)
                  ),
                  child: Text(qType, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFfff5f7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFf3e8eb)),
              ),
              child: Text(
                currentQ['questionText'] ?? '',
                style: GoogleFonts.lexend(fontSize: 15, height: 1.5, color: const Color(0xFF4a383d)),
              ),
            ),
          ],
        ),
      ),
    );

    Widget optionsContent = Container(
      padding: EdgeInsets.all(isMobile ? 16 : 30),
      color: const Color(0xFFfffcfd),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              qType == 'SATA' ? 'SELECT ALL THAT APPLY (A TO E):' : 'SELECT THE BEST OPTION (A TO E):', 
              style: GoogleFonts.lexend(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF8a7378))
            ),
            const SizedBox(height: 14),

            if (activeRecallModeEnabled && (qType == 'MCQ' || qType == 'SATA') && !isAnswerRevealed && !isAnswerLocked) ...[
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFf3e8eb),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFd9c2c7)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.psychology_outlined, size: 36, color: Color(0xFF8f4f5a)),
                    const SizedBox(height: 8),
                    Text('Active Recall Mode Active', style: GoogleFonts.lexend(fontWeight: FontWeight.bold, color: const Color(0xFF8f4f5a))),
                    const SizedBox(height: 4),
                    Text('Think through your answer before revealing options.', style: GoogleFonts.lexend(fontSize: 12, color: Colors.grey[700]), textAlign: TextAlign.center),
                    const SizedBox(height: 14),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8f4f5a), foregroundColor: Colors.white),
                      onPressed: () => setState(() => isAnswerRevealed = true),
                      child: const Text('Reveal Options'),
                    ),
                  ],
                ),
              ),
            ] else ...[
              ...List.generate(options.length, (index) {
                final option = options[index];
                final bool isCorrect = option['isCorrect'] ?? false;
                Color optBg = Colors.white;
                Color optBorder = const Color(0xFFf3e8eb);
                Color optText = const Color(0xFF38292d);

                if (qType == 'MCQ') {
                  if (isAnswerLocked) {
                    if (isCorrect) {
                      optBg = const Color(0xFFecfdf5);
                      optBorder = const Color(0xFF10b981);
                      optText = const Color(0xFF065f46);
                    } else if (selectedOptionIndex == index) {
                      optBg = const Color(0xFFfef2f2);
                      optBorder = const Color(0xFFef4444);
                      optText = const Color(0xFF991b1b);
                    }
                  } else if (selectedOptionIndex == index) {
                    optBg = const Color(0xFFfdf2f4);
                    optBorder = const Color(0xFF8f4f5a);
                  }
                } else {
                  if (isAnswerLocked) {
                    if (isCorrect) {
                      optBg = const Color(0xFFecfdf5);
                      optBorder = const Color(0xFF10b981);
                      optText = const Color(0xFF065f46);
                    } else if (selectedSataIndices.contains(index)) {
                      optBg = const Color(0xFFfef2f2);
                      optBorder = const Color(0xFFef4444);
                      optText = const Color(0xFF991b1b);
                    }
                  } else if (selectedSataIndices.contains(index)) {
                    optBg = const Color(0xFFfdf2f4);
                    optBorder = const Color(0xFF8f4f5a);
                  }
                }

                return InkWell(
                  onTap: isAnswerLocked ? null : () {
                    _playSound('click');
                    setState(() {
                      if (qType == 'MCQ') {
                        selectedOptionIndex = index;
                        isAnswerLocked = true;
                        questionStatuses[currentIndex] = 'answered';
                        
                        if (!hasScoredCurrentQuestion) {
                          if (isCorrect) {
                            score++;
                            _playSound('correct');
                            if (currentScreen == 'srs') _updateSrsProgressInBackground(docId, true);
                          } else {
                            _playSound('incorrect');
                            if (currentScreen == 'srs') _updateSrsProgressInBackground(docId, false);
                          }
                          hasScoredCurrentQuestion = true;
                        }

                        if (currentScreen == 'bookmarked' && isBookmarked) {
                          _showBookmarkPrompt(docId);
                        }
                      } else {
                        if (selectedSataIndices.contains(index)) {
                          selectedSataIndices.remove(index);
                        } else {
                          selectedSataIndices.add(index);
                        }
                      }
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: optBg,
                      border: Border.all(color: optBorder, width: (selectedOptionIndex == index || selectedSataIndices.contains(index) || (isAnswerLocked && isCorrect)) ? 2 : 1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        if (qType == 'SATA') ...[
                          Checkbox(
                            value: selectedSataIndices.contains(index),
                            onChanged: isAnswerLocked ? null : (val) {
                              _playSound('click');
                              setState(() {
                                if (val == true) {
                                  selectedSataIndices.add(index);
                                } else {
                                  selectedSataIndices.remove(index);
                                }
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Text(
                            option['text'] ?? '', 
                            style: GoogleFonts.lexend(fontSize: 13, color: optText, fontWeight: (selectedOptionIndex == index || selectedSataIndices.contains(index)) ? FontWeight.w600 : FontWeight.normal)
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],

            if (qType == 'SATA' && !isAnswerLocked) ...[
              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9333ea),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: selectedSataIndices.isEmpty ? null : () {
                  _playSound('click');
                  setState(() {
                    isAnswerLocked = true;
                    questionStatuses[currentIndex] = 'answered';
                    List correctIndices = [];
                    for (int i = 0; i < options.length; i++) {
                      if (options[i]['isCorrect'] == true) correctIndices.add(i);
                    }
                    
                    bool isExactMatch = correctIndices.length == selectedSataIndices.length &&
                        correctIndices.every((element) => selectedSataIndices.contains(element));
                    
                    if (!hasScoredCurrentQuestion) {
                      if (isExactMatch) {
                        score++;
                        _playSound('correct');
                        if (currentScreen == 'srs') _updateSrsProgressInBackground(docId, true);
                      } else {
                        _playSound('incorrect');
                        if (currentScreen == 'srs') _updateSrsProgressInBackground(docId, false);
                      }
                      hasScoredCurrentQuestion = true;
                    }

                    if (currentScreen == 'bookmarked' && isBookmarked) {
                      _showBookmarkPrompt(docId);
                    }
                  });
                },
                child: const Text('Submit Selected Answers', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],

            if (isAnswerLocked) ...[
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFf3e8eb)),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 2))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (currentQ['quickGuide'] != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFfff1f2),
                          border: Border.all(color: const Color(0xFFfecdd3)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(currentQ['quickGuide'], style: GoogleFonts.lexend(fontSize: 13, color: const Color(0xFF9f1239), fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(height: 16),
                    ],
                    _rationaleSection('1. What (Pathophysiology & Presentation):', currentQ['what'] ?? 'No presentation provided.'),
                    const SizedBox(height: 14),
                    _rationaleSection('2. How (Management & Clinical Reasoning):', currentQ['how'] ?? 'No management approach provided.'),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF38292d), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                  onPressed: currentIndex > 0 ? () {
                    _playSound('click');
                    setState(() {
                      if (questionStatuses[currentIndex] == 'unvisited') {
                        questionStatuses[currentIndex] = 'skipped';
                      }
                      currentIndex--;
                      
                      isAnswerLocked = questionStatuses[currentIndex] == 'answered';
                      hasScoredCurrentQuestion = isAnswerLocked;
                      selectedOptionIndex = null;
                      selectedSataIndices.clear();
                      isAnswerRevealed = false;
                    });
                  } : null,
                  child: const Text('← Previous'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8f4f5a), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                  onPressed: isAnswerLocked ? () {
                    _playSound('click');
                    setState(() {
                      if (questionStatuses[currentIndex] == 'unvisited') {
                        questionStatuses[currentIndex] = 'skipped';
                      }

                      if (currentIndex < activeSessionQuestions.length - 1) {
                        currentIndex++;
                        
                        isAnswerLocked = questionStatuses[currentIndex] == 'answered';
                        hasScoredCurrentQuestion = isAnswerLocked;
                        selectedOptionIndex = null;
                        selectedSataIndices.clear();
                        isAnswerRevealed = false;
                      } else {
                        examTimer?.cancel();
                        _saveSessionHistory(score, activeSessionQuestions.length, selectedCategoryFilter);
                        quizFinished = true;
                      }
                    });
                  } : null,
                  child: Text(currentIndex < activeSessionQuestions.length - 1 ? 'Next →' : 'View Results', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFfff5f7),
      endDrawer: Drawer(
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('🧠 Card Queue', style: GoogleFonts.lexend(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF38292d))),
              const SizedBox(height: 6),
              Text('Green = Done | Yellow = Viewed', style: GoogleFonts.lexend(fontSize: 12, color: const Color(0xFF8a7378))),
              const Divider(height: 25),
              Expanded(
                child: ListView.builder(
                  itemCount: activeSessionQuestions.length,
                  itemBuilder: (context, idx) {
                    final sq = activeSessionQuestions[idx];
                    bool isSelected = idx == currentIndex;
                    String status = questionStatuses[idx];
                    
                    Color tileColor = Colors.transparent;
                    if (status == 'answered') {
                      tileColor = const Color(0xFFecfdf5);
                    } else if (status == 'skipped') {
                      tileColor = const Color(0xFFfefce8);
                    }

                    return ListTile(
                      selected: isSelected,
                      selectedTileColor: const Color(0xFFfdf2f4),
                      tileColor: tileColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      title: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: status == 'answered' ? Colors.green : status == 'skipped' ? Colors.amber : Colors.grey.shade400,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text('Card ${idx + 1}: ${sq['category']}', style: GoogleFonts.lexend(fontSize: 13, fontWeight: FontWeight.w600))),
                        ],
                      ),
                      subtitle: Text(sq['questionText'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.lexend(fontSize: 11)),
                      onTap: () {
                        _playSound('click');
                        setState(() {
                          if (questionStatuses[currentIndex] == 'unvisited') {
                            questionStatuses[currentIndex] = 'skipped';
                          }
                          currentIndex = idx;
                          
                          isAnswerLocked = questionStatuses[currentIndex] == 'answered';
                          hasScoredCurrentQuestion = isAnswerLocked;
                          selectedOptionIndex = null;
                          selectedSataIndices.clear();
                          isAnswerRevealed = false;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFFfff5f7),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          'Mode: ${currentScreen == 'srs' ? '🧠 SRS' : currentScreen == 'bookmarked' ? '📌 Bookmarks' : 'Standard'}', 
                          style: GoogleFonts.lexend(color: const Color(0xFF8f4f5a), fontWeight: FontWeight.bold, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Builder(
                        builder: (context) => OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF9333ea),
                            side: const BorderSide(color: Color(0xFF9333ea)),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          ),
                          icon: const Icon(Icons.menu_rounded, size: 14),
                          label: const Text('Queue', style: TextStyle(fontSize: 11)),
                          onPressed: () {
                            _playSound('click');
                            Scaffold.of(context).openEndDrawer();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, color: Colors.amber.shade800, size: 20),
                      onPressed: () => _toggleBookmark(docId, isBookmarked),
                    ),
                    if (isAdmin)
                      IconButton(
                        icon: const Icon(Icons.delete_rounded, color: Colors.red, size: 18),
                        onPressed: () => _deleteQuestion(docId),
                      ),
                    const SizedBox(width: 4),
                    Text('${currentIndex + 1}/${activeSessionQuestions.length}', style: GoogleFonts.lexend(color: const Color(0xFF8a7378), fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: isMobile
                ? SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        questionContent,
                        const Divider(height: 1, color: Color(0xFFf3e8eb)),
                        optionsContent,
                      ],
                    ),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 1, child: questionContent),
                      const VerticalDivider(width: 1, color: Color(0xFFf3e8eb)),
                      Expanded(flex: 1, child: optionsContent),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  void _showBookmarkPrompt(String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('📌 Bookmark Status', style: GoogleFonts.lexend(fontWeight: FontWeight.bold)),
        content: Text('You have answered this bookmarked question. Would you like to keep it in your bookmarks or remove it?', style: GoogleFonts.lexend()),
        actions: [
          TextButton(
            onPressed: () {
              _toggleBookmark(docId, true);
              Navigator.pop(context);
            },
            child: const Text('Remove Bookmark', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8f4f5a)),
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Keep Bookmark', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _rationaleSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.lexend(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF8f4f5a), letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Text(content, style: GoogleFonts.lexend(fontSize: 13, height: 1.5, color: const Color(0xFF38292d))),
      ],
    );
  }

  Widget _buildResultsScreen(int totalQuestions) {
    final double percentage = totalQuestions > 0 ? (score / totalQuestions) * 100 : 0.0;

    return Center(
      child: Container(
        padding: const EdgeInsets.all(30),
        constraints: const BoxConstraints(maxWidth: 600),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFf3e8eb)),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 15, offset: Offset(0, 5))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('💖 N.R.R. SESSION COMPLETE! 💖', textAlign: TextAlign.center, style: GoogleFonts.lexend(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF38292d))),
            const SizedBox(height: 16),
            Text('$score / $totalQuestions (${percentage.toStringAsFixed(1)}%)', style: GoogleFonts.lexend(fontSize: 32, fontWeight: FontWeight.w800, color: const Color(0xFF8f4f5a))),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8f4f5a),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 16),
              ),
              onPressed: () {
                _playSound('click');
                setState(() {
                  currentScreen = 'menu';
                  quizFinished = false;
                  currentIndex = 0;
                  score = 0;
                });
              },
              child: const Text('Return to Dashboard', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}