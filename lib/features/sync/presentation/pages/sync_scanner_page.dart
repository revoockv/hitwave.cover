import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:watch_it/watch_it.dart';

/// Camera view that reads the sync QR code of the other device and closes with it.
final class SyncScannerPage extends WatchingWidget {
  static const String _title = 'Скануйте QR-код';
  static const String _codePrefix = 'hitwave-sync:';

  /// Creates a new [SyncScannerPage].
  const SyncScannerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final MobileScannerController scannerController = createOnce(
      _createScannerController,
      dispose: _disposeScannerController,
    );
    return Scaffold(
      appBar: AppBar(title: const Text(_title)),
      body: MobileScanner(
        controller: scannerController,
        onDetect: (BarcodeCapture capture) => _onDetect(context, capture),
      ),
    );
  }

  static MobileScannerController _createScannerController() =>
      MobileScannerController(formats: const <BarcodeFormat>[BarcodeFormat.qrCode]);

  static void _disposeScannerController(MobileScannerController scannerController) => scannerController.dispose();

  /// Closes with the first sync code seen; other QR codes are ignored.
  void _onDetect(BuildContext context, BarcodeCapture capture) {
    if (!(ModalRoute.of(context)?.isCurrent ?? false)) return;
    for (final Barcode barcode in capture.barcodes) {
      final String? value = barcode.rawValue;
      if (value != null && value.startsWith(_codePrefix)) {
        Navigator.of(context).pop(value);
        return;
      }
    }
  }
}
