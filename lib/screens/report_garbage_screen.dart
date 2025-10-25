import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'constants.dart';

class ReportGarbageScreen extends StatefulWidget {
  const ReportGarbageScreen({super.key});

  @override
  State<ReportGarbageScreen> createState() => _ReportGarbageScreenState();
}

class _ReportGarbageScreenState extends State<ReportGarbageScreen> {
  XFile? _pickedImage;
  final picker = ImagePicker();
  bool _loading = false;
  String? _location;
  final TextEditingController _descController = TextEditingController();

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(
      source: kIsWeb ? ImageSource.gallery : ImageSource.camera,
      imageQuality: 85,
    );
    if (mounted && pickedFile != null) {
      setState(() {
        _pickedImage = pickedFile;
      });
    }
  }

  Future<void> _getLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnack("Location services are disabled.");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnack("Location permissions denied.");
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showSnack("Location permissions are permanently denied.");
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      if (mounted) {
        setState(() {
          _location = "${position.latitude}, ${position.longitude}";
        });
      }
    } catch (e) {
      _showSnack("Location error: $e");
    }
  }

  Future<void> _uploadReport() async {
    if (_pickedImage == null || _location == null) {
      _showSnack("Please add a photo & location");
      return;
    }

    setState(() => _loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      String imageUrl = await _uploadImageWithFallback(_pickedImage!);

      await FirebaseFirestore.instance.collection(wasteReportsCollection).add({
        "userId": user.uid,
        "image_url": imageUrl,
        "location": _location,
        "description": _descController.text.trim(),
        "status": "pending",
        "timestamp": FieldValue.serverTimestamp(),
      });

      _showSnack("Report uploaded successfully!");
      setState(() {
        _pickedImage = null;
        _location = null;
        _descController.clear();
      });
    } catch (e) {
      _showSnack("Upload error: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  /// 🧠 Handles Firebase upload + fallback to ImgBB if Firebase fails
  Future<String> _uploadImageWithFallback(XFile pickedFile) async {
    final fileName =
        "garbage_reports/${DateTime.now().millisecondsSinceEpoch}.jpg";
    final storageRef = FirebaseStorage.instance.ref().child(fileName);

    try {
      UploadTask uploadTask;

      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        uploadTask = storageRef.putData(bytes);
      } else {
        uploadTask = storageRef.putFile(File(pickedFile.path));
      }

      final snapshot = await uploadTask;
      final url = await snapshot.ref.getDownloadURL();
      return url;
    } catch (e) {
      // 👇 Fallback to ImgBB if Firebase Storage fails
      debugPrint("Firebase Storage failed: $e — switching to ImgBB upload");
      return await _uploadToImgBB(pickedFile);
    }
  }

  /// 🆓 Uploads image to ImgBB (free fallback)
  Future<String> _uploadToImgBB(XFile image) async {
    const imgbbApiKey = "f82cc9c7c27283a0d3e3a78fb9cf2757"; // replace with your key
    final request = http.MultipartRequest(
      'POST',
      Uri.parse("https://api.imgbb.com/1/upload?key=$imgbbApiKey"),
    );
    request.files.add(await http.MultipartFile.fromPath('image', image.path));

    final response = await request.send();
    if (response.statusCode == 200) {
      final body = json.decode(await response.stream.bytesToString());
      return body['data']['url'];
    } else {
      throw Exception("ImgBB upload failed (${response.statusCode})");
    }
  }

  void _showSnack(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text("Report Garbage", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildImageDisplay(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.camera_alt),
                      label: Text(kIsWeb ? "Pick Image" : "Take Photo"),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _getLocation,
                      icon: const Icon(Icons.location_on),
                      label: const Text("Get Location"),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white),
                    ),
                  ),
                ],
              ),
              if (_location != null) ...[
                const SizedBox(height: 16),
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        const Icon(Icons.my_location, color: Colors.green),
                        const SizedBox(width: 12),
                        Expanded(child: Text("Location: $_location")),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              TextField(
                controller: _descController,
                decoration: InputDecoration(
                  labelText: "Description (optional)",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  prefixIcon:
                      const Icon(Icons.description, color: Colors.green),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loading ? null : _uploadReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Upload Report",
                        style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageDisplay() {
    if (_pickedImage == null) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_not_supported, size: 60, color: Colors.grey),
              SizedBox(height: 8),
              Text("No image selected", style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    } else {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: kIsWeb
            ? Image.network(_pickedImage!.path,
                height: 200, width: double.infinity, fit: BoxFit.cover)
            : Image.file(File(_pickedImage!.path),
                height: 200, width: double.infinity, fit: BoxFit.cover),
      );
    }
  }
}
