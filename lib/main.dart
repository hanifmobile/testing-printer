import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PrintScreen(),
    );
  }
}

class PrintScreen extends StatefulWidget {
  @override
  _PrintScreenState createState() => _PrintScreenState();
}

class _PrintScreenState extends State<PrintScreen> {
  final String pdfUrl =
      "https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf"; // Ganti dengan link PDF
  final String printerIp = "192.168.1.22"; // Ganti dengan IP printer
  final int printerPort = 9100; // Port umum untuk printer WiFi

  String printerStatus = "Belum dicek"; // Status koneksi printer

  /// Cek apakah printer bisa dihubungi melalui socket
  Future<void> checkPrinterConnection() async {
    setState(() {
      printerStatus = "Mengecek...";
    });

    try {
      final socket = await Socket.connect(printerIp, printerPort,
          timeout: Duration(seconds: 5));
      socket.destroy();
      setState(() {
        printerStatus = "Printer Terhubung ✅";
      });
    } catch (e) {
      setState(() {
        printerStatus = "Printer Tidak Dapat Dihubungi ❌";
      });
    }
  }

  /// Mengunduh file PDF dari URL dan menyimpannya ke penyimpanan sementara
  Future<File?> downloadPDF() async {
    try {
      final response = await http.get(Uri.parse(pdfUrl));
      if (response.statusCode == 200) {
        final directory = await getTemporaryDirectory();
        final filePath = "${directory.path}/downloaded.pdf";
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        print("PDF berhasil diunduh: $filePath");
        return file;
      }
    } catch (e) {
      print("Gagal mengunduh PDF: $e");
    }
    return null;
  }

  /// Mengirim file PDF ke printer hanya jika printer terhubung
  Future<void> sendPDFToPrinter() async {
    if (printerStatus != "Printer Terhubung ✅") {
      print("Printer tidak tersedia. Pastikan printer terhubung ke jaringan.");
      setState(() {
        printerStatus = "Printer Tidak Siap ❌";
      });
      return;
    }

    File? pdfFile = await downloadPDF();
    if (pdfFile != null) {
      try {
        Socket socket = await Socket.connect(printerIp, printerPort);
        print("Terhubung ke printer: $printerIp");

        List<int> pdfBytes = await pdfFile.readAsBytes();
        socket.add(pdfBytes);
        await socket.flush();
        socket.destroy();

        print("PDF berhasil dikirim ke printer");
        setState(() {
          printerStatus = "Dokumen Sedang Dicetak 🖨️";
        });
      } catch (e) {
        print("Gagal mencetak PDF: $e");
        setState(() {
          printerStatus = "Gagal mencetak ❌";
        });
      }
    } else {
      print("PDF tidak ditemukan");
      setState(() {
        printerStatus = "Gagal mengunduh PDF ❌";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Print PDF ke WiFi Printer")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Status Printer: $printerStatus",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: checkPrinterConnection,
              child: Text("Cek Printer 🔍"),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: sendPDFToPrinter,
              child: Text("Cetak PDF 🖨️"),
            ),
          ],
        ),
      ),
    );
  }
}
