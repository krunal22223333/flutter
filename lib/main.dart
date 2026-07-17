import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'services/notifications.dart';
import 'theme.dart';
import 'services/api.dart';
import 'screens/login.dart';
import 'screens/video_splash.dart';
import 'screens/home.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
  await NotificationService.init();
  runApp(const HcpHrmsApp());
}

class HcpHrmsApp extends StatelessWidget {
  const HcpHrmsApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HCP HRMS',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const VideoSplashScreen(next: _Gate()),
    );
  }
}

/// Decides the first screen based on saved token.
class _Gate extends StatefulWidget {
  const _Gate();
  @override
  State<_Gate> createState() => _GateState();
}

class _GateState extends State<_Gate> {
  bool _checking = true;
  bool _loggedIn = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final token = await Api.getToken();
    setState(() { _loggedIn = token != null && token.isNotEmpty; _checking = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _loggedIn ? const HomeScreen() : const LoginScreen();
  }
}
