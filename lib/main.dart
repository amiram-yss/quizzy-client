import 'package:flutter/material.dart';
import 'quiz_model.dart';
import 'mock_quizzes.dart';
import 'quiz_play_page.dart';

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

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Quizzes'),
      ),
      body: ListView.builder(
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
          // TODO: Implement quiz creation
        },
        child: const Icon(Icons.add),
        tooltip: 'Create New Game',
      ),
    );
  }
}
