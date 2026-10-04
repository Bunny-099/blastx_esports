import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';
import 'features/splash/providers/splash_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Handle Flutter framework UI errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Framework Error: ${details.exception}');
  };

  // Handle unhandled async Platform & Dart errors to prevent process crash
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Unhandled Async Error: $error\n$stack');
    return true; // Keeps app process running safely
  };

  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  final container = ProviderContainer();
  try {
    await container.read(storageServiceProvider).init();
  } catch (e) {
    debugPrint('StorageService init error: $e');
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MyApp(),
    ),
  );
}
