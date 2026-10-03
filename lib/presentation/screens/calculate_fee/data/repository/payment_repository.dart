import 'package:pu_taxi_driver/core/network/result.dart';
import 'package:pu_taxi_driver/presentation/screens/calculate_fee/data/datasource/payment_datasource.dart';

class PaymentRepository {
  PaymentRepository(this._datasource);

  final PaymentDatasource _datasource;

  Future<Result<bool>> acceptPayment(int rideId) =>
      _datasource.acceptPayment(rideId);
}
