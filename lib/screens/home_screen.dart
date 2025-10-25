// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'sell_waste_screen.dart';
import 'constants.dart';

class HomeScreen extends StatefulWidget {
  final String userId;

  const HomeScreen({super.key, required this.userId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ignore: unused_element
  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Logout")),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // StreamBuilder on wastePickups to calculate earnings and pickups dynamically
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(wastePickupsCollection)
          .where("userId", isEqualTo: widget.userId)
          .snapshots(),
      builder: (context, pickupSnapshot) {
        if (pickupSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        final pickupDocs = pickupSnapshot.data?.docs ?? [];

        // Calculate total earnings and pickup count
        double earnings = 0.0;
        int pickups = pickupDocs.length;

        for (var doc in pickupDocs) {
          final data = doc.data() as Map<String, dynamic>? ?? {};
          final status = (data['status'] as String?)?.toLowerCase() ?? 'pending';
          final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;

          if (status == 'completed') {
            earnings += amount;
          }
        }

        // StreamBuilder for user info
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection(usersCollection)
              .doc(widget.userId)
              .snapshots(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                  body: Center(child: CircularProgressIndicator()));
            }

            final userData =
                userSnapshot.data?.data() as Map<String, dynamic>? ?? {};
            final username = userData['username'] ?? "User";

            return Scaffold(
              backgroundColor: const Color(0xFFF5FBEF),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Hi, $username",
                        style: const TextStyle(
                            fontSize: 28, fontWeight: FontWeight.bold)),
                    const Text("Let's contribute to a cleaner earth.",
                        style: TextStyle(color: Colors.grey, fontSize: 16)),
                    const SizedBox(height: 25),

                    _buildCTACard(),
                    const SizedBox(height: 25),

                    const Text("Recycle Categories",
                        style:
                            TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CategoryIcon(
                          icon: Icons.local_drink,
                          label: "Plastic",
                          onTap: () => _showMaterialDialog(context, "Plastic"),
                        ),
                        CategoryIcon(
                          icon: Icons.delete,
                          label: "Metal",
                          onTap: () => _showMaterialDialog(context, "Metal"),
                        ),
                        CategoryIcon(
                          icon: Icons.checkroom,
                          label: "Clothes",
                          onTap: () => _showMaterialDialog(context, "Clothes"),
                        ),
                        CategoryIcon(
                          icon: Icons.local_mall,
                          label: "Glass",
                          onTap: () => _showMaterialDialog(context, "Glass"),
                        ),
                        CategoryIcon(
                          icon: Icons.recycling,
                          label: "Other",
                          onTap: () => _showMaterialDialog(context, "Other"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    Row(
                      children: [
                        Expanded(
                            child: StatCard(
                                value: "₹${earnings.toStringAsFixed(2)}",
                                label: "Earned",
                                icon: Icons.currency_rupee)),
                        const SizedBox(width: 10),
                        Expanded(
                            child: StatCard(
                                value: "$pickups",
                                label: "Pickups",
                                icon: Icons.local_shipping)),
                      ],
                    ),
                    const SizedBox(height: 30),

                    const Text("Recent Pickups",
                        style:
                            TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    _buildRecentActivityList(),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCTACard() {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            colors: [Colors.green.shade400, Colors.green.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Have waste to sell?",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              const SizedBox(height: 8),
              const Text(
                "Schedule a free pickup and earn points!",
                style: TextStyle(fontSize: 14, color: Colors.white70),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const SellWasteScreen()));
                },
                icon: const Icon(Icons.add_shopping_cart, color: Colors.green),
                label: const Text("Schedule a Pickup",
                    style: TextStyle(color: Colors.green)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMaterialDialog(BuildContext context, String material) {
    final Map<String, Map<String, List<String>>> materialGuidelines = {
      "Plastic": {
        "Do": [
          "Rinse containers before recycling",
          "Separate plastic types if required",
          "Use reusable plastic bags"
        ],
        "Don't": [
          "Don't recycle plastic bags with regular plastics",
          "Don't throw food-contaminated plastics in recycling",
          "Don't burn plastic waste"
        ],
      },
      "Metal": {
        "Do": [
          "Clean and sort metals",
          "Separate aluminum and steel",
          "Remove non-metal attachments"
        ],
        "Don't": [
          "Don't mix hazardous metals with regular metal waste",
          "Don't throw rusty metals in regular trash",
        ],
      },
      "Clothes": {
        "Do": [
          "Donate gently used clothes",
          "Separate by fabric type if possible",
          "Repair before recycling"
        ],
        "Don't": [
          "Don't recycle wet or moldy clothes",
          "Don't mix with non-textile materials"
        ],
      },
      "Glass": {
        "Do": [
          "Rinse jars and bottles",
          "Separate colored and clear glass",
          "Handle carefully to avoid breakage"
        ],
        "Don't": [
          "Don't throw broken glass in regular trash without protection",
          "Don't mix glass with ceramics or porcelain"
        ],
      },
      "Other": {
        "Do": [
          "Sort e-waste and hazardous items separately",
          "Check local recycling guidelines"
        ],
        "Don't": [
          "Don't mix hazardous waste with regular trash",
          "Don't dispose of batteries or electronics in normal bins"
        ],
      },
    };

    final guidelines = materialGuidelines[material] ?? {"Do": [], "Don't": []};

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Recycling Dos and Don'ts for $material"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("✅ Do:", style: TextStyle(fontWeight: FontWeight.bold)),
              ...guidelines["Do"]!.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text("• $item"),
                  )),
              const SizedBox(height: 8),
              const Text("❌ Don't:",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ...guidelines["Don't"]!.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text("• $item"),
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(wastePickupsCollection)
          .where("userId", isEqualTo: widget.userId)
          .orderBy("timestamp", descending: true)
          .limit(3)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text("No recent pickups to display.",
              style: TextStyle(color: Colors.grey));
        }

        final recentPickups = snapshot.data!.docs;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: recentPickups.length,
          itemBuilder: (context, index) {
            final data =
                recentPickups[index].data() as Map<String, dynamic>? ?? {};
            final timestamp = data['timestamp'] as Timestamp?;
            final formattedDate = timestamp != null
                ? DateFormat('MMM dd, hh:mm a').format(timestamp.toDate())
                : 'N/A';

            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                leading: const Icon(Icons.local_shipping, color: Colors.green),
                title: Text(
                    "${data['wasteType'] ?? 'Waste Pickup'} - ${data['totalQuantity'] ?? 0} kg"),
                subtitle: Text("Status: ${data['status'] ?? 'Pending'}"),
                trailing: Text(formattedDate,
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ),
            );
          },
        );
      },
    );
  }
}

class CategoryIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const CategoryIcon(
      {super.key, required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.green, size: 30),
          ),
          const SizedBox(height: 8),
          Text(label,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const StatCard(
      {super.key, required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          children: [
            Icon(icon, color: Colors.green, size: 30),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
