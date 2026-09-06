import 'package:tara_driver_application/core/network/result.dart';
import 'package:tara_driver_application/features/payment/data/datasource/payment_datasource.dart';

class PaymentRepository {
  PaymentRepository(this._datasource);

  final PaymentDatasource _datasource;

  Future<Result<bool>> acceptPayment(int rideId) =>
      _datasource.acceptPayment(rideId);
}
