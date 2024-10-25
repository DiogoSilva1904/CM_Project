import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'dart:convert';
import 'comparisonpage.dart';

class QRScannerPage extends StatefulWidget {
  @override
  _QRScannerPageState createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  Barcode? result;
  QRViewController? controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Scan QR Code")),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 5,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Text(result != null ? 'Scanned QR code!' : 'Scan a QR code'),
            ),
          ),
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) async {
      controller.pauseCamera(); // Pause camera to avoid re-scanning
      try {
        // Decode QR data
        final scannedData = jsonDecode(scanData.code!);
        final int scannedSteps = scannedData['steps'];
        final double scannedCalories = scannedData['calories'];
        final double scannedDistance = scannedData['distance'];

        // Navigate to ComparisonPage
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ComparisonPage(
              scannedSteps: scannedSteps,
              scannedCalories: scannedCalories,
              scannedDistance: scannedDistance,
            ),
          ),
        ).then((_) => controller.resumeCamera());
      } catch (e) {
        // Handle potential errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Invalid QR code")),
        );
        controller.resumeCamera();
      }
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
