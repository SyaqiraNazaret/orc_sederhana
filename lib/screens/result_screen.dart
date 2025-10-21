import 'package:flutter/material.dart';
// SOAL 3.1: Import plugin TTS
import 'package:flutter_tts/flutter_tts.dart';
import 'home_screen.dart';

// SOAL 3.2: Ubah dari StatelessWidget menjadi StatefulWidget
class ResultScreen extends StatefulWidget {
  final String ocrText;
  const ResultScreen({super.key, required this.ocrText});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  // SOAL 3.2: Deklarasi FlutterTts
  late FlutterTts flutterTts;
  String languageCode = "id-ID"; // Kode Bahasa Indonesia

  @override
  void initState() {
    super.initState();
    flutterTts = FlutterTts();
    _initializeTts();
  }

  // SOAL 3.2: Fungsi Inisialisasi TTS (mengatur bahasa)
  Future<void> _initializeTts() async {
    // Mengatur Bahasa Indonesia
    await flutterTts.setLanguage(languageCode);
    // Mengatur nada bicara (pitch) dan kecepatan bicara (rate)
    await flutterTts.setPitch(1.0);
    await flutterTts.setSpeechRate(0.5);
  }

  @override
  void dispose() {
    // SOAL 3.2: Menghentikan mesin TTS saat halaman ditutup
    flutterTts.stop();
    super.dispose();
  }

  // SOAL 3.3: Fungsi untuk membacakan teks
  Future<void> _speakText() async {
    // Membacakan seluruh isi ocrText
    if (widget.ocrText.isNotEmpty) {
      await flutterTts.speak(widget.ocrText);
    }
  }

  // Navigasi Balik (Bagian dari SOAL 1.2)
  void _navigateHome() {
    flutterTts.stop(); // Hentikan TTS saat navigasi
    // SOAL 1.2: Navigasi ke HomeScreen dan HAPUS SEMUA halaman di atasnya
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
          (Route<dynamic> route) => false, // Parameter ini yang menghapus semua route
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
            widget.ocrText.isEmpty
                ? 'Tidak ada teks ditemukan.'
            // SOAL 1.2: Menampilkan teks utuh (pastikan .replaceAll('\n', ' ') sudah dihapus)
                : widget.ocrText,
            style: const TextStyle(fontSize: 18),
          ),
        ),
      ),

      // Menggunakan Column untuk menempatkan dua FAB
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // FloatingActionButton 1: Membaca Teks (SOAL 3.3)
          FloatingActionButton(
            heroTag: 'speakBtn',
            onPressed: _speakText,
            tooltip: 'Baca Teks',
            child: const Icon(Icons.volume_up),
          ),
          const SizedBox(height: 10),
          // FloatingActionButton 2: Navigasi Balik ke Home (SOAL 1.2)
          FloatingActionButton(
            heroTag: 'homeBtn',
            onPressed: _navigateHome,
            tooltip: 'Kembali ke Menu Utama',
            child: const Icon(Icons.home),
          ),
        ],
      ),
    );
  }
}