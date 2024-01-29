import 'dart:io';

import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ocr_app/controllers/extract_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => CameraScreenState();
}

class CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  bool _isPermissionGranted = false;

  late Future<void> _future;

  CameraController? _cameraController;

  final _textRecognizer = TextRecognizer();

  AssetsAudioPlayer audioPlayer = AssetsAudioPlayer();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _future = _requestCameraPermission();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state){
    if (_cameraController == null || _cameraController!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _stopCamera();
    } else if (state == AppLifecycleState.resumed && _cameraController != null && _cameraController!.value.isInitialized){
      _startCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(future: _future, builder: (context, snapshot){
      return Stack(
        children: [
          //show the camera ffed behind everything
          if (_isPermissionGranted)
            FutureBuilder<List<CameraDescription>>(future: availableCameras(), builder: (context, snapshot) {
              if (snapshot.hasData) {
                _initializeCameraController(snapshot.data!);

                return Center(child: CameraPreview(_cameraController!));
              } else {
                return const LinearProgressIndicator();
              }
            },),
            Scaffold(
              backgroundColor: _isPermissionGranted ? Colors.transparent : null,
              body: _isPermissionGranted ?
              Column(
                children: [
                  Expanded(
                    child: Container(),
                  ),
                  Container(
                    padding: const EdgeInsets.only(bottom: 30.0),
                    child: Center(
                      child: Builder(
                        builder: (context) {
                          return IconButton(
                            onPressed: _scanImage, 
                            icon: const Icon(Icons.camera, size: 70.0,),
                            focusColor: Colors.blue,
                            tooltip: 'Extract text',
                          );
                        }
                      ),
                    ),
                  )
                ],
              ) : Center(
                child: Container(
                padding: const EdgeInsets.only(
                  left: 24.0,
                  right: 24.0
                ),
                child: const Text('Camera permission denied', textAlign: TextAlign.center, ),
                ),
              )
            )
          
        ],
      );
    });
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    _isPermissionGranted = status == PermissionStatus.granted;
  }

  void _startCamera() {
    if (_cameraController != null) {
      _cameraSelected(_cameraController!.description);
    }
  }

  void _stopCamera() {
    if (_cameraController != null) {
      _cameraController?.dispose();
    }
  }

  void _initializeCameraController(List<CameraDescription> cameras){
    if (_cameraController != null) {
      return;
    }

    //Select the first rear camera
    CameraDescription? camera;
    for (var i = 0; i < cameras.length; i++) {
      final CameraDescription current =cameras[i];
      if (current.lensDirection == CameraLensDirection.back) {
        camera = current;
        break;
      }
    }
    if (camera != null) {
      _cameraSelected(camera);
    }
  }
  
  Future<void> _cameraSelected(CameraDescription camera) async {
    _cameraController = CameraController(camera, ResolutionPreset.max, enableAudio: true,);

    await _cameraController?.initialize();

    if (!mounted) {
      return;
    }
    setState(() {}); 
  }

  Future<void> _scanImage() async {
    if (_cameraController == null) {
      return;
    }

    final navigator = Navigator.of(context);

    try {
      //play a sound effect
      audioPlayer.open(Audio('assets/media/camera-shutter.wav'));
      audioPlayer.play();

      // for showing text extract
      final pictureFile = await _cameraController!.takePicture();
      final file = File(pictureFile.path);
      final inputImage = InputImage.fromFile(file);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      await _textRecognizer.close();
      await navigator.push(
        MaterialPageRoute(
          builder: (context) => ExtractionScreen(text: recognizedText.text),
        ),
      );
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occured when scanning text'),
        ),
      );
    }
  }
}
