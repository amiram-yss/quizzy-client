import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:html' as html;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import 'quiz_model.dart';
import 'mock_quizzes.dart';

class CreateQuizPage extends StatefulWidget {
  const CreateQuizPage({super.key});

  @override
  State<CreateQuizPage> createState() => _CreateQuizPageState();
}

class _CreateQuizPageState extends State<CreateQuizPage> with TickerProviderStateMixin {
  String? _selectedDifficulty;
  String _specificRequirements = '';
  PlatformFile? _selectedFile;
  bool _isDragging = false;
  bool _isLoading = false;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<String> _difficulties = ['קל', 'בינוני', 'קשה'];
  final List<String> _allowedExtensions = ['pdf', 'doc', 'docx', 'ppt', 'pptx'];

  // Map Hebrew difficulty levels to English for the API
  final Map<String, String> _difficultyMapping = {
    'קל': 'easy',
    'בינוני': 'medium',
    'קשה': 'hard',
  };

  // Base URL for the API
  final String _apiBaseUrl = 'http://localhost:8001';

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));

    // Start animations
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _allowedExtensions,
      );

      if (result != null) {
        setState(() {
          _selectedFile = result.files.first;
        });
      }
    } catch (e) {
      _showSnackBar('שגיאה בהעלאת הקובץ', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // Function to get the authentication token
  Future<String?> _getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user_data');

      print('🔍 Checking stored user data...');
      print('📦 Raw user data: $userData');

      if (userData != null) {
        final userMap = json.decode(userData);
        final token = userMap['token'];

        print('🔑 Token found: ${token != null ? "Yes" : "No"}');
        if (token != null) {
          print('🔍 Token preview: ${token.toString().substring(0, math.min(50, token.toString().length))}...');
          print('🔍 Token length: ${token.toString().length}');
        }

        return token;
      } else {
        print('❌ No user data found in storage');
      }
    } catch (e) {
      print('❌ Error getting auth token: $e');
    }
    return null;
  }

  // Function to create a quiz by sending the document to the server
  Future<void> _createQuiz() async {
    if (_selectedFile == null) {
      _showSnackBar('נא להעלות קובץ תחילה', isError: true);
      return;
    }

    if (_selectedDifficulty == null) {
      _showSnackBar('נא לבחור רמת קושי', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get authentication token
      String? authToken = await _getAuthToken();

      if (authToken == null) {
        _showSnackBar('שגיאה: לא נמצא טוקן אוטנטיקציה. נא להתחבר מחדש.', isError: true);
        setState(() {
          _isLoading = false;
        });
        return;
      }

      var uri = Uri.parse('$_apiBaseUrl/generate-quiz/');
      var request = http.MultipartRequest('POST', uri);

      // Add authentication header
      request.headers['Authorization'] = 'Bearer $authToken';

      final englishDifficulty = _difficultyMapping[_selectedDifficulty] ?? 'medium';
      request.fields['difficulty'] = englishDifficulty;
      request.fields['prompt'] = _specificRequirements;

      if (_selectedFile != null) {
        List<int> fileBytes;
        if (kIsWeb) {
          // Handle web file reading
          final html.File file = html.File(
            [_selectedFile!.bytes ?? Uint8List(0)],
            _selectedFile!.name,
          );
          final reader = html.FileReader();
          final completer = Completer<List<int>>();

          reader.onLoadEnd.listen((event) {
            final result = reader.result as String;
            final bytes = Uint8List.fromList(base64Decode(result.split(',').last));
            completer.complete(bytes.toList());
          });

          reader.readAsDataUrl(file);
          fileBytes = await completer.future;
        } else {
          fileBytes = _selectedFile!.bytes ?? [];
        }

        if (fileBytes.isEmpty) {
          throw Exception('לא ניתן לקרוא את תוכן הקובץ');
        }

        var multipartFile = http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: _selectedFile!.name,
        );
        request.files.add(multipartFile);
      }

      print('🚀 Sending request to create quiz...');
      print('📦 Using auth token: ${authToken.substring(0, 20)}...');

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      print('📬 Server response status: ${response.statusCode}');
      print('📄 Server response body: $responseBody');

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(responseBody);
        try {
          // Add the new quiz to mockQuizzes
          final newQuiz = Quiz(
            title: jsonResponse['title'] ?? 'שאלון חדש',
            description: jsonResponse['description'] ?? '',
            questions: (jsonResponse['questions'] as List<dynamic>).map((q) => QuizQuestion(
              question: q['question'] as String,
              options: (q['options'] as List<dynamic>).map((o) => QuizOption(
                text: o['text'] as String,
                correct: o['correct'] as bool,
              )).toList(),
            )).toList(),
          );

          setState(() {
            mockQuizzes.add(newQuiz);
          });

          _showSnackBar('השאלון נוצר בהצלחה: ${newQuiz.title}');

          // Navigate back to the home page
          Navigator.of(context).pop();
        } catch (e) {
          print('❌ Error processing server response: $e');
          _showSnackBar('שגיאה בעיבוד תשובת השרת', isError: true);
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        // Authentication error - redirect to login
        _showSnackBar('שגיאת אוטנטיקציה. נא להתחבר מחדש.', isError: true);
      } else {
        print('❌ Server error: ${response.statusCode}');
        _showSnackBar('שגיאה ביצירת השאלון: ${response.statusCode}', isError: true);
      }
    } catch (e) {
      print('❌ Exception during quiz creation: $e');
      _showSnackBar('שגיאה: ${e.toString()}', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildFileUploadSection() {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: DragTarget<html.File>(
          onWillAccept: (data) {
            setState(() => _isDragging = true);
            return true;
          },
          onAccept: (data) async {
            setState(() => _isDragging = false);
            final extension = data.name.split('.').last.toLowerCase();
            if (_allowedExtensions.contains(extension)) {
              final reader = html.FileReader();
              final completer = Completer<Uint8List>();

              reader.onLoadEnd.listen((event) {
                final result = reader.result as String;
                final bytes = Uint8List.fromList(base64Decode(result.split(',').last));
                completer.complete(bytes);
              });

              reader.readAsDataUrl(data);
              final bytes = await completer.future;

              setState(() {
                _selectedFile = PlatformFile(
                  name: data.name,
                  size: data.size,
                  bytes: bytes,
                );
              });
            } else {
              _showSnackBar('סוג קובץ לא נתמך', isError: true);
            }
          },
          onLeave: (data) => setState(() => _isDragging = false),
          builder: (context, candidateData, rejectedData) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _isDragging ? Color(0xFF667eea).withOpacity(0.1) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isDragging
                      ? Color(0xFF667eea)
                      : _selectedFile != null
                      ? Colors.green.shade300
                      : Colors.grey.shade300,
                  width: 2,
                  style: _isDragging ? BorderStyle.solid : BorderStyle.solid,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Icon and Title
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: (_selectedFile != null ? Colors.green : Color(0xFF667eea)).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _selectedFile != null ? Icons.check_circle : Icons.cloud_upload,
                      size: 40,
                      color: _selectedFile != null ? Colors.green.shade600 : Color(0xFF667eea),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    _selectedFile != null ? 'קובץ נבחר בהצלחה!' : 'העלאת קובץ',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _selectedFile != null ? Colors.green.shade700 : Color(0xFF1F2937),
                    ),
                  ),

                  const SizedBox(height: 8),

                  if (_selectedFile != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.description, color: Colors.green.shade600, size: 20),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              _selectedFile!.name,
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => setState(() => _selectedFile = null),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.red.shade600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Upload Button
                  Container(
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
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF667eea).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _pickFile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.upload_file, color: Colors.white),
                      label: Text(
                        _selectedFile != null ? 'בחר קובץ אחר' : 'בחר קובץ',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // File types info
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade600, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'PDF, Word, PowerPoint • עד 50MB',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDifficultySection() {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Color(0xFF667eea).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.tune,
                      color: Color(0xFF667eea),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'רמת קושי',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Difficulty chips
              Wrap(
                spacing: 12,
                children: _difficulties.map((difficulty) {
                  final isSelected = _selectedDifficulty == difficulty;
                  Color chipColor;
                  Color textColor;
                  switch (difficulty) {
                    case 'קל':
                      chipColor = Colors.green;
                      textColor = isSelected ? Colors.green.shade700 : Colors.grey.shade700;
                      break;
                    case 'בינוני':
                      chipColor = Colors.orange;
                      textColor = isSelected ? Colors.orange.shade700 : Colors.grey.shade700;
                      break;
                    case 'קשה':
                      chipColor = Colors.red;
                      textColor = isSelected ? Colors.red.shade700 : Colors.grey.shade700;
                      break;
                    default:
                      chipColor = Colors.grey;
                      textColor = Colors.grey.shade700;
                  }

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDifficulty = difficulty;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? chipColor.withOpacity(0.1) : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: isSelected ? chipColor : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isSelected ? Icons.check_circle : Icons.circle_outlined,
                            color: isSelected ? chipColor : Colors.grey.shade500,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            difficulty,
                            style: TextStyle(
                              color: textColor,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequirementsSection() {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Color(0xFF667eea).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.edit_note,
                      color: Color(0xFF667eea),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'דרישות מיוחדות',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              TextField(
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'הוסף דרישות מיוחדות כאן... (אופציונלי)',
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Color(0xFF667eea), width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.all(16),
                ),
                onChanged: (value) {
                  setState(() {
                    _specificRequirements = value;
                  });
                },
              ),

              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: Colors.amber.shade700, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'לדוגמה: "התמקד בנושא X", "הוסף שאלות מעשיות", "כלול דוגמאות"',
                        style: TextStyle(
                          color: Colors.amber.shade800,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
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
            'יצירת שאלון חדש',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
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

        body: _isLoading
            ? Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF667eea).withOpacity(0.1),
                Colors.white,
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(32),
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
                      SizedBox(
                        width: 60,
                        height: 60,
                        child: CircularProgressIndicator(
                          strokeWidth: 4,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'יוצר שאלון...',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'זה עלול לקחת כמה דקות',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )
            : SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // File Upload Section
                  _buildFileUploadSection(),

                  const SizedBox(height: 24),

                  // Difficulty Section
                  _buildDifficultySection(),

                  const SizedBox(height: 24),

                  // Requirements Section
                  _buildRequirementsSection(),

                  const SizedBox(height: 32),

                  // Info Section
                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF667eea).withOpacity(0.1),
                              Color(0xFF764ba2).withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Color(0xFF667eea).withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              color: Color(0xFF667eea),
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'השאלון יכלול 10 שאלות רב-ברירה בעברית על בסיס התוכן שהעלת',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF667eea),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Create Button
                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: (_selectedFile != null && _selectedDifficulty != null)
                                ? [
                              Color(0xFF667eea),
                              Color(0xFF764ba2),
                            ]
                                : [
                              Colors.grey.shade400,
                              Colors.grey.shade500,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: (_selectedFile != null && _selectedDifficulty != null)
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
                          onPressed: (_selectedFile != null && _selectedDifficulty != null && !_isLoading)
                              ? _createQuiz
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isLoading) ...[
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'יוצר שאלון...',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ] else ...[
                                Icon(
                                  Icons.auto_awesome,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'צור שאלון',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}