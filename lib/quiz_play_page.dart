import 'package:flutter/material.dart';
import 'quiz_model.dart';

class QuizPlayPage extends StatefulWidget {
  final Quiz quiz;
  const QuizPlayPage({super.key, required this.quiz});

  @override
  State<QuizPlayPage> createState() => _QuizPlayPageState();
}

class _QuizPlayPageState extends State<QuizPlayPage> with TickerProviderStateMixin {
  int _currentQuestionIndex = 0;
  int? _selectedOptionIndex;
  bool _showResult = false;
  bool? _isCorrect;
  int _correctAnswers = 0;
  bool _quizCompleted = false;

  late AnimationController _flipController;
  late AnimationController _progressController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;

  late Animation<double> _flipAnimation;
  late Animation<double> _progressAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _flipController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );

    _progressAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOut),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    // Start initial animations
    _fadeController.forward();
    _scaleController.forward();
    _updateProgress();
  }

  @override
  void dispose() {
    _flipController.dispose();
    _progressController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _updateProgress() {
    final progress = (_currentQuestionIndex + 1) / widget.quiz.questions.length;
    _progressController.animateTo(progress);
  }

  Widget _buildProgressBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'שאלה ${_currentQuestionIndex + 1} מתוך ${widget.quiz.questions.length}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                '${((_currentQuestionIndex + 1) / widget.quiz.questions.length * 100).round()}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF667eea),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            child: AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return FractionallySizedBox(
                  alignment: Alignment.centerRight,
                  widthFactor: _progressAnimation.value,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF667eea),
                          Color(0xFF764ba2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard() {
    final currentQuestion = widget.quiz.questions[_currentQuestionIndex];

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              // Question icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFF667eea).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.quiz,
                  color: Color(0xFF667eea),
                  size: 24,
                ),
              ),

              const SizedBox(height: 16),

              Text(
                currentQuestion.question,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard(int index) {
    final currentQuestion = widget.quiz.questions[_currentQuestionIndex];
    final option = currentQuestion.options[index];
    final isSelected = _selectedOptionIndex == index;
    final isCorrect = option.correct;

    return AnimatedBuilder(
      animation: _flipAnimation,
      builder: (context, child) {
        final angle = isSelected && _showResult ? _flipAnimation.value * 3.14159 : 0.0;

        return GestureDetector(
          onTap: _showResult ? null : () {
            setState(() {
              _selectedOptionIndex = index;
              _showResult = false;
              _flipController.reset();
            });
          },
          child: Container(
            height: 140, // Increased height for more space
            child: Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(angle),
              alignment: Alignment.center,
              child: angle < 1.57079633
                  ? _buildFrontCard(option.text, isSelected, index)
                  : Transform(
                transform: Matrix4.identity()..rotateY(3.14159),
                alignment: Alignment.center,
                child: _buildBackCard(isCorrect),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFrontCard(String text, bool isSelected, int index) {
    // Define colors for each option
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
    ];
    final color = colors[index % colors.length];

    return Container(
      width: double.infinity,
      height: 140,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isSelected ? color.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSelected ? color : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected ? color.withOpacity(0.2) : Colors.grey.withOpacity(0.05),
            blurRadius: isSelected ? 8 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Option letter
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isSelected ? color : Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                String.fromCharCode(65 + index), // A, B, C, D
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          Expanded(
            child: Center(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? color.shade700 : Color(0xFF1F2937),
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          if (isSelected) ...[
            const SizedBox(height: 8),
            Icon(
              Icons.check_circle,
              color: color,
              size: 22,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBackCard(bool isCorrect) {
    return Container(
      width: double.infinity,
      height: 140,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isCorrect
              ? [Colors.green.shade400, Colors.green.shade600]
              : [Colors.red.shade400, Colors.red.shade600],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: (isCorrect ? Colors.green : Colors.red).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isCorrect ? Icons.check_circle : Icons.cancel,
            color: Colors.white,
            size: 40,
          ),
          const SizedBox(height: 10),
          Text(
            isCorrect ? 'נכון!' : 'שגוי',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerButton() {
    final isEnabled = _selectedOptionIndex != null && !_showResult;

    return Container(
      margin: const EdgeInsets.all(20),
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isEnabled
              ? [Color(0xFF667eea), Color(0xFF764ba2)]
              : [Colors.grey.shade400, Colors.grey.shade500],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: isEnabled
            ? [
          BoxShadow(
            color: Color(0xFF667eea).withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ]
            : [],
      ),
      child: ElevatedButton(
        onPressed: isEnabled ? _handleAnswer : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          'בחר תשובה',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Future<void> _handleAnswer() async {
    if (_selectedOptionIndex == null) return;

    final currentQuestion = widget.quiz.questions[_currentQuestionIndex];
    final correct = currentQuestion.options[_selectedOptionIndex!].correct;

    setState(() {
      _isCorrect = correct;
      _showResult = true;
    });

    await _flipController.forward();
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
        });
        _flipController.reset();
        _updateProgress();

        // Reset animations for new question
        _fadeController.reset();
        _scaleController.reset();
        _fadeController.forward();
        _scaleController.forward();
      } else {
        setState(() {
          _quizCompleted = true;
        });
      }
    }
  }

  Widget _buildCompletionScreen() {
    final percentage = (_correctAnswers / widget.quiz.questions.length * 100).round();
    final isExcellent = percentage >= 80;
    final isGood = percentage >= 60;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Success icon with animation
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isExcellent
                      ? [Colors.green.shade400, Colors.green.shade600]
                      : isGood
                      ? [Colors.orange.shade400, Colors.orange.shade600]
                      : [Colors.red.shade400, Colors.red.shade600],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (isExcellent ? Colors.green : isGood ? Colors.orange : Colors.red).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                isExcellent ? Icons.emoji_events : isGood ? Icons.thumb_up : Icons.refresh,
                size: 60,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 32),

            Text(
              isExcellent ? 'מעולה!' : isGood ? 'כל הכבוד!' : 'ניסיון טוב!',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),

            const SizedBox(height: 16),

            Text(
              'סיימת את השאלון בהצלחה',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),

            const SizedBox(height: 32),

            // Score card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'התוצאה שלך',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$_correctAnswers',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF667eea),
                        ),
                      ),
                      Text(
                        ' / ${widget.quiz.questions.length}',
                        style: TextStyle(
                          fontSize: 24,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: (isExcellent ? Colors.green : isGood ? Colors.orange : Colors.red).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$percentage%',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isExcellent ? Colors.green[700] : isGood ? Colors.orange[700] : Colors.red[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Action buttons
            Column(
              children: [
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF667eea).withOpacity(0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.home, color: Colors.white),
                    label: const Text(
                      'חזרה לתפריט הראשי',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Container(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _currentQuestionIndex = 0;
                        _selectedOptionIndex = null;
                        _showResult = false;
                        _correctAnswers = 0;
                        _quizCompleted = false;
                      });
                      _flipController.reset();
                      _progressController.reset();
                      _fadeController.reset();
                      _scaleController.reset();
                      _fadeController.forward();
                      _scaleController.forward();
                      _updateProgress();
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Color(0xFF667eea), width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: Icon(Icons.refresh, color: Color(0xFF667eea)),
                    label: Text(
                      'שחק שוב',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF667eea),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        appBar: AppBar(
          title: Text(
            widget.quiz.title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.grey.withOpacity(0.1),
          surfaceTintColor: Colors.white,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.arrow_back,
                color: Color(0xFF1F2937),
              ),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),

        body: _quizCompleted
            ? _buildCompletionScreen()
            : Column(
          children: [
            // Progress bar
            _buildProgressBar(),

            // Question card
            _buildQuestionCard(),

            // Options in 2x2 grid
            Expanded(
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 700),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // First row
                      Row(
                        children: [
                          Expanded(child: _buildOptionCard(0)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildOptionCard(1)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Second row
                      Row(
                        children: [
                          Expanded(child: _buildOptionCard(2)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildOptionCard(3)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Answer button
            _buildAnswerButton(),
          ],
        ),
      ),
    );
  }
}