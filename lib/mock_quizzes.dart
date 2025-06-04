import 'quiz_model.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// שינוי מרשימה קבועה לרשימה שניתן לעדכן
List<Quiz> mockQuizzes = [
  Quiz(
    title: "מדריך הכשרה לדירוג מכשירים לטיסה",
    description: "מדריך מקצועי להכשרת טייסים לטיסת מכשירים, כולל תרגילים ופרוצדורות לטיסה בתנאי ראות לקויה.",
    questions: [
      QuizQuestion(
        question: "מהו המרכיב העיקרי של טיסת מכשירים?",
        options: [
          QuizOption(text: "Amriam", correct: false),
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

// פונקציה לטעינת חידונים מהשרת
Future<void> loadQuizzesFromApi() async {
  try {
    final response = await http.get(Uri.parse('http://localhost:8001/api/quizzes/all/raw'));
    
    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      
      if (jsonData['success'] == true && jsonData['data'] != null) {
        // מחיקת החידונים הקיימים
        mockQuizzes.clear();
        
        // המרת ה-JSON לאובייקטים של Quiz
        final quizData = jsonData['data'] as Map<String, dynamic>;
        
        quizData.forEach((quizId, quizJson) {
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
        });
      }
    }
  } catch (e) {
    print('שגיאה בטעינת החידונים: $e');
  }
}
