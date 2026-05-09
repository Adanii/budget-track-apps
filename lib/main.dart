import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fin_track/app.dart';
import 'firebase_options.dart'; // Uncomment this after running flutterfire configure

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  // If you haven't run 'flutterfire configure', you might need to do that first.
  // Or manually provide options here for Web.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
    // For now, we continue so the UI can be tested,
    // but Firestore features will fail until properly configured.
  }

  runApp(const ProviderScope(child: FinTrackApp()));
}
