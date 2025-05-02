import 'package:flutter/material.dart';
import 'quiz_model.dart';

class QuizPlayPage extends StatefulWidget {
  final Quiz quiz;
  const QuizPlayPage({super.key, required this.quiz});

  @override
  State<QuizPlayPage> createState() => _QuizPlayPageState();
}

class _QuizPlayPageState extends State<QuizPlayPage> with SingleTickerProviderStateMixin {
  int? _selectedOptionIndex;
  bool _showResult = false;
  bool? _isCorrect;
  bool _isOptionSelected = false; // משתנה חדש למעקב אחרי בחירה
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
    final firstQuestion = widget.quiz.questions.isNotEmpty ? widget.quiz.questions[0] : null;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quiz.title),
      ),
      body: firstQuestion == null
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
                          firstQuestion.question,
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
                                  onTap: !_isOptionSelected ? () {
                                    setState(() {
                                      _selectedOptionIndex = 0;
                                      _showResult = false;
                                      _isOptionSelected = true; // עדכון משתנה הבחירה
                                    });
                                  } : null,
                                  child: _buildOptionCard(firstQuestion, 0, cardWidth, minCardHeight),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: !_isOptionSelected ? () {
                                    setState(() {
                                      _selectedOptionIndex = 1;
                                      _showResult = false;
                                      _isOptionSelected = true; // עדכון משתנה הבחירה
                                    });
                                  } : null,
                                  child: _buildOptionCard(firstQuestion, 1, cardWidth, minCardHeight),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: !_isOptionSelected ? () {
                                    setState(() {
                                      _selectedOptionIndex = 2;
                                      _showResult = false;
                                      _isOptionSelected = true; // עדכון משתנה הבחירה
                                    });
                                  } : null,
                                  child: _buildOptionCard(firstQuestion, 2, cardWidth, minCardHeight),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: !_isOptionSelected ? () {
                                    setState(() {
                                      _selectedOptionIndex = 3;
                                      _showResult = false;
                                      _isOptionSelected = true; // עדכון משתנה הבחירה
                                    });
                                  } : null,
                                  child: _buildOptionCard(firstQuestion, 3, cardWidth, minCardHeight),
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
                              final firstQuestion = widget.quiz.questions[0];
                              final correct = _selectedOptionIndex != null &&
                                  firstQuestion.options[_selectedOptionIndex!].correct;
                              setState(() {
                                _isCorrect = correct;
                              });
                              await _controller.forward();
                              setState(() {
                                _showResult = true;
                              });
                              Future.delayed(Duration(seconds: 3), () {
                                // לוגיקה למעבר לשאלה הבאה
                                // לדוגמה: עדכון אינדקס השאלה הנוכחית
                                // currentQuestionIndex++;
                                // setState(() {
                                //   _selectedOptionIndex = null;
                                //   _showResult = false;
                                //   _isOptionSelected = false; // איפוס משתנה הבחירה
                                // });
                              });
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
    );
  }

  Widget _buildOptionCard(firstQuestion, int index, double width, double minHeight) {
    final isSelected = _selectedOptionIndex == index;
    final optionText = firstQuestion.options.length > index ? firstQuestion.options[index].text : '';
    final isCorrect = firstQuestion.options.length > index ? firstQuestion.options[index].correct : false;
    final double expandedHeight = minHeight * 1.2;

    return AnimatedBuilder(
      animation: _flipAnimation,
      builder: (context, child) {
        final angle = isSelected ? _flipAnimation.value * 3.14159 : 0.0;
        final currentHeight = isSelected 
            ? minHeight + (_flipAnimation.value * (expandedHeight - minHeight))
            : minHeight;

        return SizedBox(
          width: width,
          height: currentHeight,
          child: Transform(
            transform: Matrix4.rotationY(angle),
            alignment: Alignment.center,
            child: angle < 1.57
                ? Card(
                    elevation: 1,
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: Container(
                      width: width,
                      height: currentHeight,
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
                : Transform.scale(
                    scaleX: -1,
                    scaleY: 1,
                    child: Card(
                      elevation: 1,
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      color: isCorrect ? Colors.green[400] : Colors.red[400],
                      child: Container(
                        width: width,
                        height: currentHeight,
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