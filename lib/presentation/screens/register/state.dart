import 'dart:io';

import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/data/models/register_model.dart';
import 'package:tara_driver_application/presentation/screens/invite/widgets/invite_code_field.dart';

enum RegisterStatus { initial, loading, loaded, fail }

/// Every field below was a `setState` field on `_RegisterPageState`. The
/// screen already wrapped its body in `Obx`, so making them `Rx` is what that
/// `Obx` was always meant to watch.
class RegisterState {
  final Rx<RegisterStatus> status = Rx<RegisterStatus>(RegisterStatus.initial);
  final Rxn<RegisterModel> registerModel = Rxn<RegisterModel>();

  final Rxn<File> imageProfile = Rxn<File>();
  final Rxn<File> imageCardID = Rxn<File>();
  final Rxn<File> imageLicense = Rxn<File>();
  final Rxn<File> imageVehicle = Rxn<File>();

  final RxnInt vehicalId = RxnInt();

  /// Bumped whenever a text field changes, so the `Obx` re-runs the
  /// "is the form fillable" checks that used to ride on `setState(() {})`.
  final RxInt formRevision = 0.obs;

  /// DD-45: where the optional invite code stands, and who it belongs to.
  final Rx<InviteCodeStatus> inviteStatus =
      Rx<InviteCodeStatus>(InviteCodeStatus.idle);
  final RxnString inviterName = RxnString();
}
