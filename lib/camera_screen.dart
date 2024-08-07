import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tflite/tflite.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path/path.dart' as path;

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  List<CameraDescription>? cameras;
  bool isCameraInitialized = false;
  FlutterTts flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    initializeCamera();
    loadModel();
  }

  void initializeCamera() async {
    cameras = await availableCameras();
    _controller = CameraController(cameras![1], ResolutionPreset.high);
    await _controller?.initialize();
    setState(() {
      isCameraInitialized = true;
    });
  }

  void loadModel() async {
    await Tflite.loadModel(
      model: "assets/yolov3.tflite",
      labels: "assets/yolov3.txt",
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    Tflite.close();
    flutterTts.stop();
    super.dispose();
  }

  void detectObject(File imageFile) async {
    var recognitions = await Tflite.detectObjectOnImage(
      path: imageFile.path,
      model: "YOLO",
      threshold: 0.5,
      imageMean: 0.0,
      imageStd: 255.0,
    );

    if ((recognitions ?? []).isNotEmpty) {
      // Upload the detected object image and interact with the Generative AI service
      String detectedObjectPath = imageFile.path;
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.gemini.com/v1/detect'),
      );
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          detectedObjectPath,
        ),
      );
      var res = await request.send();
      var responseBody = await res.stream.bytesToString();

      // Use the Gemini API to get information about the detected object
      String detectedText = responseBody; // Parse the response as needed

      // Convert the text to speech
      await flutterTts.speak(detectedText);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isCameraInitialized
          ? CameraPreview(_controller!)
          : const Center(child: CircularProgressIndicator()),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          XFile picture = await _controller!.takePicture();
          final directory = await getApplicationDocumentsDirectory();
          final imagePath = path.join(directory.path, picture.name);
          final File imageFile = File(imagePath);
          await picture.saveTo(imagePath);

          detectObject(imageFile);
        },
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}
