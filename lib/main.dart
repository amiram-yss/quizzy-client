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
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
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

class _HomePageState extends State<HomePage> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuizzes();
  }

  Future<void> _loadQuizzes() async {
    setState(() {
      _isLoading = true;
    });

    await loadQuizzesFromApi();

    setState(() {
      _isLoading = false;
    });
  }

  // פונקציה לבניית תמונת פרופיל עם fallback
  // עדכן את הפונקציה _buildProfileImage ב-main.dart:

  // החלף את הפונקציה _buildProfileImage הקיימת בזו:
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

// וודא שיש גם את הפונקציה הזו (אם אין):
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
      backgroundColor: Colors.blue.shade600,
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

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('השאלונים שלי'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadQuizzes,
              tooltip: 'רענן שאלונים',
            ),
            // תצוגת פרטי המשתמש מתוקנת
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
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // תמונת פרופיל עם fallback
                    _buildProfileImage(user),
                  ],
                ),
              ),
              const SizedBox(width: 8),
            ],
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await authService.signOut();
              },
              tooltip: 'התנתק',
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          children: [
            // כרטיס פרטי משתמש בראש הדף
            if (user != null)
              Card(
                margin: const EdgeInsets.all(16),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // תמונת פרופיל גדולה יותר
                      Container(
                        width: 60,
                        height: 60,
                        child: user.picture != null && user.picture!.isNotEmpty
                            ? CircleAvatar(
                          backgroundImage: NetworkImage(user.picture!),
                          radius: 30,
                          backgroundColor: Colors.grey.shade300,
                          onBackgroundImageError: (error, stackTrace) {
                            print('שגיאה בטעינת תמונת פרופיל: $error');
                          },
                        )
                            : CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.blue.shade600,
                          child: Text(
                            user.name.isNotEmpty
                                ? user.name.split(' ').map((e) => e.substring(0, 1)).take(2).join('').toUpperCase()
                                : user.email.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'שלום, ${user.name.isNotEmpty ? user.name : user.email.split('@').first}!',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.email,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.green.shade200),
                              ),
                              child: Text(
                                'מחובר',
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // רשימת השאלונים
            Expanded(
              child: mockQuizzes.isEmpty
                  ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.quiz_outlined,
                      size: 64,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'לא נמצאו שאלונים',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'לחץ על + ליצירת שאלון חדש',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: mockQuizzes.length,
                itemBuilder: (context, index) {
                  final quiz = mockQuizzes[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      title: Text(
                        quiz.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Text(
                            quiz.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.quiz,
                                size: 16,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${quiz.questions.length} שאלות',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => QuizPlayPage(quiz: quiz),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
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
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}