import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text("User not logged in")),
      );
    }

    // Use collection group with fallback for missing timestamp
    final notificationsStream = FirebaseFirestore.instance
        .collection("notifications")
        .where("userId", isEqualTo: userId)
        .snapshots(); // remove orderBy to prevent empty results if timestamp missing

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: notificationsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildNoNotificationsMessage();
          }

          final notifications = snapshot.data!.docs;

          // Sort manually by timestamp if available
          notifications.sort((a, b) {
            final aTimestamp = a.get("timestamp") as Timestamp?;
            final bTimestamp = b.get("timestamp") as Timestamp?;
            if (aTimestamp != null && bTimestamp != null) {
              return bTimestamp.compareTo(aTimestamp);
            }
            return 0;
          });

          return ListView.builder(
            padding: const EdgeInsets.all(12.0),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notificationDoc = notifications[index];
              final notification = notificationDoc.data() as Map<String, dynamic>;
              final String title = notification["title"] ?? "No Title";
              final String message = notification["message"] ?? "No Message";
              final String iconKey = notification["icon"] ?? "default";
              final bool read = notification["read"] ?? false;

              IconData icon;
              switch (iconKey) {
                case "schedule":
                  icon = Icons.calendar_today;
                  break;
                case "location":
                  icon = Icons.place;
                  break;
                case "reward":
                  icon = Icons.star;
                  break;
                case "tip":
                  icon = Icons.lightbulb_outline;
                  break;
                default:
                  icon = Icons.notifications;
              }

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  onTap: () {
                    if (!read) {
                      notificationDoc.reference.update({'read': true});
                    }
                  },
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.green.shade50,
                        child: Icon(icon, color: Colors.green),
                      ),
                      if (!read)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Text(
                    title,
                    style: TextStyle(
                      fontWeight: read ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(message),
                  trailing: const Icon(Icons.arrow_forward_ios,
                      size: 16, color: Colors.grey),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildNoNotificationsMessage() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            "No new notifications yet.",
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          Text(
            "Check back later for updates!",
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
