import 'package:tara_driver_application/core/network/result.dart';
import 'package:tara_driver_application/data/models/complete_driver_model.dart';
import 'package:tara_driver_application/data/models/confirm_booking_model.dart';
import 'package:tara_driver_application/features/trip/data/datasource/trip_datasource.dart';

class TripRepository {
  TripRepository(this._datasource);

  final TripDatasource _datasource;

  Future<Result<ConfirmBookingModel>> confirm(int rideId) =>
      _datasource.confirm(rideId);

  Future<Result<bool>> cancel(int rideId) => _datasource.cancel(rideId);

  Future<Result<ConfirmBookingModel>> arrive(int rideId) =>
      _datasource.arrive(rideId);

  Future<Result<ConfirmBookingModel>> start(int rideId) =>
      _datasource.start(rideId);

  Future<Result<CompleteDriverModel>> complete({
    required int rideId,
    required double endLatitude,
    required double endLongitude,
    required String endAddress,
    required double distance,
  }) =>
      _datasource.complete(
        rideId: rideId,
        endLatitude: endLatitude,
        endLongitude: endLongitude,
        endAddress: endAddress,
        distance: distance,
      );
}
