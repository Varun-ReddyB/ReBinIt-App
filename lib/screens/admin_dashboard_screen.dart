import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'constants.dart';
import 'auth/login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final String adminId;

  const AdminDashboardScreen({super.key, required this.adminId});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _statuses = ['Reports', 'Pickups', 'Users'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statuses.length, vsync: this);
  }

  // Admin stats stream
  Stream<DocumentSnapshot<Map<String, dynamic>>> getAdminStatsStream() {
    return FirebaseFirestore.instance
        .collection(adminsCollection)
        .doc(widget.adminId)
        .snapshots();
  }

  // Reports stream
  Stream<QuerySnapshot<Map<String, dynamic>>> getReportsStream({String? status}) {
    Query<Map<String, dynamic>> query =
        FirebaseFirestore.instance.collection(wasteReportsCollection);

    if (status != null && status != 'All') {
      query = query.where('status', isEqualTo: status);
    }

    return query.orderBy('timestamp', descending: true).snapshots();
  }

  // Pickups stream
  Stream<QuerySnapshot<Map<String, dynamic>>> getPickupsStream() {
    return FirebaseFirestore.instance
        .collection('waste_pickups')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Admin Dashboard",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          tabs: _statuses.map((s) => Tab(text: s)).toList(),
          indicatorColor: Colors.white,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildAdminStatsSection(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _statuses.map((status) {
                if (status == 'Users') return _buildUsersTab();
                if (status == 'Pickups') return _buildPickupsTab();
                return _buildFilteredReports(status);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Admin Stats Section ----------------
  Widget _buildAdminStatsSection() {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: getAdminStatsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(),
          );
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("Admin data not found"),
          );
        }

        final data = snapshot.data!.data() ?? {};
        final username = data['username'] ?? 'Admin';
        final earnings = data['earnings'] ?? 0;
        final pickups = data['pickups'] ?? 0;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Welcome, $username",
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: AdminStatCard(
                      icon: Icons.attach_money,
                      label: "Total Earnings",
                      value: "\$$earnings",
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AdminStatCard(
                      icon: Icons.recycling,
                      label: "Total Pickups",
                      value: "$pickups",
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
            ],
          ),
        );
      },
    );
  }

  // ---------------- Reports Tab ----------------
  Widget _buildFilteredReports(String status) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: getReportsStream(status: status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error fetching reports: ${snapshot.error}"));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text("No reports available", style: TextStyle(color: Colors.grey)),
          );
        }

        final reports = snapshot.data!.docs;
        return ListView.builder(
          itemCount: reports.length,
          itemBuilder: (context, index) {
            final data = reports[index].data();
            final docId = reports[index].id;
            return AdminReportTile(data: data, reportId: docId, adminId: widget.adminId);
          },
        );
      },
    );
  }

  // ---------------- Pickups Tab ----------------
  Widget _buildPickupsTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: getPickupsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No pickups found"));
        }

        final pickups = snapshot.data!.docs;

        return ListView.builder(
          itemCount: pickups.length,
          itemBuilder: (context, index) {
            final data = pickups[index].data();
            final pickupId = pickups[index].id;
            final userId = data['userId'];

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const Icon(Icons.local_shipping, color: Colors.green),
                title: Text(data['wasteType'] ?? 'Unknown Type',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Address: ${data['address'] ?? 'N/A'}"),
                    Text("Contact: ${data['contact'] ?? 'N/A'}"),
                    Text("Quantity: ${data['totalQuantity'] ?? 0}"),
                    Text("Status: ${data['status'] ?? 'N/A'}"),
                    Text(
                      data['timestamp'] != null
                          ? DateFormat('dd MMM yyyy, hh:mm a')
                              .format((data['timestamp'] as Timestamp).toDate())
                          : "No Date",
                    ),
                  ],
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'Complete' && userId != null) {
                      final pickupRef = FirebaseFirestore.instance
                          .collection('waste_pickups')
                          .doc(pickupId);
                      final userRef =
                          FirebaseFirestore.instance.collection('users').doc(userId);
                      final adminRef =
                          FirebaseFirestore.instance.collection(adminsCollection).doc(widget.adminId);

                      // Update pickup status
                      await pickupRef.update({'status': 'Completed'});

                      // Transaction: update user points/money & admin earnings
                      await FirebaseFirestore.instance.runTransaction((transaction) async {
                        final userSnap = await transaction.get(userRef);
                        final adminSnap = await transaction.get(adminRef);

                        if (!userSnap.exists || !adminSnap.exists) return;

                        final pointsToAdd = data['points'] ?? 10;
                        final moneyToAdd = data['money'] ?? 5;

                        transaction.update(userRef, {
                          'points': (userSnap['points'] ?? 0) + pointsToAdd,
                          'money': (userSnap['money'] ?? 0) + moneyToAdd,
                        });

                        transaction.update(adminRef, {
                          'earnings': (adminSnap['earnings'] ?? 0) + moneyToAdd,
                        });
                      });

                      // Firestore notification
                      await FirebaseFirestore.instance.collection('notifications').add({
                        'title': 'Pickup Completed 🎉',
                        'message':
                            'Your pickup has been completed. You earned ₹${data['money'] ?? 5} and ${data['points'] ?? 10} points!',
                        'icon': 'reward',
                        'userId': userId,
                        'read': false,
                        'timestamp': FieldValue.serverTimestamp(),
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Pickup marked as Completed and user updated')),
                      );
                    } else if (value == 'Delete') {
                      await FirebaseFirestore.instance
                          .collection('waste_pickups')
                          .doc(pickupId)
                          .delete();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Pickup deleted')),
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'Complete', child: Text('Mark as Completed')),
                    const PopupMenuItem(value: 'Delete', child: Text('Delete')),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ---------------- Users Tab ----------------
  Widget _buildUsersTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No users found"));
        }

        final users = snapshot.data!.docs;
        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index].data();
            final userId = users[index].id;
            final role = user['role'] ?? 'user';

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: const Icon(Icons.person, color: Colors.green),
                title: Text(user['username'] ?? 'Unknown User',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(user['email'] ?? ''),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'delete') {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text("Delete User"),
                          content: const Text("Are you sure you want to delete this user?"),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text("Cancel")),
                            TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text("Delete", style: TextStyle(color: Colors.red))),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await FirebaseFirestore.instance.collection('users').doc(userId).delete();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("User deleted successfully")),
                        );
                      }
                    } else if (value == 'promote') {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(userId)
                          .update({'role': 'admin'});
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("User promoted to Admin")),
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    if (role != 'admin')
                      const PopupMenuItem(value: 'promote', child: Text('Promote to Admin')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete User')),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ---------------- Stat Card ----------------
class AdminStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const AdminStatCard({super.key, required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: Colors.green, size: 30),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 4),
            Text(label),
          ],
        ),
      ),
    );
  }
}

