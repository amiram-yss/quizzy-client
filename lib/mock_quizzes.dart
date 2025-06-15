import 'quiz_model.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// *** ייבוא dart:math עבור math.min ***
import 'dart:math' as math;

// שינוי מרשימה קבועה לרשימה שניתן לעדכן
List<Quiz> mockQuizzes = [
  Quiz(
    title: "מדריך הכשרה לדירוג מכשירים לטיסה",
    description: "מדריך מקצועי להכשרת טייסים לטיסת מכשירים, כולל תרגילים ופרוצדורות לטיסה בתנאי ראות לקויה.",
    questions: [
      QuizQuestion(
        question: "מהו המרכיב העיקרי של טיסת מכשירים?",
        options: [
          QuizOption(text: "Amiram", correct: false),
          QuizOption(text: "אמון במכשירים", correct: true),
          QuizOption(text: "תצפית חיצונית", correct: false),
          QuizOption(text: "האזנה לרדיו", correct: false),
        ],
      ),
      QuizQuestion(
        question: "מהו סדר הסריקה הנכון בטיסה ישרה ואופקית?",
        options: [
          QuizOption(text: "H → A ← H → S → H", correct: false),
          QuizOption(text: "H ↓ D ↑ H ↓ D ↑ H → A ← H ↓ D ↑ H ← S → H", correct: true),
          QuizOption(text: "H ↙ V ↖ H → A ← H → S ← H", correct: false),
          QuizOption(text: "H → S → H → A ← H", correct: false),
        ],
      ),
      QuizQuestion(
        question: "מהו שיעור הטיפוס הסטנדרטי (ROC) באימוני מכשירים?",
        options: [
          QuizOption(text: "300 רגל לדקה", correct: false),
          QuizOption(text: "500 רגל לדקה", correct: true),
          QuizOption(text: "700 רגל לדקה", correct: false),
          QuizOption(text: "1000 רגל לדקה", correct: false),
        ],
      ),
      QuizQuestion(
        question: "מהו זווית הבנק המומלצת לסיבוב Rate 1 במהירות אווירית של 80 קשר?",
        options: [
          QuizOption(text: "10°", correct: false),
          QuizOption(text: "15°", correct: true),
          QuizOption(text: "20°", correct: false),
          QuizOption(text: "25°", correct: false),
        ],
      ),
      QuizQuestion(
        question: "מהו השלב הראשון בהתאוששות מ-Upset כאשר האף למעלה והמהירות נמוכה?",
        options: [
          QuizOption(text: "הפחתת עוצמת המנוע", correct: false),
          QuizOption(text: "הפעלת עוצמת מנוע מלאה", correct: true),
          QuizOption(text: "הרמת האף עוד יותר", correct: false),
          QuizOption(text: "הורדת האף", correct: false),
        ],
      ),
      QuizQuestion(
        question: "מהו ההליך הנכון להתאוששות מ-Stall עם מנוע פועל?",
        options: [
          QuizOption(text: "הפחתת AOA על ידי הורדת האף, שמירת כנפיים ישרות וכיוון קבוע, הפעלת עוצמת מנוע לפי הצורך", correct: true),
          QuizOption(text: "הרמת האף עוד יותר, הפעלת עוצמת מנוע מלאה", correct: false),
          QuizOption(text: "סיבוב חד לצד אחד", correct: false),
          QuizOption(text: "הורדת כל המצנחים", correct: false),
        ],
      ),
      QuizQuestion(
        question: "מהי שיטת ה-'45' ליירט Radial חדש?",
        options: [
          QuizOption(text: "סיבוב של 45° לכיוון ה-Radial החדש", correct: false),
          QuizOption(text: "טיסה בזווית 45° מה-Radial הנוכחי ל-Radial החדש", correct: true),
          QuizOption(text: "טיסה למשך 45 שניות לפני ה-Radial החדש", correct: false),
          QuizOption(text: "טיסה במהירות של 45 קשר", correct: false),
        ],
      ),
      QuizQuestion(
        question: "מהו ההבדל בין Procedure Turn ל-Base Turn?",
        options: [
          QuizOption(text: "Procedure Turn משנה כיוון ב-180° בעוד Base Turn לא", correct: false),
          QuizOption(text: "Base Turn כולל Outbound Leg שאינו הדדי ל-Inbound Leg", correct: true),
          QuizOption(text: "אין הבדל, שניהם זהים", correct: false),
          QuizOption(text: "Base Turn משמש רק במטוסים גדולים", correct: false),
        ],
      ),
      QuizQuestion(
        question: "מהו הכלל הראשון בטיסה על DME Arc?",
        options: [
          QuizOption(text: "לשמור על המרחק הנדרש מ-DME ±0.5 NM", correct: true),
          QuizOption(text: "לשמור על גובה קבוע", correct: false),
          QuizOption(text: "לשמור על מהירות קבועה", correct: false),
          QuizOption(text: "לשמור על זווית נטייה קבועה", correct: false),
        ],
      ),
      QuizQuestion(
        question: "מהו השלב הראשון בביצוע Holding Procedure?",
        options: [
          QuizOption(text: "סיבוב ראשוני לכיוון Outbound", correct: true),
          QuizOption(text: "טיסה ישרה ל-Inbound Leg", correct: false),
          QuizOption(text: "המתנה להוראות ATC", correct: false),
          QuizOption(text: "שינוי גובה", correct: false),
        ],
      ),
    ],
  ),
];

