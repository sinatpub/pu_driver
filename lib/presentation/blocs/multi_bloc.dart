import 'package:tara_driver_application/data/datasources/get_vehical_remote_data_source.dart';
import 'package:tara_driver_application/presentation/blocs/get_current_driver_info_bloc.dart';
import 'package:tara_driver_application/presentation/blocs/vehical_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

List<BlocProvider> _listBlocProvider = [
  BlocProvider<VehicalBloc>(
      create: (context) => VehicalBloc(GetVehicalRemoteDataSource())),
  BlocProvider<CurrentDriverInfoBloc>(
      create: (context) => CurrentDriverInfoBloc()),
];
List<BlocProvider> get listBlocProvider => _listBlocProvider;