// ---------------- Report Tile ----------------
class AdminReportTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final String reportId;
  final String adminId;

  const AdminReportTile({super.key, required this.data, required this.reportId, required this.adminId});

  @override
  Widget build(BuildContext context) {
    final timestamp = data['timestamp'] as Timestamp?;
    String formattedDate = timestamp != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(timestamp.toDate())
        : "N/A";

    String status = data['status'] ?? 'Pending';
    final userId = data['userId'];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(Icons.recycling, color: Colors.green.shade400),
        title: Text(data['type'] ?? 'Unknown Type',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Location: ${data['location'] ?? 'Not provided'}"),
            Text("User: ${data['user'] ?? 'Anonymous'}"),
            Text("Date: $formattedDate"),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text("Status: "),
                DropdownButton<String>(
                  value: status,
                  items: ['Pending', 'Completed', 'Rejected']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (newValue) async {
                    if (newValue == null || userId == null) return;

                    final reportRef = FirebaseFirestore.instance
                        .collection(wasteReportsCollection)
                        .doc(reportId);
                    final userRef =
                        FirebaseFirestore.instance.collection('users').doc(userId);
                    final adminRef = FirebaseFirestore.instance
                        .collection(adminsCollection)
                        .doc(adminId);

                    final reportSnapshot = await reportRef.get();
                    final previousStatus = reportSnapshot['status'] ?? 'Pending';

                    await reportRef.update({'status': newValue});

                    if (previousStatus != 'Completed' && newValue == 'Completed') {
                      final pointsToAdd = reportSnapshot['points'] ?? 10;
                      final moneyToAdd = reportSnapshot['money'] ?? 5;

                      await FirebaseFirestore.instance.runTransaction((transaction) async {
                        final userSnapshot = await transaction.get(userRef);
                        final adminSnapshot = await transaction.get(adminRef);

                        if (!userSnapshot.exists || !adminSnapshot.exists) return;

                        final currentPoints = userSnapshot['points'] ?? 0;
                        final currentMoney = userSnapshot['money'] ?? 0;
                        final currentEarnings = adminSnapshot['earnings'] ?? 0;

                        transaction.update(userRef, {
                          'points': currentPoints + pointsToAdd,
                          'money': currentMoney + moneyToAdd,
                        });

                        transaction.update(adminRef, {
                          'earnings': currentEarnings + moneyToAdd,
                        });
                      });

                      await FirebaseFirestore.instance.collection('notifications').add({
                        'title': 'Pickup Completed 🎉',
                        'message': 'Your waste report has been completed. You earned ₹$moneyToAdd and $pointsToAdd points!',
                        'icon': 'reward',
                        'userId': userId,
                        'read': false,
                        'timestamp': FieldValue.serverTimestamp(),
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Status updated and user notified')),
                      );
                    } else if (newValue == 'Rejected') {
                      await FirebaseFirestore.instance.collection('notifications').add({
                        'title': 'Pickup Rejected ❌',
                        'message': 'Your waste report was rejected. Please review and try again.',
                        'icon': 'alert',
                        'userId': userId,
                        'read': false,
                        'timestamp': FieldValue.serverTimestamp(),
                      });
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- Full Image Screen ----------------
class FullImageScreen extends StatelessWidget {
  final String imageUrl;

  const FullImageScreen({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.green,
          iconTheme: const IconThemeData(color: Colors.white)),
      body: Center(
        child: Hero(
          tag: imageUrl,
          child: Image.network(imageUrl, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
