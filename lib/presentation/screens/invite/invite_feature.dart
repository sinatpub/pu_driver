/// Whether the invite QR, the rewards screens and the sign-up invite code are
/// shown (DD-45).
///
/// The backend now answers every endpoint in `ReferralDatasource`
/// (`/taxi-driver/referral`, `/referral/check-code`, `/referral/transfer`),
/// so the feature is on for every build. Kept as one switch so it can be
/// turned off (or tied to a server flag) in one place.
///
/// QA mock mode and a `DEMO_INVITE=true` build (DD-55) still answer these
/// calls from made-up data instead of the backend.
bool get inviteFeatureEnabled => true;
