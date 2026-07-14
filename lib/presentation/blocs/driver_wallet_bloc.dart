import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tara_driver_application/data/datasources/get_driver_waleet_data_api.dart';
import 'package:tara_driver_application/data/models/wallet_model.dart';

class DriverWalletBloc extends Bloc<DriverWalletEvent, DriverWalletState> {
  final GetDriverWAallet getDriverWAallet = GetDriverWAallet();
  DriverWalletBloc() : super(DriverWalletInitial()) {
    on<GetDriverWallet>((event, emit) async{
      emit(DriverWalletLoading());
      try{
         var dataWaleet = await getDriverWAallet.getDriverWalletApi();
         emit(DriverWalletLoaded(walletData: dataWaleet));
      }catch(e){
        emit(DriverWalletError());
      }
    });
  }
}


@immutable
sealed class DriverWalletState {}

final class DriverWalletInitial extends DriverWalletState {}

final class DriverWalletLoading extends DriverWalletState {}

final class DriverWalletLoaded extends DriverWalletState {
  final WalletModel walletData;
  DriverWalletLoaded({required this.walletData});
}

final class DriverWalletError extends DriverWalletState {}



@immutable
sealed class DriverWalletEvent {}

class GetDriverWallet extends DriverWalletEvent{}
