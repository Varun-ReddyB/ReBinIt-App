import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'home_screen.dart';
import 'admin_dashboard_screen.dart';
import 'constants.dart'; // Import the constants file

class RoleChecker extends StatelessWidget {
  const RoleChecker({super.key});

  Future<String> getUserRole(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection(usersCollection).doc(uid).get();
      // If the document exists, return the role. If not, or if the role field is missing, default to 'user'.
      return doc.data()?['role'] ?? 'user';
    } catch (e) {
      // In case of any error (e.g., network issues), default to 'user'
      return 'user';
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off, size: 80, color: Colors.grey),
              SizedBox(height: 16),
              Text("No user logged in", style: TextStyle(fontSize: 16, color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return FutureBuilder<String>(
      future: getUserRole(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.green),
                  SizedBox(height: 16),
                  Text("Checking user role...", style: TextStyle(color: Colors.green)),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 80, color: Colors.red),
                  const SizedBox(height: 16),
                  Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)),
                ],
              ),
            ),
          );
        }
        
        // Use the snapshot data directly
        final role = snapshot.data;

        if (role == "admin") {
          return AdminDashboardScreen(adminId: user.uid);
        } else {
          return HomeScreen(userId: user.uid);
        }
      },
    );
  }
}