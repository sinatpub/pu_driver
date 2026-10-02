import 'package:tara_driver_application/mock/mock_mode.dart';

/// Whether the invite QR, the rewards screens and the sign-up invite code are
/// shown (DD-45).
///
/// The backend has no referral endpoints yet, so the feature is served by the
/// mock backend only. Against the real API the entry points stay hidden —
/// a driver never reaches a screen that can only fail. Replace this with
/// `true` (or a server flag) when the endpoints in `ReferralDatasource` exist.
bool get inviteFeatureEnabled => MockMode.isActive;
