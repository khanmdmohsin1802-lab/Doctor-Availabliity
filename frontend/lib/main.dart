import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:curasync/config/theme.dart';
import 'package:curasync/providers/auth_provider.dart';
import 'package:curasync/screens/auth/register_screen.dart';
import 'package:curasync/screens/auth/login_screen.dart';
import 'package:curasync/screens/patient/patient_home_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const CuraSyncApp(),
    ),
  );
}

class CuraSyncApp extends StatefulWidget {
  const CuraSyncApp({super.key});

  @override
  State<CuraSyncApp> createState() => _CuraSyncAppState();
}

class _CuraSyncAppState extends State<CuraSyncApp> {
  late Future<void> _initSessionFuture;

  @override
  void initState() {
    super.initState();
    // Load the session when the app starts
    _initSessionFuture = context.read<AuthProvider>().loadSession();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CuraSync',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: FutureBuilder(
        future: _initSessionFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          return Consumer<AuthProvider>(
            builder: (context, auth, child) {
              if (auth.isLoggedIn) {
                if (auth.isDoctor) {
                  return const PlaceholderScreen(title: 'Doctor Dashboard');
                } else {
                  return const PatientHomeScreen();
                }
              }
              return const RegisterScreen();
            },
          );
        },
      ),
      routes: {
        '/register': (context) => const RegisterScreen(),
        '/login': (context) => const LoginScreen(),
        '/doctor-dashboard': (context) => const PlaceholderScreen(title: 'Doctor Dashboard'),
        '/patient-home': (context) => const PatientHomeScreen(),
      },
    );
  }
}

// Temporary placeholder screen for routing
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthProvider>().logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          )
        ],
      ),
      body: Center(
        child: Text('Welcome to $title!'),
      ),
    );
  }
}
