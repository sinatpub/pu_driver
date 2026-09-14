/// UX-redesign F2/F3 — the shared design-system components.
///
/// One import for a screen that needs several:
/// `import 'package:tara_driver_application/presentation/widgets/ds/ds.dart';`
///
/// Specs: `docs/ux-redesign/04-component-specification.md § A` (behaviour and
/// inputs) and `docs/ux-redesign/02-design-system.md §7–§13` (visuals).
///
/// These are presentational only: they take values and callbacks and never
/// reach for a controller. The three *connected* components in `04 § B`
/// (OnlineStatusPill, ApprovalGate, OfflineBanner) arrive with the shell (C1).
///
/// The `show…Dialog` functions in `presentation/widgets/` keep their own
/// signatures and their own navigation semantics; they render [TDialog]
/// internally. That split is deliberate — see `t_dialog.dart`.
library;

export 'ds_icons.dart';
export 't_app_bar.dart';
export 't_button.dart';
export 't_content.dart';
export 't_motion.dart';
export 't_dialog.dart';
export 't_overlays.dart';
export 't_selection.dart';
export 't_states.dart';
export 't_surfaces.dart';
export 't_text_field.dart';
