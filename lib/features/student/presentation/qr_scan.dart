import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../data/attendances_repository.dart';

class QrScanScreen extends ConsumerStatefulWidget {
  const QrScanScreen({super.key});

  @override
  ConsumerState<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends ConsumerState<QrScanScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _busy = false;
  String? _message;
  Timer? _cooldown;

  @override
  void dispose() {
    _cooldown?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quét QR điểm danh')),
      body: Column(
        children: [
          Expanded(
            child: MobileScanner(
              controller: _controller,
              onDetect: (capture) async {
                if (_busy) return;
                final barcodes = capture.barcodes;
                if (barcodes.isEmpty) return;
                final raw = barcodes.first.rawValue;
                if (raw == null || raw.isEmpty) return;
                setState(() { _busy = true; _message = null; });
                try {
                  final res = await ref.read(attendancesRepositoryProvider).checkinByQr(qr: raw);
                  if (mounted) setState(() { _message = res['message']?.toString() ?? 'Điểm danh thành công'; });
                } catch (e) {
                  if (mounted) setState(() { _message = 'Điểm danh thất bại'; });
                } finally {
                  _cooldown?.cancel();
                  _cooldown = Timer(const Duration(seconds: 2), () {
                    if (mounted) setState(() { _busy = false; });
                  });
                }
              },
            ),
          ),
          if (_message != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(_message!, style: const TextStyle(fontWeight: FontWeight.w600)),
            )
        ],
      ),
    );
  }
}



