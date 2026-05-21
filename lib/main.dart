import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';

import 'screens/auth/login_screen.dart';

import 'screens/employee/employee_home.dart';
import 'screens/manager/manager_dashboard.dart';
import 'screens/admin/admin_panel.dart';
import 'screens/splash_screen.dart';


void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {

  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {

    return MaterialApp(

      debugShowCheckedModeBanner: false,

      title: 'qdesk',

      theme: ThemeData(

        brightness: Brightness.dark,

        scaffoldBackgroundColor:
        const Color(0xFF0B1020),

        primaryColor:
        const Color(0xFFD4AF37),

        colorScheme: ColorScheme.dark(

          primary:
          const Color(0xFFD4AF37),

          secondary:
          const Color(0xFFD4AF37),
        ),

        appBarTheme: const AppBarTheme(

          backgroundColor:
          Color(0xFF111827),

          foregroundColor: Colors.white,

          elevation: 0,
        ),

        elevatedButtonTheme:
        ElevatedButtonThemeData(

          style: ElevatedButton.styleFrom(

            backgroundColor:
            const Color(0xFFD4AF37),

            foregroundColor:
            Colors.black,

            shape: RoundedRectangleBorder(

              borderRadius:
              BorderRadius.circular(14),
            ),
          ),
        ),

        cardColor:
        const Color(0xFF1F2937),

      ),

      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/auth': (context) => const AuthWrapper(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {

  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {

    return StreamBuilder<User?>(

      stream:
      FirebaseAuth.instance.authStateChanges(),

      builder: (context, snapshot) {

        // Loading
        if (snapshot.connectionState ==
            ConnectionState.waiting) {

          return const Scaffold(
            body: Center(
              child:
              CircularProgressIndicator(),
            ),
          );
        }

        // User NOT logged in
        if (!snapshot.hasData) {

          return const LoginScreen();
        }

        // User logged in
        final uid = snapshot.data!.uid;

        return FutureBuilder<DocumentSnapshot>(

          future: FirebaseFirestore.instance
              .collection("users")
              .doc(uid)
              .get(),

          builder: (context, roleSnapshot) {

            if (!roleSnapshot.hasData) {

              return const Scaffold(
                body: Center(
                  child:
                  CircularProgressIndicator(),
                ),
              );
            }

            // Document might not exist yet
            if (!roleSnapshot.data!.exists) {
              return const EmployeeHome();
            }

            final data =
            roleSnapshot.data!.data()
            as Map<String, dynamic>;

            final role = data["role"] ?? "employee";


            // Block inactive users
            if (data['isActive'] == false) {
              FirebaseAuth.instance.signOut();
              return const LoginScreen();
            }

// ADMIN
            if (role == "admin") {
              return const AdminPanel();
            }

// MANAGER
            if (role == "manager") {
              return const ManagerDashboard();
            }

// EMPLOYEE
            return const EmployeeHome();
          },
        );
      },
    );
  }
}