import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class WasteSortingScreen extends StatefulWidget {
  const WasteSortingScreen({super.key});

  @override
  State<WasteSortingScreen> createState() => _WasteSortingScreenState();
}

class _WasteSortingScreenState extends State<WasteSortingScreen> {
  Uint8List? _imageBytes;
  String? _outputLabel;
  bool _loading = false;

  Interpreter? _interpreter;
  List<String> _labels = [];

  @override
  void initState() {
    super.initState();
    _loadModelAndLabels();
  }

  Future<void> _loadModelAndLabels() async {
    try {
      _interpreter = await Interpreter.fromAsset('model/waste_model.tflite');
      final labelData = await rootBundle.loadString('assets/model/labels.txt');
      _labels = labelData.split('\n');
      debugPrint('✅ Model and labels loaded!');
    } catch (e) {
      debugPrint('❌ Error loading model: $e');
    }
  }

  Future<void> _pickImage(bool fromCamera) async {
    final picked = await ImagePicker().pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    setState(() {
      _imageBytes = bytes;
      _loading = true;
      _outputLabel = null;
    });
    await _classifyImage(bytes);
  }

  Future<void> _classifyImage(Uint8List imageBytes) async {
    if (_interpreter == null) {
      debugPrint("❌ Interpreter not initialized.");
      setState(() => _loading = false);
      return;
    }

    try {
      final rawImage = img.decodeImage(imageBytes)!;
      final resized = img.copyResize(rawImage, width: 224, height: 224);

      final input = List.generate(
        1,
        (_) => List.generate(
          224,
          (y) => List.generate(
            224,
            (x) => List.generate(
              3,
              (c) => ((resized.getPixel(x, y) >> (16 - 8 * c)) & 0xFF) / 255.0,
            ),
          ),
        ),
      );

      var output = List.filled(_labels.length, 0.0).reshape([1, _labels.length]);
      _interpreter!.run(input, output);

      int topIndex = output[0].indexOf(output[0].reduce((a, b) => a > b ? a : b));

      setState(() {
        _loading = false;
        _outputLabel = _labels[topIndex];
      });
      debugPrint("✅ Classified as: $_outputLabel");
    } catch (e) {
      debugPrint('❌ Error classifying image: $e');
      setState(() => _loading = false);
    }
  }

  String getEcoTip(String wasteType) {
    final tips = {
      "Plastic": "Plastic can be recycled. Rinse bottles and remove caps before disposal.",
      "Paper": "Paper is recyclable. Keep it clean and dry.",
      "Metal": "Metal cans are 100% recyclable. Clean them before disposal.",
      "Glass": "Glass bottles/jars can be recycled. Sort by color if possible.",
      "Organic": "Organic waste can be composted to create natural fertilizer.",
      "E-waste": "E-waste should be taken to certified e-waste recycling centers.",
      "Battery": "Batteries are hazardous. Dispose at special battery collection points.",
      "Cloth": "Clothes can be donated or recycled into rags.",
      "Wood": "Wood can be reused or chipped for compost/mulch.",
      "Food Waste": "Food waste can be composted or used in biogas plants.",
    };
    return tips[wasteType] ?? "Recycle or dispose responsibly!";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Waste Sorting",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_imageBytes != null)
                Image.memory(_imageBytes!, height: 250)
              else
                const Icon(Icons.image, size: 150, color: Colors.green),
              const SizedBox(height: 20),
              if (_loading)
                const CircularProgressIndicator()
              else if (_outputLabel != null)
                Column(
                  children: [
                    Text(
                      "Detected: $_outputLabel",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Card(
                      color: Colors.green.shade50,
                      margin: const EdgeInsets.all(16),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          getEcoTip(_outputLabel!),
                          style: const TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                )
              else
                const Text(
                  "Upload or capture an image to start classification.",
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(false),
                    icon: const Icon(Icons.photo, color: Colors.white),
                    label: const Text("Gallery", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(true),
                    icon: const Icon(Icons.camera_alt, color: Colors.white),
                    label: const Text("Camera", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
