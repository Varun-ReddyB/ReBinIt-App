import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'constants.dart';

class RewardsScreen extends StatelessWidget {
  final String userId;

  const RewardsScreen({super.key, required this.userId});

  Future<void> _redeemReward(
      BuildContext context, int cost, String rewardName) async {
    final userRef = FirebaseFirestore.instance.collection(usersCollection).doc(userId);
    final rewardHistoryRef = userRef.collection(rewardsHistoryCollection);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final userDoc = await transaction.get(userRef);
        final currentPoints = (userDoc.data()?["points"] ?? 0) as int;

        if (currentPoints < cost) {
          throw Exception("Not enough points to redeem.");
        }

        transaction.update(userRef, {"points": currentPoints - cost});
        transaction.set(rewardHistoryRef.doc(), {
          "description": "Redeemed $rewardName",
          "points": -cost,
          "timestamp": FieldValue.serverTimestamp(),
        });
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("You successfully redeemed $rewardName!")),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to redeem: $e")),
        );
      }
    }
  }

  Icon _getRewardIcon(String? iconName) {
    switch (iconName) {
      case "card_giftcard":
        return const Icon(Icons.card_giftcard, color: Colors.deepOrange);
      case "shopping_bag":
        return const Icon(Icons.shopping_bag, color: Colors.blue);
      case "eco":
        return const Icon(Icons.eco, color: Colors.green);
      default:
        return const Icon(Icons.star, color: Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Rewards", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection(usersCollection)
            .doc(userId)
            .snapshots(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
            return const Center(child: Text("User not found"));
          }

          final userData = userSnapshot.data!.data() as Map<String, dynamic>? ?? {};
          final points = userData["points"] ?? 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPointsCard(points),
                const SizedBox(height: 20),
                _buildRewardsSection(context, points),
                const SizedBox(height: 20),
                _buildRewardHistorySection(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPointsCard(int points) {
    return Card(
      elevation: 6,
      color: Colors.green.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.star, color: Colors.green, size: 40),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Your Reward Points",
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                ),
                Text(
                  "$points",
                  style: const TextStyle(
                      fontSize: 40, fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardsSection(BuildContext context, int points) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Available Rewards",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection(rewardsCollection)
              .orderBy("cost")
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("No rewards available"));
            }

            final rewards = snapshot.data!.docs;
            return Column(
              children: rewards.map((doc) {
                final rewardData = doc.data() as Map<String, dynamic>? ?? {};
                final rewardName = rewardData["name"] ?? "Reward";
                final rewardCost = (rewardData["cost"] as num?)?.toInt() ?? 0;
                final rewardIcon = rewardData["icon"] ?? "star";
                final canRedeem = points >= rewardCost;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  elevation: canRedeem ? 4 : 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: _getRewardIcon(rewardIcon),
                    title: Text(rewardName,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("Cost: $rewardCost points"),
                    trailing: ElevatedButton(
                      onPressed: canRedeem
                          ? () => _redeemReward(context, rewardCost, rewardName)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canRedeem ? Colors.green : Colors.grey,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(canRedeem ? "Redeem" : "Locked"),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRewardHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Reward History",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection(usersCollection)
              .doc(userId)
              .collection(rewardsHistoryCollection)
              .orderBy("timestamp", descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("No reward history yet."));
            }

            final history = snapshot.data!.docs;
            return Column(
              children: history.map((doc) {
                final historyData = doc.data() as Map<String, dynamic>? ?? {};
                final description = historyData["description"] ?? "Reward";
                final points = (historyData["points"] as num?)?.toInt() ?? 0;
                final timestamp = historyData["timestamp"] as Timestamp?;
                final formattedDate = timestamp != null
                    ? DateFormat('dd MMM yyyy, hh:mm a').format(timestamp.toDate())
                    : "N/A";
                final isRedeemed = points < 0;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  elevation: 2,
                  child: ListTile(
                    leading: isRedeemed
                        ? const Icon(Icons.arrow_downward, color: Colors.red)
                        : const Icon(Icons.arrow_upward, color: Colors.green),
                    title: Text(description),
                    subtitle: Text(formattedDate),
                    trailing: Text(
                      "$points",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isRedeemed ? Colors.red : Colors.green,
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
