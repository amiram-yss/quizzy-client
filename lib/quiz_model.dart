class QuizOption {
  final String text;
  final bool correct;

  QuizOption({required this.text, required this.correct});

  factory QuizOption.fromJson(Map<String, dynamic> json) {
    return QuizOption(
      text: json['text'],
      correct: json['correct'],
    );
  }
}

class QuizQuestion {
  final String question;
  final List<QuizOption> options;

  QuizQuestion({required this.question, required this.options});

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      question: json['question'],
      options: (json['options'] as List)
          .map((e) => QuizOption.fromJson(e))
          .toList(),
    );
  }
}

class Quiz {
  final String title;
  final String description;
  final List<QuizQuestion> questions;

  Quiz({required this.title, required this.description, required this.questions});

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      title: json['title'],
      description: json['description'],
      questions: (json['questions'] as List)
          .map((e) => QuizQuestion.fromJson(e))
          .toList(),
    );
  }
}