// *** פונקציה משופרת לקבלת טוקן אוטנטיקציה ***
Future<String?> _getAuthToken() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');

    print('🔍 [LOAD_QUIZZES] Checking stored user data...');
    print('📦 [LOAD_QUIZZES] Raw user data exists: ${userData != null}');

    if (userData != null) {
      final userMap = json.decode(userData);
      final token = userMap['token'];

      print('🔑 [LOAD_QUIZZES] Token found: ${token != null ? "Yes" : "No"}');
      if (token != null) {
        print('🔍 [LOAD_QUIZZES] Token preview: ${token.toString().substring(0, math.min(50, token.toString().length))}...');
        print('🔍 [LOAD_QUIZZES] Token length: ${token.toString().length}');
      }

      return token;
    } else {
      print('❌ [LOAD_QUIZZES] No user data found in storage');
    }
  } catch (e) {
    print('❌ [LOAD_QUIZZES] Error getting auth token: $e');
  }
  return null;
}

// *** פונקציה משופרת לטעינת חידונים מהשרת ***
Future<void> loadQuizzesFromApi() async {
  try {
    print('🚀 [LOAD_QUIZZES] Starting to load quizzes from API...');

    // *** השינוי החשוב - תמיד נקבל טוקן ***
    String? authToken = await _getAuthToken();

    if (authToken == null) {
      print('❌ [LOAD_QUIZZES] No auth token found - user might not be logged in');
      // אם אין טוקן, נשאיר את הרשימה הקיימת ולא נטען מהשרת
      return;
    }

    print('✅ [LOAD_QUIZZES] Auth token found, proceeding with API call');

    // *** הכותרות החדשות - תמיד כולל טוקן ***
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $authToken',  // *** תמיד שולח טוקן ***
    };

    print('📡 [LOAD_QUIZZES] Making request to: http://localhost:8001/api/quizzes/all/raw');
    print('🔐 [LOAD_QUIZZES] Using auth token: ${authToken.substring(0, 20)}...');

    final response = await http.get(
      Uri.parse('http://localhost:8001/api/quizzes/all/raw'),
      headers: headers,
    ).timeout(
      Duration(seconds: 30),
      onTimeout: () {
        print('⏰ [LOAD_QUIZZES] Request timed out after 30 seconds');
        throw Exception('Request timeout');
      },
    );

    print('📬 [LOAD_QUIZZES] Server response status: ${response.statusCode}');
    print('📄 [LOAD_QUIZZES] Server response body: ${response.body}');

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);

      if (jsonData['success'] == true && jsonData['data'] != null) {
        print('✅ [LOAD_QUIZZES] Successfully received quiz data');

        // *** מחיקת החידונים הקיימים כי עכשיו יש לנו נתונים אמיתיים ***
        mockQuizzes.clear();

        // המרת ה-JSON לאובייקטים של Quiz
        final quizData = jsonData['data'] as Map<String, dynamic>;

        print('📊 [LOAD_QUIZZES] Processing ${quizData.length} quizzes');

        quizData.forEach((quizId, quizJson) {
          try {
            final quiz = Quiz(
              title: quizJson['title'] ?? 'חידון ללא כותרת',
              description: quizJson['description'] ?? '',
              questions: (quizJson['questions'] as List<dynamic>).map((q) => QuizQuestion(
                question: q['question'] as String,
                options: (q['options'] as List<dynamic>).map((o) => QuizOption(
                  text: o['text'] as String,
                  correct: o['correct'] as bool,
                )).toList(),
              )).toList(),
            );

            mockQuizzes.add(quiz);
            print('✅ [LOAD_QUIZZES] Added quiz: ${quiz.title}');
          } catch (e) {
            print('❌ [LOAD_QUIZZES] Error processing quiz $quizId: $e');
          }
        });

        print('🎉 [LOAD_QUIZZES] Successfully loaded ${mockQuizzes.length} quizzes');
      } else {
        print('❌ [LOAD_QUIZZES] Server response indicates failure or no data');
        print('📊 [LOAD_QUIZZES] Response data: $jsonData');
      }
    } else if (response.statusCode == 401) {
      print('🔐 [LOAD_QUIZZES] Authentication failed - user needs to login again');
      // יש לטפל בזה ב-UI - אולי להעביר למסך התחברות
    } else if (response.statusCode == 403) {
      print('🚫 [LOAD_QUIZZES] Access forbidden - insufficient permissions');
    } else {
      print('❌ [LOAD_QUIZZES] Server error: ${response.statusCode}');
      print('📄 [LOAD_QUIZZES] Error response: ${response.body}');
    }
  } catch (e) {
    print('🚨 [LOAD_QUIZZES] Exception occurred: ${e.toString()}');
    print('🔍 [LOAD_QUIZZES] Exception type: ${e.runtimeType}');

    // במקרה של שגיאה, נשאיר את הרשימה הקיימת
    if (e.toString().contains('SocketException') || e.toString().contains('timeout')) {
      print('🌐 [LOAD_QUIZZES] Network error - keeping existing quizzes');
    } else {
      print('⚠️ [LOAD_QUIZZES] Other error - keeping existing quizzes');
    }
  }
}

