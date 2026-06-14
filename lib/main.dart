import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'services/service_locator.dart' as di;
import 'features/auth/presentation/screens/login_screen.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize Dependency Injection
  await di.init();

  // Get available cameras
  cameras = await availableCameras();

  runApp(const MotionIQApp());
}

class MotionIQApp extends StatelessWidget {
  const MotionIQApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Global providers can go here
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'MotionIQ',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
          textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
        ),
        // Start at LoginScreen to handle authentication properly
        home: const LoginScreen(),
      ),
    );
  }
}
