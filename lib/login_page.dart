import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'ברוכים הבאים ל-Quizzy',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),
                const Text(
                  'אפליקציית השאלונים החכמה',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 60),
                if (authService.isLoading)
                  const CircularProgressIndicator()
                else
                  ElevatedButton.icon(
                    onPressed: () async {
                      final a = 0;
                      final success = await authService.signInWithGoogle();
                      if (success && mounted && authService.currentUser != null) {
                        Navigator.of(context).pushReplacementNamed('/');
                      }
                    },
                    icon: Image.asset(
                      'assets/images/google_logo.png',
                      height: 24,
                    ),
                    label: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      child: Text('התחבר עם Google', style: TextStyle(fontSize: 16)),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      elevation: 2,
                    ),
                  ),
                const SizedBox(height: 20),
                if (authService.error != null)
                  Text(
                    authService.error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}