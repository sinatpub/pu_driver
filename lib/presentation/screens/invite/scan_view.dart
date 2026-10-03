import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pu_taxi_driver/core/theme/tokens.dart';
import 'package:pu_taxi_driver/presentation/screens/invite/invite_presentation.dart';
import 'package:pu_taxi_driver/presentation/widgets/ds/ds.dart';

/// Scans an invite QR at sign-up (DD-45) and pops with the invite code it
/// held, as a `String`. Popping without one means the person backed out.
///
/// Only an invite counts: a QR that holds anything else is refused with a
/// line of text, and the camera keeps looking.
class InviteScanPage extends StatefulWidget {
  const InviteScanPage({super.key});

  @override
  State<InviteScanPage> createState() => _InviteScanPageState();
}

class _InviteScanPageState extends State<InviteScanPage> {
  final MobileScannerController _controller = MobileScannerController(
    formats: const <BarcodeFormat>[BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  bool _done = false;
  bool _notAnInvite = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_done) return;
    for (final Barcode barcode in capture.barcodes) {
      final String? code = parseInviteCode(barcode.rawValue);
      if (code != null) {
        _done = true;
        Navigator.of(context).pop(code);
        return;
      }
    }
    if (!_notAnInvite && mounted) setState(() => _notAnInvite = true);
  }

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;

    return Scaffold(
      backgroundColor: c.bgPage,
      appBar: TAppBar(title: 'INVITE_SCAN'.tr()),
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (BuildContext context, MobileScannerException error) {
              final bool denied =
                  error.errorCode == MobileScannerErrorCode.permissionDenied;
              return ColoredBox(
                color: c.bgPage,
                child: Center(
                  child: SingleChildScrollView(
                    child: TErrorState(
                      title: denied
                          ? 'INVITE_CAMERA_DENIED'.tr()
                          : 'PLEASE_TRY_AGAIN_SOMETHING_WENT_WRONG'.tr(),
                      message: denied ? 'INVITE_CAMERA_DENIED_HINT'.tr() : null,
                      actionLabel: denied ? 'OPEN_SETTINGS'.tr() : null,
                      onAction: denied ? () => openAppSettings() : null,
                    ),
                  ),
                ),
              );
            },
            overlayBuilder:
                (BuildContext context, BoxConstraints constraints) =>
                    ScanOverlay(
              hint: _notAnInvite
                  ? 'INVITE_SCAN_NOT_INVITE'.tr()
                  : 'INVITE_SCAN_HINT'.tr(),
              isWarning: _notAnInvite,
            ),
          ),
        ],
      ),
    );
  }
}

/// The frame the QR goes in, and one line saying what to do.
class ScanOverlay extends StatelessWidget {
  const ScanOverlay({super.key, required this.hint, this.isWarning = false});

  final String hint;

  /// The last QR seen was not an invite.
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double side =
            (constraints.biggest.shortestSide * 0.68).clamp(160.0, 300.0);
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: side,
              height: side,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Radii.xl),
                border: Border.all(color: Colors.white, width: 3),
              ),
            ),
            const SizedBox(height: Insets.s20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Insets.s24),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: c.toastBackground,
                  borderRadius: Radii.controlRadius,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (isWarning) ...<Widget>[
                      TIcon(
                        DsIcons.warn,
                        size: TIconSize.sm,
                        color: c.toastText,
                      ),
                      const SizedBox(width: Insets.s8),
                    ],
                    Flexible(
                      child: Text(
                        hint,
                        textAlign: TextAlign.center,
                        style: context.texts.bodySecondary.copyWith(
                          color: c.toastText,
                          fontWeight: FontWeights.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
