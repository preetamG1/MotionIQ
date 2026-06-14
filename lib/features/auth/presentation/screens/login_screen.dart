import 'package:flutter/material.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../services/service_locator.dart';
import '../../../../features/workout/presentation/screens/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    final user = await sl<FirebaseService>().signInWithGoogle();
    setState(() => _isLoading = false);

    if (user != null && mounted) {
      _navigateToHome();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login failed. Using offline mode instead.")),
      );
      _navigateToHome(); // Fallback to offline mode
    }
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(30),
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade900, Colors.blue.shade500],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            const Icon(Icons.fitness_center, size: 110, color: Colors.white),
            const SizedBox(height: 20),
            const Text(
              "MotionIQ",
              style: TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
            const Text(
              "PRO AI FITNESS COACH",
              style: TextStyle(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.w600, letterSpacing: 2),
            ),
            const Spacer(),
            if (_isLoading)
              const CircularProgressIndicator(color: Colors.white)
            else ...[
              ElevatedButton.icon(
                onPressed: _handleGoogleLogin,
                icon: const Icon(Icons.login, size: 24),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue.shade900,
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  elevation: 5,
                ),
                label: const Text(
                  "Continue with Google",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 15),
              TextButton(
                onPressed: _navigateToHome,
                style: TextButton.styleFrom(foregroundColor: Colors.white70),
                child: const Text(
                  "Train Offline (No Account)",
                  style: TextStyle(fontSize: 16, decoration: TextDecoration.underline),
                ),
              ),
            ],
            const SizedBox(height: 40),
            const Text(
              "100% Offline AI Detection • Auto-Cloud Sync",
              style: TextStyle(color: Colors.white54, fontSize: 11),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
