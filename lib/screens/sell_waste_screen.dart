import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // Import for date formatting
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import 'rewards_screen.dart';
import 'constants.dart';

class SellWasteScreen extends StatefulWidget {
  const SellWasteScreen({super.key});

  @override
  State<SellWasteScreen> createState() => _SellWasteScreenState();
}

class _SellWasteScreenState extends State<SellWasteScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _wasteTypeController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _wasteTypeController.dispose();
    _quantityController.dispose();
    _addressController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (mounted) setState(() => _isLoading = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Please login first!")),
          );
          setState(() => _isLoading = false);
        }
        return;
      }

      try {
        final int quantity = int.tryParse(_quantityController.text.trim()) ?? 0;

        // Use a Firestore Transaction for atomic updates
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final userRef = FirebaseFirestore.instance.collection(usersCollection).doc(user.uid);
          final userDoc = await transaction.get(userRef);
          final currentPoints = (userDoc.data()?["points"] ?? 0) as int;

          // Add pickup record
          transaction.set(FirebaseFirestore.instance.collection(wastePickupsCollection).doc(), {
            "userId": user.uid,
            "wasteType": _wasteTypeController.text.trim(),
            "totalQuantity": quantity,
            "address": _addressController.text.trim(),
            "contact": _contactController.text.trim(),
            "status": "Pending",
            "timestamp": FieldValue.serverTimestamp(),
          });

          // Update user points
          transaction.update(userRef, {"points": currentPoints + quantity});
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Pickup submitted! 🎉 You earned $quantity points.")),
          );
        }

        _wasteTypeController.clear();
        _quantityController.clear();
        _addressController.clear();
        _contactController.clear();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e")),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _cancelPickup(String pickupId, int qty) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You are not logged in.")),
        );
      }
      return;
    }

    try {
      // Use a transaction for atomic update and deletion
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final userRef = FirebaseFirestore.instance.collection(usersCollection).doc(user.uid);
        final pickupRef = FirebaseFirestore.instance.collection(wastePickupsCollection).doc(pickupId);

        final userDoc = await transaction.get(userRef);
        final currentPoints = (userDoc.data()?["points"] ?? 0) as int;

        transaction.update(userRef, {"points": currentPoints - qty});
        transaction.delete(pickupRef);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Pickup cancelled ❌ $qty points refunded.")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to cancel pickup: $e")),
        );
      }
    }
  }

  /// ✅ New: Get Current Location and fill address
  Future<void> _fillCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location services are disabled.')),
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied.')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission permanently denied.')),
      );
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      // Reverse geocoding
      List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        _addressController.text =
            "${placemark.street}, ${placemark.locality}, ${placemark.postalCode}, ${placemark.country}";
      } else {
        _addressController.text =
            "Lat: ${position.latitude.toStringAsFixed(5)}, Lng: ${position.longitude.toStringAsFixed(5)}";
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get location: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: CupertinoNavigationBar(
          middle: const Text("Sell Waste"),
        ),
        body: const Center(child: Text("Please login to sell waste.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Sell Waste", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          _buildPointsBadge(context, user.uid),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildSubmissionForm(),
                  const SizedBox(height: 30),
                  _buildPickupList(user.uid),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsBadge(BuildContext context, String userId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection(usersCollection).doc(userId).snapshots(),
      builder: (context, snapshot) {
        int points = 0;
        if (snapshot.hasData && snapshot.data!.exists) {
          points = snapshot.data!["points"] ?? 0;
        }
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => RewardsScreen(userId: userId)),
            );
          },
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 24),
                const SizedBox(width: 8),
                Text(
                  "Your Points: $points (Tap to Redeem)",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubmissionForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "Schedule a Pickup",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _wasteTypeController,
            decoration: _inputDecoration(labelText: "Waste Type"),
            validator: (value) => value!.isEmpty ? "Please enter waste type" : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _quantityController,
            decoration: _inputDecoration(labelText: "Quantity (kg)"),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) return "Please enter quantity";
              if (int.tryParse(value) == null || int.parse(value) <= 0) return "Enter a valid number > 0";
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _addressController,
            decoration: InputDecoration(
              labelText: "Pickup Address",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey.shade100,
              suffixIcon: IconButton(
                icon: const Icon(Icons.my_location, color: Colors.green),
                onPressed: _fillCurrentLocation,
              ),
            ),
            validator: (value) => value!.isEmpty ? "Please enter address" : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _contactController,
            decoration: _inputDecoration(labelText: "Contact Number"),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) return "Please enter contact number";
              if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) return "Enter a valid 10-digit number";
              return null;
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _submitForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text("Submit Pickup", style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }

  Widget _buildPickupList(String userId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          "Your Pickups",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection(wastePickupsCollection)
              .where("userId", isEqualTo: userId)
              .orderBy("timestamp", descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("No pickups yet."));
            }

            final docs = snapshot.data!.docs;

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>? ?? {};
                final pickupId = docs[index].id;

                String dateText = "Pending...";
                if (data['timestamp'] != null && data['timestamp'] is Timestamp) {
                  dateText = DateFormat('dd MMM yyyy')
                      .format((data['timestamp'] as Timestamp).toDate());
                }

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: const Icon(Icons.recycling, color: Colors.green),
                    title: Text(
                      "${data['wasteType'] ?? 'N/A'} - ${data['totalQuantity'] ?? 0} kg",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "Status: ${data['status'] ?? 'N/A'}\n"
                      "Address: ${data['address'] ?? 'N/A'}\n"
                      "Date: $dateText",
                    ),
                    trailing: data['status'] == 'Pending'
                        ? IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.red),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text("Cancel Pickup"),
                                  content: const Text("Are you sure you want to cancel this pickup?"),
                                  actions: [
                                    TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text("No")),
                                    TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: const Text("Yes")),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                _cancelPickup(pickupId, data["totalQuantity"] ?? 0);
                              }
                            },
                          )
                        : null,
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({required String labelText}) {
    return InputDecoration(
      labelText: labelText,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.grey.shade100,
    );
  }
}
