import 'package:flutter/material.dart';
import 'quiz_model.dart';

class QuizPlayPage extends StatefulWidget {
  final Quiz quiz;
  const QuizPlayPage({super.key, required this.quiz});

  @override
  State<QuizPlayPage> createState() => _QuizPlayPageState();
}

class _QuizPlayPageState extends State<QuizPlayPage> with SingleTickerProviderStateMixin {
  int _currentQuestionIndex = 0;
  int? _selectedOptionIndex;
  bool _showResult = false;
  bool? _isCorrect;
  int _correctAnswers = 0;
  bool _quizCompleted = false;
  late AnimationController _controller;
  late Animation<double> _flipAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion = widget.quiz.questions.isNotEmpty ? widget.quiz.questions[_currentQuestionIndex] : null;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.quiz.title),
        ),
        body: _quizCompleted
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'סיימת את השאלון!',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'תשובות נכונות: $_correctAnswers מתוך ${widget.quiz.questions.length}',
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1976D2),
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      'חזרה לתפריט הראשי',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
            )
          : currentQuestion == null
              ? const Center(child: Text('No questions available.'))
              : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 24),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Center(
                        child: Text(
                          currentQuestion.question,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      double cardWidth = (constraints.maxWidth - 8) / 2;
                      double minCardHeight = 120.0;

                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: _showResult ? null : () {
                                    setState(() {
                                      _selectedOptionIndex = 0;
                                      // Reset result state when selecting a new answer
                                      _showResult = false;
                                      _controller.reset();
                                    });
                                  },
                                  child: _buildOptionCard(currentQuestion, 0, cardWidth, minCardHeight),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: _showResult ? null : () {
                                    setState(() {
                                      _selectedOptionIndex = 1;
                                      // Reset result state when selecting a new answer
                                      _showResult = false;
                                      _controller.reset();
                                    });
                                  },
                                  child: _buildOptionCard(currentQuestion, 1, cardWidth, minCardHeight),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: _showResult ? null : () {
                                    setState(() {
                                      _selectedOptionIndex = 2;
                                      // Reset result state when selecting a new answer
                                      _showResult = false;
                                      _controller.reset();
                                    });
                                  },
                                  child: _buildOptionCard(currentQuestion, 2, cardWidth, minCardHeight),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: _showResult ? null : () {
                                    setState(() {
                                      _selectedOptionIndex = 3;
                                      // Reset result state when selecting a new answer
                                      _showResult = false;
                                      _controller.reset();
                                    });
                                  },
                                  child: _buildOptionCard(currentQuestion, 3, cardWidth, minCardHeight),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF1976D2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _selectedOptionIndex != null && !_showResult
                          ? () async {
                              final currentQuestion = widget.quiz.questions[_currentQuestionIndex];
                              final correct = _selectedOptionIndex != null &&
                                  currentQuestion.options[_selectedOptionIndex!].correct;
                              
                              setState(() {
                                _isCorrect = correct;
                                _showResult = true;
                              });
                              
                              await _controller.forward();
                              
                              await Future.delayed(const Duration(seconds: 2));
                              
                              if (correct) {
                                setState(() {
                                  _correctAnswers++;
                                });
                              }

                              if (mounted) {
                                if (_currentQuestionIndex < widget.quiz.questions.length - 1) {
                                  setState(() {
                                    _currentQuestionIndex++;
                                    _selectedOptionIndex = null;
                                    _showResult = false;
                                    _controller.reset();
                                  });
                                } else {
                                  setState(() {
                                    _quizCompleted = true;
                                  });
                                }
                              }
                            }
                          : null,
                      child: const Text(
                        'בחר',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildOptionCard(currentQuestion, int index, double width, double minHeight) {
    final isSelected = _selectedOptionIndex == index;
    final optionText = currentQuestion.options.length > index ? currentQuestion.options[index].text : '';
    final isCorrect = currentQuestion.options.length > index ? currentQuestion.options[index].correct : false;

    return AnimatedBuilder(
      animation: _flipAnimation,
      builder: (context, child) {
        final angle = isSelected && _showResult ? _flipAnimation.value * 3.14159 : 0.0;

        return SizedBox(
          width: width,
          height: minHeight,
          child: Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            alignment: Alignment.center,
            child: angle < 1.57079633
                ? Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: Container(
                      width: width,
                      height: minHeight,
                      decoration: isSelected
                          ? BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF1976D2), Color(0xFF7B1FA2)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            )
                          : null,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Center(
                          child: Text(
                            optionText,
                            style: TextStyle(
                              fontSize: 16,
                              color: isSelected ? Colors.white : Colors.black,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  )
                : Transform(
                    transform: Matrix4.identity()..rotateY(3.14159),
                    alignment: Alignment.center,
                    child: Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      color: isCorrect ? Colors.green[400] : Colors.red[400],
                      child: Container(
                        width: width,
                        height: minHeight,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isCorrect ? Icons.check_circle : Icons.cancel,
                                  color: Colors.white,
                                  size: 36,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  isCorrect ? 'תשובה נכונה!' : 'תשובה לא נכונה',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }
}