// File: lib/screens/scan_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'result_screen.dart';

// Variabel global harus diinisialisasi oleh main.dart
late List<CameraDescription> cameras;

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  // Variabel late
  late CameraController _controller;
  // Future ini yang akan diamati oleh FutureBuilder
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  void _initCamera() async {
    try {
      // Menunggu daftar kamera tersedia
      cameras = await availableCameras();

      // Inisialisasi controller
      _controller = CameraController(
        cameras[0],
        ResolutionPreset.medium,
      );

      // Dapatkan Future dari inisialisasi kamera yang sebenarnya
      Future<void> cameraInitialization = _controller.initialize();

      // --- MODIFIKASI: GABUNGKAN INISIALISASI DENGAN DELAY BUATAN 3 DETIK ---
      _initializeControllerFuture = Future.wait([
        cameraInitialization, // 1. Tunggu inisialisasi kamera selesai
        Future.delayed(const Duration(seconds: 3)), // 2. Tunggu delay buatan 3 detik
      ]).then((_) => null); // Future selesai hanya setelah keduanya terpenuhi
      // ----------------------------------------------------------------------

      // setState dibutuhkan jika inisialisasi sukses setelah build pertama
      if (mounted) {
        setState(() {});
      }

    } catch (e) {
      if (mounted) {
        // Jika inisialisasi gagal, Future diisi dengan error
        _initializeControllerFuture = Future.error('Gagal inisialisasi kamera: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Gagal mengakses kamera. Periksa izin.')),
        );
      }
    }
  }

  @override
  void dispose() {
    // Dipanggil hanya jika controller berhasil diinisialisasi untuk mencegah error saat exit
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
      // Menunggu kamera siap sebelum mengambil gambar
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

      // SOAL 2.2: Pesan error spesifik tanpa menampilkan detail error $e
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Pemindaian Gagal! Periksa Izin Kamera atau coba lagi.')
          )
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // FutureBuilder yang mencegah LateInitializationError
    return FutureBuilder<void>(
      future: _initializeControllerFuture,
      builder: (context, snapshot) {

        // SOAL 2.1: Custom Loading Screen (muncul saat waiting)
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Colors.grey[900], // Latar Belakang Custom
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  CircularProgressIndicator(color: Colors.yellow), // Indikator Custom
                  SizedBox(height: 20),
                  Text(
                    'Memuat Kamera... Harap tunggu.', // Teks Custom
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
            ),
          );
        }

        // Menangani error inisialisasi kamera (error izin, dll.)
        else if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error Kamera')),
            body: Center(
              child: Text(
                'Gagal memuat kamera. Cek log konsol untuk detail atau pastikan izin kamera aktif.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
            ),
          );
        }

        // Tampilkan CameraPreview setelah Future selesai (ready)
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