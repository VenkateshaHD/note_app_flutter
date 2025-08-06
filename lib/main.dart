import 'package:flutter/material.dart';
import 'package:note_app/screens/create_note.dart';
import 'package:note_app/screens/notes.dart';
import 'package:note_app/screens/sign_in.dart';
import 'package:note_app/screens/signup.dart';

void main() {
   WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: SignInScreen(),
      routes: {
        "/sign_in": (context) => const SignInScreen(),
        "/sign_up": (context) => const SignUpScreen(),
        "/notes": (context) => const NotesCloudDashboard(),
        "/create_note": (context) => const CreateNoteScreen(),
      },
    );
  }
}


