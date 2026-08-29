import 'package:tara_driver_application/data/datasources/get_vehical_remote_data_source.dart';
import 'package:tara_driver_application/presentation/blocs/driver_wallet_bloc.dart';
import 'package:tara_driver_application/presentation/blocs/get_current_driver_info_bloc.dart';
import 'package:tara_driver_application/presentation/blocs/get_version_app.dart';
import 'package:tara_driver_application/presentation/blocs/notification_bloc.dart';
import 'package:tara_driver_application/presentation/blocs/notification_detail_bloc.dart';
import 'package:tara_driver_application/presentation/blocs/otp_bloc.dart';
import 'package:tara_driver_application/presentation/blocs/phone_login_bloc.dart';
import 'package:tara_driver_application/presentation/blocs/register_bloc.dart';
import 'package:tara_driver_application/presentation/blocs/vehical_bloc.dart';
import 'package:tara_driver_application/presentation/screens/booking/booking/bloc/booking_bloc.dart';
import 'package:tara_driver_application/presentation/screens/home_screen/bloc/home_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

List<BlocProvider> _listBlocProvider = [
  BlocProvider<HomeBloc>(create: (context) => HomeBloc()),
  BlocProvider<VehicalBloc>(
      create: (context) => VehicalBloc(GetVehicalRemoteDataSource())),
  BlocProvider<PhoneLoginBloc>(
    create: (context) => PhoneLoginBloc(),
  ),
  BlocProvider<OTPVerifyBloc>(
    create: (context) => OTPVerifyBloc(),
  ),
  BlocProvider<RegisterBloc>(create: (context) => RegisterBloc()),
  BlocProvider<CurrentDriverInfoBloc>(
      create: (context) => CurrentDriverInfoBloc()),
  BlocProvider<BookingBloc>(create: (context) => BookingBloc()),
  BlocProvider<DriverWalletBloc>(create: (context) => DriverWalletBloc()),
  BlocProvider<VersionAppBloc>(create: (context) => VersionAppBloc()),
  BlocProvider<NotificationDetailBloc>(
      create: (context) => NotificationDetailBloc()),
];
List<BlocProvider> get listBlocProvider => _listBlocProvider;
