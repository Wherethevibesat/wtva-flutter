import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../theme/figma_theme.dart';
import '../../../utils/wtva_feedback.dart';

/// Scans a venue's check-in QR code and returns its token (via [Navigator.pop]).
///
/// The business app encodes `.../check-in?venue=<id>&token=<token>`. When
/// [expectedVenueId] is provided, only a QR for that venue is accepted.
class QrScanScreen extends StatefulWidget {
  final String? expectedVenueId;

  const QrScanScreen({super.key, this.expectedVenueId});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null || raw.isEmpty) continue;

      final uri = Uri.tryParse(raw);
      final token = uri?.queryParameters['token'];
      final venue = uri?.queryParameters['venue'];
      if (token == null || token.isEmpty) continue;

      if (widget.expectedVenueId != null &&
          venue != null &&
          venue != widget.expectedVenueId) {
        showWtvaSnack(context, 'That QR is for a different venue', icon: Icons.error_outline);
        continue;
      }

      _handled = true;
      Navigator.pop(context, token);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Scan venue QR', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: WtvaColors.accentPurple, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const Positioned(
            left: 24,
            right: 24,
            bottom: 48,
            child: Text(
              'Point your camera at the venue\'s check-in QR code',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