// *** פונקציה חדשה לרענון חידונים ***
Future<bool> refreshQuizzesFromApi() async {
  try {
    print('🔄 [REFRESH_QUIZZES] Manual refresh triggered');
    await loadQuizzesFromApi();
    return true;
  } catch (e) {
    print('❌ [REFRESH_QUIZZES] Refresh failed: $e');
    return false;
  }
}

// *** פונקציה חדשה לבדיקת חיבור ***
Future<bool> checkApiConnection() async {
  try {
    print('🔍 [CHECK_CONNECTION] Testing API connection...');

    final response = await http.get(
      Uri.parse('http://localhost:8001/health'),
    ).timeout(Duration(seconds: 10));

    if (response.statusCode == 200) {
      print('✅ [CHECK_CONNECTION] API is available');
      return true;
    } else {
      print('❌ [CHECK_CONNECTION] API returned status: ${response.statusCode}');
      return false;
    }
  } catch (e) {
    print('❌ [CHECK_CONNECTION] API connection failed: $e');
    return false;
  }
}

// *** פונקציה חדשה לקבלת מידע על המשתמש הנוכחי ***
Future<Map<String, dynamic>?> getCurrentUserInfo() async {
  try {
    final authToken = await _getAuthToken();

    if (authToken == null) {
      print('❌ [USER_INFO] No auth token found');
      return null;
    }

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $authToken',
    };

    final response = await http.get(
      Uri.parse('http://localhost:8001/auth/me'),
      headers: headers,
    ).timeout(Duration(seconds: 10));

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      if (jsonData['success'] == true && jsonData['user'] != null) {
        print('✅ [USER_INFO] Got user info: ${jsonData['user']['email']}');
        return jsonData['user'];
      }
    } else {
      print('❌ [USER_INFO] Failed to get user info: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ [USER_INFO] Error getting user info: $e');
  }
  return null;
}

// *** פונקציה חדשה לקבלת סטטיסטיקות המשתמש ***
Future<Map<String, dynamic>?> getUserStats() async {
  try {
    final authToken = await _getAuthToken();

    if (authToken == null) {
      print('❌ [USER_STATS] No auth token found');
      return null;
    }

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $authToken',
    };

    final response = await http.get(
      Uri.parse('http://localhost:8001/api/user/stats'),
      headers: headers,
    ).timeout(Duration(seconds: 10));

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      if (jsonData['success'] == true && jsonData['stats'] != null) {
        print('✅ [USER_STATS] Got user stats: ${jsonData['stats']['total_quizzes']} quizzes');
        return jsonData['stats'];
      }
    } else {
      print('❌ [USER_STATS] Failed to get user stats: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ [USER_STATS] Error getting user stats: $e');
  }
  return null;
}

// *** פונקציה חדשה למחיקת חידון ***
Future<bool> deleteQuiz(String quizId) async {
  try {
    print('🗑️ [DELETE_QUIZ] Attempting to delete quiz: $quizId');

    final authToken = await _getAuthToken();

    if (authToken == null) {
      print('❌ [DELETE_QUIZ] No auth token found');
      return false;
    }

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $authToken',
    };

    final response = await http.delete(
      Uri.parse('http://localhost:8001/api/quizzes/$quizId'),
      headers: headers,
    ).timeout(Duration(seconds: 15));

    print('📬 [DELETE_QUIZ] Server response status: ${response.statusCode}');
    print('📄 [DELETE_QUIZ] Server response body: ${response.body}');

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      if (jsonData['success'] == true) {
        print('✅ [DELETE_QUIZ] Quiz deleted successfully');

        // רענן את רשימת החידונים
        await loadQuizzesFromApi();
        return true;
      }
    } else if (response.statusCode == 403) {
      print('🚫 [DELETE_QUIZ] Access forbidden - not the owner');
    } else if (response.statusCode == 404) {
      print('❌ [DELETE_QUIZ] Quiz not found');
    } else {
      print('❌ [DELETE_QUIZ] Server error: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ [DELETE_QUIZ] Error deleting quiz: $e');
  }
  return false;
}
