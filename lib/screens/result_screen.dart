// File: lib/screens/result_screen.dart (Status Sementara Soal 1)

import 'package:flutter/material.dart';
import 'home_screen.dart';

class ResultScreen extends StatelessWidget {
  final String ocrText;
  const ResultScreen({super.key, required this.ocrText});

  // Fungsi navigasi balik (di luar build karena widget masih StatelessWidget)
  void _navigateHome(BuildContext context) {
    // SOAL 1.2: Navigasi ke HomeScreen dan hapus semua halaman di atasnya
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
          (Route<dynamic> route) => false, // Hapus semua route
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hasil OCR')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: SelectableText(
            ocrText.isEmpty
                ? 'Tidak ada teks ditemukan.'
                : ocrText, // SOAL 1.2: Menghapus .replaceAll('\n', ' ')
            style: const TextStyle(fontSize: 18),
          ),
        ),
      ),
      // SOAL 1.2: FloatingActionButton untuk navigasi balik
      floatingActionButton: FloatingActionButton(
        heroTag: 'homeBtn',
        onPressed: () => _navigateHome(context),
        child: const Icon(Icons.home),
      ),
    );
  }
}