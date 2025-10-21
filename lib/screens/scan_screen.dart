import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'result_screen.dart';

// Variabel global, harus diinisialisasi sebelum digunakan pertama kali
late List<CameraDescription> cameras;

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  // Variabel 'late' yang akan diinisialisasi
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  // >>>>>> PERBAIKAN KRITIS PADA _initCamera() <<<<<<
  void _initCamera() async {
    try {
      // Dapatkan daftar kamera yang tersedia
      cameras = await availableCameras();

      // Pilih kamera pertama
      _controller = CameraController(
        cameras[0],
        ResolutionPreset.medium,
      );

      // Simpan Future inisialisasi controller
      _initializeControllerFuture = _controller.initialize();

    } catch (e) {
      if (mounted) {
        // Jika inisialisasi kamera gagal, tampilkan pesan dan pastikan Future diisi
        // Ini MENCEGAH LateInitializationError di build()
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ERROR KAMERA: $e. Cek izin kamera.')),
        );
        _initializeControllerFuture = Future.error('Gagal inisialisasi kamera');
      }
    }
  }

  @override
  void dispose() {
    // Pastikan controller di-dispose hanya jika sudah diinisialisasi
    if (_controller.value.isInitialized) {
      _controller.dispose();
    }
    super.dispose();
  }

  Future<String> _ocrFromFile(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final RecognizedText recognizedText =
    await textRecognizer.processImage(inputImage);
    textRecognizer.close();
    return recognizedText.text;
  }

  Future<void> _takePicture() async {
    try {
      // Menunggu inisialisasi
      await _initializeControllerFuture;

      if (!mounted || !_controller.value.isInitialized) return;

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Memproses OCR, mohon tunggu...'),
              duration: Duration(seconds: 2)));

      final XFile image = await _controller.takePicture();
      final ocrText = await _ocrFromFile(File(image.path));

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ResultScreen(ocrText: ocrText)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error saat mengambil/memproses foto: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // FutureBuilder menunggu _initializeControllerFuture selesai
    return FutureBuilder<void>(
      future: _initializeControllerFuture,
      builder: (context, snapshot) {
        // 1. Tampilkan loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 2. Tampilkan error jika inisialisasi gagal
        else if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error Kamera')),
            body: Center(
              child: Text(
                'Gagal memuat kamera: ${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
            ),
          );
        }

        // 3. Tampilkan CameraPreview
        else {
          return Scaffold(
            appBar: AppBar(title: const Text('Kamera OCR')),
            body: Column(
              children: [
                Expanded(
                  child: AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: CameraPreview(_controller),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton.icon(
                    onPressed: _takePicture,
                    icon: const Icon(Icons.camera),
                    label: const Text('Ambil Foto & Scan'),
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }
}