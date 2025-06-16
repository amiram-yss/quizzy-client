import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'user_model.dart';

class AuthService with ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  // Base URL for the API
  final String _apiBaseUrl = 'http://localhost:8001';

  // Getters
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  // Google Sign In instance - תיקון עבור Web (בלי clientId כי זה מוגדר ב-HTML)
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile', 'openid'],
  );

  // Initialize - check if user is already logged in
  Future<void> initialize() async {
    _setLoading(true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user_data');

      if (userData != null) {
        final userMap = json.decode(userData);
        final token = userMap['token'];

        // Verify token with server
        final isValid = await _verifyToken(token);

        if (isValid) {
          _currentUser = User.fromJson(userMap, token);
          notifyListeners();
        } else {
          // Token invalid, clear storage
          await prefs.remove('user_data');
        }
      }
    } catch (e) {
      _setError('שגיאה באתחול: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // פונקציה לתיקון URL תמונת Google
  String _fixGoogleImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return '';
    }

    print('🔧 Original image URL: "$imageUrl"');

    // אם זה URL של Google, נשתמש בפורמט שעובד טוב יותר
    if (imageUrl.contains('googleusercontent.com')) {
      try {
        final uri = Uri.parse(imageUrl);
        final pathSegments = uri.pathSegments;

        // חלץ את ה-ID של התמונה מה-path
        if (pathSegments.length >= 3 && pathSegments[1] == 'a') {
          final imageId = pathSegments[2];

          // צור URL פשוט יותר בלי פרמטרים מיוחדים
          final newUrl = 'https://lh3.googleusercontent.com/a/$imageId';
          print('🔧 Fixed image URL: "$newUrl"');
          return newUrl;
        }
      } catch (e) {
        print('❌ Error parsing Google image URL: $e');
      }
    }

    print('🔧 Using original URL: "$imageUrl"');
    return imageUrl;
  }

  // פונקציה פשוטה ליצירת תמונה עם אותיות ראשונות
  String _generateDefaultImageUrl(String email, String name) {
    // במקום Gravatar, נחזיר URL לשירות תמונות אחר או null
    // כך שה-UI יכול להציג אותיות ראשונות
    print('🖼️ No image available, will use initials for: $email');
    return '';
  }

  // Sign in with Google - עם לוגים מפורטים לדיבוג
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _clearError();

    try {
      print('🚀 Starting Google Sign In process...');

      // בדיקת מצב חיבור נוכחי
      final isCurrentlySignedIn = await _googleSignIn.isSignedIn();
      print('📊 Currently signed in to Google: $isCurrentlySignedIn');

      // תיקון הלוגיקה - אם כבר מחובר, ננתק קודם
      if (isCurrentlySignedIn) {
        print('🔄 Already signed in, signing out first...');
        await _googleSignIn.signOut();
      }

      // התחלת תהליך ההתחברות
      print('👤 Starting Google sign in...');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print('❌ Google sign in was canceled by user');
        _setError('ההתחברות בוטלה על ידי המשתמש');
        return false;
      }

      print('✅ Google user obtained: ${googleUser.email}');
      print('👤 Display name: ${googleUser.displayName}');
      print('🖼️ Photo URL: ${googleUser.photoUrl}');

      // קבלת פרטי אימות
      print('🔐 Getting authentication details...');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      print('🔑 Access Token exists: ${googleAuth.accessToken != null}');
      print('🆔 ID Token exists: ${googleAuth.idToken != null}');

      // ב-Flutter Web, לעיתים קרובות אין ID Token אבל יש Access Token
      String? token = googleAuth.idToken;
      String tokenType = 'id_token';

      if (token == null && googleAuth.accessToken != null) {
        print('⚠️ ID Token is null, using Access Token instead');
        token = googleAuth.accessToken;
        tokenType = 'access_token';
      }

      if (token == null) {
        print('❌ Both ID Token and Access Token are null!');
        _setError('לא נתקבל טוקן מ-Google');
        return false;
      }

      // הדפסת חלק מהטוקן (לא הכל מסיבות אבטחה)
      print('🔍 Token type: $tokenType');
      print('🔍 Token length: ${token.length}');
      print('🔍 Token preview: ${token.substring(0, 50)}...');

      // שליחה לשרת
      print('📡 Sending request to server: $_apiBaseUrl/auth/login');
      final requestBody = {
        'token': token,
        'token_type': tokenType,
        'provider': 'google',
      };
      print('📦 Request body: ${json.encode(requestBody)}');

      final response = await http.post(
        Uri.parse('$_apiBaseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      ).timeout(
        Duration(seconds: 30),
        onTimeout: () {
          print('⏰ Request timed out after 30 seconds');
          throw Exception('זמן חיבור לשרת פג');
        },
      );

      print('📬 Server response status: ${response.statusCode}');
      print('📄 Server response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('📊 Parsed response data: $responseData');

        if (responseData['success'] == true) {
          final userData = responseData['content'];
          final customToken = userData['token'] ?? '';

          print('🖼️ Picture from server: ${userData['picture']}');
          print('📊 Full user data from server: $userData');
          print('🔍 Picture is null: ${userData['picture'] == null}');
          print('🔍 Picture is empty: ${userData['picture'] == ""}');

          print('✅ Login successful with custom token!');
          print('🔑 Custom token length: ${customToken.length}');

          // קביעת תמונת הפרופיל עם fallbacks
          String? finalPictureUrl;
          if (userData['picture'] != null && userData['picture'].toString().isNotEmpty) {
            finalPictureUrl = _fixGoogleImageUrl(userData['picture'].toString());
            print('🖼️ Using fixed picture from server: "$finalPictureUrl"');
          } else if (googleUser.photoUrl != null && googleUser.photoUrl!.isNotEmpty) {
            finalPictureUrl = _fixGoogleImageUrl(googleUser.photoUrl);
            print('🖼️ Using fixed picture from Google: "$finalPictureUrl"');
          } else {
            // אם אין תמונה, נשאיר ריק וה-UI יציג אותיות ראשונות
            finalPictureUrl = _generateDefaultImageUrl(googleUser.email, googleUser.displayName ?? '');
            print('🖼️ No picture available, UI will show initials');
          }

          _currentUser = User(
            id: userData['uid'] ?? '',
            email: userData['email'] ?? googleUser.email,
            name: userData['name'] ?? googleUser.displayName ?? '',
            picture: finalPictureUrl,
            token: customToken,
          );

          print('🖼️ Final user picture: "${_currentUser!.picture}"');

          // שמירה ב-SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          final userJson = _currentUser!.toJson();
          print('💾 Complete user JSON: ${json.encode(userJson)}');
          await prefs.setString('user_data', json.encode(userJson));

          notifyListeners();
          return true;
        } else {
          final errorMessage = responseData['message'] ?? 'שגיאה בהתחברות';
          print('❌ Server returned error: $errorMessage');
          _setError(errorMessage);
          return false;
        }
      } else {
        print('❌ Server error: ${response.statusCode}');
        print('📄 Error response: ${response.body}');
        _setError('שגיאת שרת: ${response.statusCode}');
        return false;
      }
    } on Exception catch (e) {
      print('🚨 Exception caught: ${e.toString()}');
      print('🔍 Exception type: ${e.runtimeType}');

      if (e.toString().contains('network_error')) {
        _setError('בעיית חיבור לאינטרנט');
      } else if (e.toString().contains('sign_in_canceled')) {
        _setError('ההתחברות בוטלה');
      } else {
        _setError('שגיאה בהתחברות: ${e.toString()}');
      }
      return false;
    } catch (e) {
      print('🚨 General error caught: ${e.toString()}');
      print('🔍 Error type: ${e.runtimeType}');
      _setError('שגיאה לא צפויה: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Verify token with server
  Future<bool> _verifyToken(String token) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/auth/verify'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _googleSignIn.signOut();
      _currentUser = null;

      // Clear from shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_data');

      notifyListeners();
    } catch (e) {
      _setError('שגיאה בהתנתקות: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Helper methods
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}