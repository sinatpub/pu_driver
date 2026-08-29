import 'package:tara_driver_application/data/datasources/get_vehical_remote_data_source.dart';
import 'package:tara_driver_application/presentation/blocs/vehical_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// D-04 (docs/12) — CurrentDriverInfoBloc migrated to HomeController
// (features/home/presentation/controller/home_controller.dart).
List<BlocProvider> _listBlocProvider = [
  BlocProvider<VehicalBloc>(
      create: (context) => VehicalBloc(GetVehicalRemoteDataSource())),
];
List<BlocProvider> get listBlocProvider => _listBlocProvider;
