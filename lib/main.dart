import 'package:flutter/material.dart';
import 'quiz_model.dart';
import 'mock_quizzes.dart';
import 'quiz_play_page.dart';
import 'create_quiz_page.dart';

void main() {
  runApp(const QuizzyApp());
}

class QuizzyApp extends StatelessWidget {
  const QuizzyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quizzy',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('השאלונים שלי'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadQuizzes,
            tooltip: 'רענן שאלונים',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : mockQuizzes.isEmpty
              ? const Center(child: Text('לא נמצאו שאלונים'))
              : ListView.builder(
                  itemCount: mockQuizzes.length,
                  itemBuilder: (context, index) {
                    final quiz = mockQuizzes[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(quiz.title),
                        subtitle: Text(quiz.description),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateQuizPage(),
            ),
          ).then((_) {
            setState(() {}); // Refresh the list when returning from CreateQuizPage
          });
        },
        child: const Icon(Icons.add),
        tooltip: 'Create New Game',
      ),
    );
  }
}
