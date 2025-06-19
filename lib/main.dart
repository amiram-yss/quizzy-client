import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'quiz_model.dart';
import 'mock_quizzes.dart';
import 'quiz_play_page.dart';
import 'create_quiz_page.dart';
import 'auth_service.dart';
import 'login_page.dart';
import 'user_model.dart';

void main() {
  runApp(const QuizzyApp());
}

class QuizzyApp extends StatelessWidget {
  const QuizzyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AuthService(),
      child: MaterialApp(
        title: 'Quizzy',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // Initialize auth service
    Future.microtask(() {
      Provider.of<AuthService>(context, listen: false).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    // Show loading indicator while checking authentication
    if (authService.isLoading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF667eea),
                Color(0xFF764ba2),
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'טוען...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // If authenticated, show home page, otherwise show login page
    return authService.isAuthenticated ? const HomePage() : const LoginPage();
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  bool _isLoading = true;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _loadQuizzes();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadQuizzes() async {
    setState(() {
      _isLoading = true;
    });

    await loadQuizzesFromApi();

    setState(() {
      _isLoading = false;
    });

    // Start animation after loading
    _fadeController.forward();
  }

  // שמירה על הלוגיקה המקורית שלך לתמונת פרופיל
  Widget _buildProfileImage(User? user) {
    print('🔍 Building profile image for user: ${user?.email}');
    print('🖼️ Picture URL: "${user?.picture}"');

    // תמיד נתחיל עם תמונת initials כ-fallback
    final initialsWidget = _buildInitialsAvatar(user);

    // אם יש URL של תמונה, ננסה לטעון אותה
    if (user?.picture != null &&
        user!.picture!.isNotEmpty &&
        (user.picture!.startsWith('http://') || user.picture!.startsWith('https://'))) {

      print('✅ Attempting to load picture from: ${user.picture}');

      return CircleAvatar(
        radius: 16,
        backgroundColor: Colors.grey.shade300,
        // תמיד נציג את האותיות ראשונות כ-fallback
        child: Stack(
          children: [
            // תמונת האותיות כבסיס
            initialsWidget,
            // נסיון לטעון את התמונה מעל
            ClipOval(
              child: Image.network(
                user.picture!,
                width: 32,
                height: 32,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  // במהלך הטעינה, תציג את האותיות
                  if (loadingProgress == null) {
                    // הטעינה הסתיימה בהצלחה
                    return child;
                  }
                  // עדיין טוען - תציג את האותיות
                  return const SizedBox.shrink();
                },
                errorBuilder: (context, error, stackTrace) {
                  print('❌ Failed to load image: $error');
                  // אם יש שגיאה, תציג את האותיות (שכבר מוצגות)
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      );
    } else {
      print('⚠️ No valid picture URL, showing initials only');
      return initialsWidget;
    }
  }

  // שמירה על הפונקציה המקורית שלך
  Widget _buildInitialsAvatar(User? user) {
    String initials = '';
    if (user?.name != null && user!.name.isNotEmpty) {
      final nameParts = user.name.split(' ');
      if (nameParts.isNotEmpty) {
        initials = nameParts[0].substring(0, 1).toUpperCase();
        if (nameParts.length > 1) {
          initials += nameParts[1].substring(0, 1).toUpperCase();
        }
      }
    } else {
      initials = user?.email?.substring(0, 1).toUpperCase() ?? 'U';
    }

    return CircleAvatar(
      radius: 16,
      backgroundColor: Color(0xFF667eea),
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  // תמונת פרופיל גדולה לכרטיס המשתמש (שמירה על הלוגיקה המקורית)
  Widget _buildLargeProfileImage(User? user) {
    if (user?.picture != null && user!.picture!.isNotEmpty) {
      return CircleAvatar(
        backgroundImage: NetworkImage(user.picture!),
        radius: 30,
        backgroundColor: Color(0xFF667eea),
        onBackgroundImageError: (error, stackTrace) {
          print('שגיאה בטעינת תמונת פרופיל: $error');
        },
      );
    } else {
      return CircleAvatar(
        radius: 30,
        backgroundColor: Color(0xFF667eea),
        child: Text(
          user?.name.isNotEmpty == true
              ? user!.name.split(' ').map((e) => e.substring(0, 1)).take(2).join('').toUpperCase()
              : user?.email.substring(0, 1).toUpperCase() ?? 'U',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        appBar: AppBar(
          title: Text(
            'השאלונים שלי',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.grey.withOpacity(0.1),
          surfaceTintColor: Colors.white,
          actions: [
            // כפתור רענון
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Color(0xFF667eea).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.refresh,
                  color: Color(0xFF667eea),
                ),
                onPressed: _loadQuizzes,
                tooltip: 'רענן שאלונים',
              ),
            ),

            // תצוגת פרטי המשתמש מתוקנת - שמירה על הלוגיקה המקורית
            if (user != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // הצגת השם (רק שם פרטי)
                    Text(
                      user.name.isNotEmpty
                          ? user.name.split(' ').first
                          : user.email.split('@').first,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // תמונת פרופיל עם fallback - הלוגיקה המקורית שלך
                    _buildProfileImage(user),
                  ],
                ),
              ),
              const SizedBox(width: 8),
            ],

            // כפתור התנתקות
            Container(
              margin: const EdgeInsets.only(left: 12, right: 8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.logout,
                  color: Colors.red.shade600,
                ),
                onPressed: () async {
                  await authService.signOut();
                },
                tooltip: 'התנתק',
              ),
            ),
          ],
        ),

        body: _isLoading
            ? Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        width: 50,
                        height: 50,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'טוען שאלונים...',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )
            : FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              // רשימת השאלונים
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: mockQuizzes.isEmpty
                      ? Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Color(0xFF667eea).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.quiz_outlined,
                              size: 40,
                              color: Color(0xFF667eea),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'אין שאלונים עדיין',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'צור את השאלון הראשון שלך\nבלחיצה על כפתור הפלוס',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                      : Column(
                    children: [
                      // כרטיס סטטיסטיקות קטן יותר
                      if (user != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16, top: 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Color(0xFF667eea).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.person,
                                  color: Color(0xFF667eea),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'שלום, ${user.name.isNotEmpty ? user.name.split(' ').first : user.email.split('@').first}!',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Color(0xFF667eea).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.assessment,
                                  color: Color(0xFF667eea),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'שאלונים',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    '${mockQuizzes.length}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF667eea),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                      // רשימת החידונים
                      Expanded(
                        child: ListView.builder(
                          itemCount: mockQuizzes.length,
                          itemBuilder: (context, index) {
                            final quiz = mockQuizzes[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.08),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => QuizPlayPage(quiz: quiz),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Row(
                                      children: [
                                        // איקון החידון
                                        Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                Color(0xFF667eea),
                                                Color(0xFF764ba2),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            Icons.quiz,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        ),

                                        const SizedBox(width: 16),

                                        // פרטי החידון
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                quiz.title,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  color: Color(0xFF1F2937),
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                quiz.description,
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 14,
                                                  height: 1.4,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 10),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Color(0xFF667eea).withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.quiz,
                                                      size: 14,
                                                      color: Color(0xFF667eea),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '${quiz.questions.length} שאלות',
                                                      style: TextStyle(
                                                        color: Color(0xFF667eea),
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        // חץ
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[50],
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            Icons.arrow_forward_ios,
                                            size: 16,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // FAB משופר
        floatingActionButton: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF667eea),
                  Color(0xFF764ba2),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF667eea).withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateQuizPage(),
                  ),
                ).then((_) {
                  // Refresh quizzes after creating a new one
                  _loadQuizzes();
                });
              },
              backgroundColor: Colors.transparent,
              elevation: 0,
              icon: const Icon(Icons.add, color: Colors.white, size: 24),
              label: const Text(
                'יצירת שאלון',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}