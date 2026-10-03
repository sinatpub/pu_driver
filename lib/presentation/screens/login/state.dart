import 'package:get/get.dart' hide Trans;
import 'package:pu_taxi_driver/presentation/screens/login/data/models/phone_model.dart';

enum LoginStatus { initial, loading, loaded, fail }

class LoginState {
  final Rx<LoginStatus> status = Rx<LoginStatus>(LoginStatus.initial);
  final Rxn<PhoneNumberModel> phoneModel = Rxn<PhoneNumberModel>();
  final RxBool isInvalidPhone = RxBool(false);
  final RxBool isRequired8Digit = RxBool(false);
}
