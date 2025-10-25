import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'auth/login_screen.dart';
import 'constants.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;

  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _profileImage;
  final picker = ImagePicker();
  bool _isEditing = false;
  bool _isUploading = false;

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  // Replace with your ImgBB API Key
  final String imgbbApiKey = "f82cc9c7c27283a0d3e3a78fb9cf2757";

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  Future<void> _pickProfileImage() async {
    try {
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
        await _uploadImageToImgBB();
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Image pick failed: $e')));
    }
  }

  Future<void> _uploadImageToImgBB() async {
    if (_profileImage == null) return;

    setState(() => _isUploading = true);

    try {
      final uri = Uri.parse("https://api.imgbb.com/1/upload?key=$imgbbApiKey");
      final bytes = await _profileImage!.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http.post(uri, body: {"image": base64Image});

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final imageUrl = data['data']['url'];

        await FirebaseFirestore.instance
            .collection(usersCollection)
            .doc(widget.userId)
            .update({'profileImage': imageUrl});

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile image updated successfully!')),
        );
      } else {
        throw Exception('ImgBB upload failed: ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Image upload failed: $e')));
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _updateProfile() async {
    try {
      await FirebaseFirestore.instance
          .collection(usersCollection)
          .doc(widget.userId)
          .update({
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );

      setState(() => _isEditing = false);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Update failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection(usersCollection)
          .doc(widget.userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));

        final userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        _phoneController.text = userData['phone'] ?? '';
        _addressController.text = userData['address'] ?? '';
        final username = userData['username'] ?? 'User';
        final email = userData['email'] ?? 'Not provided';
        final profileImage = userData['profileImage'];

        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile', style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.green,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                icon: Icon(_isEditing ? Icons.check : Icons.edit),
                onPressed: () {
                  if (_isEditing) {
                    _updateProfile();
                  } else {
                    setState(() => _isEditing = true);
                  }
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Profile Image
                GestureDetector(
                  onTap: _pickProfileImage,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: _profileImage != null
                            ? FileImage(_profileImage!) as ImageProvider
                            : AssetImage('assets/images/default_profile.png'),
                      ),
                      if (_isUploading)
                        const Positioned.fill(
                          child: Center(
                            child: CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.green),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(username,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(email, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 20),

                // Stats Card (Earnings & Pickups) using real-time wastePickups
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection(wastePickupsCollection)
                      .where('userId', isEqualTo: widget.userId)
                      .snapshots(),
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return const CircularProgressIndicator();
                    }

                    final pickupsList = snap.data!.docs;
                    final pickupsCount = pickupsList.length;
                    final earnings = pickupsList.fold<double>(0, (sum, doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return data['status'] == 'completed'
                          ? sum + (data['amount'] as num? ?? 0)
                          : sum;
                    });

                    return Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStat(Icons.attach_money, "Earnings",
                                "₹${earnings.toStringAsFixed(2)}"),
                            _buildStat(
                                Icons.local_shipping, "Pickups", "$pickupsCount"),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                // Personal Info
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Personal Information",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const Divider(),
                        _isEditing
                            ? Column(
                                children: [
                                  TextField(
                                    controller: _phoneController,
                                    keyboardType: TextInputType.phone,
                                    decoration: const InputDecoration(
                                        labelText: "Phone Number"),
                                  ),
                                  const SizedBox(height: 10),
                                  TextField(
                                    controller: _addressController,
                                    decoration: const InputDecoration(
                                        labelText: "Address"),
                                  ),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildInfoRow(Icons.phone, "Phone",
                                      _phoneController.text),
                                  const SizedBox(height: 12),
                                  _buildInfoRow(Icons.location_on, "Address",
                                      _addressController.text),
                                ],
                              ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Logout Button
                ElevatedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: const Text("Logout"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStat(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.green, size: 30),
        const SizedBox(height: 5),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.green),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey)),
            Text(value.isNotEmpty ? value : "Not provided",
                style: const TextStyle(fontSize: 16)),
          ],
        ),
      ],
    );
  }
}
