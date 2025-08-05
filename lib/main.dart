import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_page.dart';
import 'home_page.dart';
import 'background_location_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://bayhdtjxtvmefclngraf.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJheWhkdGp4dHZtZWZjbG5ncmFmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDg0NTkzNDksImV4cCI6MjA2NDAzNTM0OX0.gwPzeh7k-x4y-vOYRvbsVupCFBQhzf9Q9CSTOA6nNAw',
  );

  final supabase = Supabase.instance.client;
  final session = supabase.auth.currentSession;

  if (session != null) {
    await initializeService();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Proyecto final',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const AuthWrapper(),
      routes: {'/home': (_) => const HomePage()},
      onGenerateRoute: (settings) {
        // Maneja rutas no definidas
        return MaterialPageRoute(builder: (_) => const AuthWrapper());
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final session = supabase.auth.currentSession;

    // Verifica si hay sesión activa
    return session != null ? const HomePage() : const AuthPage();
  }
}
