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

class _CreateQuizPageState extends State<CreateQuizPage> {
  String? _selectedDifficulty;
  String _specificRequirements = '';
  PlatformFile? _selectedFile;
  bool _isDragging = false;
  bool _isLoading = false;

  final List<String> _difficulties = ['קל', 'בינוני', 'קשה'];
  final List<String> _allowedExtensions = ['pdf', 'doc', 'docx', 'ppt', 'pptx'];

  // Map Hebrew difficulty levels to English for the API
  final Map<String, String> _difficultyMapping = {
    'קל': 'easy',
    'בינוני': 'medium',
    'קשה': 'hard',
  };

  // Base URL for the API - update this with your actual server URL
  final String _apiBaseUrl = 'http://localhost:8001';

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('שגיאה בהעלאת הקובץ')),
      );
    }
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('נא להעלות קובץ תחילה')),
      );
      return;
    }

    if (_selectedDifficulty == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('נא לבחור רמת קושי')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get authentication token
      String? authToken = await _getAuthToken();

      if (authToken == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('שגיאה: לא נמצא טוקן אוטנטיקציה. נא להתחבר מחדש.')),
        );
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
          'file',  // *** שונה מ-document_file ל-file
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

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('השאלון נוצר בהצלחה: ${newQuiz.title}')),
          );

          // Navigate back to the home page
          Navigator.of(context).pop();
        } catch (e) {
          print('❌ Error processing server response: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('שגיאה בעיבוד תשובת השרת')),
          );
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        // Authentication error - redirect to login
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('שגיאת אוטנטיקציה. נא להתחבר מחדש.')),
        );
        // You might want to redirect to login page here
      } else {
        print('❌ Server error: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה ביצירת השאלון: ${response.statusCode} - $responseBody')),
        );
      }
    } catch (e) {
      print('❌ Exception during quiz creation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('שגיאה: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('יצירת שאלון חדש'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: _isLoading
            ? const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('יוצר שאלון...', style: TextStyle(fontSize: 16)),
              SizedBox(height: 8),
              Text('זה עלול לקחת כמה דקות', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        )
            : Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DragTarget<html.File>(
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('סוג קובץ לא נתמך')),
                    );
                  }
                },
                onLeave: (data) => setState(() => _isDragging = false),
                builder: (context, candidateData, rejectedData) {
                  return Card(
                    color: _isDragging ? Colors.blue.shade50 : null,
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.upload_file, color: Theme.of(context).primaryColor),
                              const SizedBox(width: 8),
                              const Text(
                                'העלאת קובץ',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (_selectedFile != null) ...[
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                border: Border.all(color: Colors.green.shade200),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _selectedFile!.name,
                                      style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w500),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 20),
                                    onPressed: () => setState(() => _selectedFile = null),
                                    color: Colors.red.shade600,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          OutlinedButton.icon(
                            onPressed: _pickFile,
                            icon: const Icon(Icons.upload_file),
                            label: const Text('העלה קובץ PDF/Word/PowerPoint'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'ניתן להעלות קבצי PDF, Word או PowerPoint • גודל מקסימלי: 50MB',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.tune, color: Theme.of(context).primaryColor),
                          const SizedBox(width: 8),
                          const Text(
                            'רמת קושי',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedDifficulty,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        hint: const Text('בחר רמת קושי'),
                        items: _difficulties.map((String difficulty) {
                          return DropdownMenuItem<String>(
                            value: difficulty,
                            child: Text(difficulty),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedDifficulty = newValue;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.edit_note, color: Theme.of(context).primaryColor),
                          const SizedBox(width: 8),
                          const Text(
                            'דרישות מיוחדות',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        maxLines: 3,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'הוסף דרישות מיוחדות כאן... (אופציונלי)',
                          contentPadding: EdgeInsets.all(16),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _specificRequirements = value;
                          });
                        },
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'לדוגמה: "התמקד בנושא X", "הוסף שאלות מעשיות", "כלול דוגמאות"',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'השאלון יכלול 10 שאלות רב-ברירה בעברית על בסיס התוכן שהעלת',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: (_selectedFile != null && _selectedDifficulty != null && !_isLoading)
                    ? _createQuiz
                    : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isLoading) ...[
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text('יוצר שאלון...', style: TextStyle(fontSize: 18)),
                    ] else ...[
                      const Icon(Icons.auto_awesome),
                      const SizedBox(width: 8),
                      const Text('צור שאלון', style: TextStyle(fontSize: 18)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}