import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class CameraScreen extends StatefulWidget {
  final CameraDescription camera;

  const CameraScreen({super.key, required this.camera});

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  final model = GenerativeModel(
    model: 'gemini-1.5-pro',
    apiKey: "AIzaSyDHRCG6Ig1LIn28lfRljDrdNZIHvF5a908",
  );

  String res = "";

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.high,
    );
    _initializeControllerFuture = _controller.initialize();

    // loadit();
    gobro();
  }

  gobro() {
    Timer.periodic(const Duration(seconds: 15), (timer) {
      print(timer.tick);

      loadit();
    });
  }

  loadit() async {
    // const prompt = 'describe this picture';
    final prompt = TextPart("Describe this picture");

    // final content = [Content.text(prompt)];
    // final response = await model.generateContent(content);
    // try {
    await _initializeControllerFuture;
    final image = await _controller.takePicture();

    final imageParts = [
      DataPart('image/jpeg', await image.readAsBytes()),
    ];
    final response = await model.generateContent([
      Content.multi([prompt, ...imageParts])
    ]);
    print("----------> response");
    print(response.text);
    setState(() {
      res = response.text ?? "";
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Take a picture')),
      body: Stack(
        children: [
          FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return CameraPreview(_controller);
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          ),
          res.isEmpty
              ? const SizedBox()
              : Container(
                  width: 300,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    res,
                    style: const TextStyle(color: Colors.black),
                  ),
                )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.camera_alt),
        onPressed: () async {
          // try {
          //   await _initializeControllerFuture;
          //   final image = await _controller.takePicture();
          //   // Handle the captured image
          // } catch (e) {
          //   print(e);
          // }
          loadit();
        },
      ),
    );
  }
}
