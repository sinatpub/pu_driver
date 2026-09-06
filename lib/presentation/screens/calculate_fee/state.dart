import 'package:get/get.dart' hide Trans;

enum PaymentStatus { initial, loading, success, error }

class CalculateFeeState {
  final Rx<PaymentStatus> status = Rx<PaymentStatus>(PaymentStatus.initial);
}
