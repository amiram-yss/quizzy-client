import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:html' as html;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';
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
      var uri = Uri.parse('$_apiBaseUrl/generate-quiz/');
      var request = http.MultipartRequest('POST', uri);
      
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
          'document_file',
          fileBytes,
          filename: _selectedFile!.name,
        );
        request.files.add(multipartFile);
      }

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('שגיאה בעיבוד תשובת השרת')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה ביצירת השאלון: ${responseBody}')),
        );
      }
    } catch (e) {
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
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: _isLoading 
        ? const Center(child: CircularProgressIndicator())
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
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'העלאת קובץ',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          if (_selectedFile != null) ...[                            
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _selectedFile!.name,
                                    style: const TextStyle(color: Colors.blue),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () => setState(() => _selectedFile = null),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                          OutlinedButton.icon(
                            onPressed: _pickFile,
                            icon: const Icon(Icons.upload_file),
                            label: const Text('העלה קובץ PDF/Word/PowerPoint'),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'ניתן להעלות קבצי PDF, Word או PowerPoint',
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
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'רמת קושי',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'דרישות מיוחדות',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        maxLines: 3,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'הוסף דרישות מיוחדות כאן...',
                        ),
                        onChanged: (value) {
                          setState(() {
                            _specificRequirements = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _createQuiz,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'צור שאלון',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}