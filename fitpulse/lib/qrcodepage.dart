import 'package:flutter/material.dart';
import 'qrcode.dart';

class QRPage extends StatefulWidget {
  @override
  _QRPageState createState() => _QRPageState();
}

class _QRPageState extends State<QRPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(  // Center widget to align buttons in the middle
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,  // Center vertically
          children: <Widget>[
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,  // Center horizontally
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Navigate to QRCodePage
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => QRScannerPage()),
                    );
                  },
                  child: Text('Go to QRCodePage'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Placeholder for another action
                    print("Another action triggered");
                  },
                  child: Text('Another Button'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
