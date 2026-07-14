import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tara_driver_application/data/datasources/get_version_app.dart';
import 'package:tara_driver_application/data/models/version_app_model.dart';

class VersionAppBloc extends Bloc<VersionAppEvent, VersionAppState> {
  final GetVersionAppApi getVersionApp = GetVersionAppApi();
  VersionAppBloc() : super(VersionAppInitial()) {
    on<GetVersionApp>((event, emit) async{
      emit(VersionAppLoading());
      try{
         var dataVersion = await getVersionApp.getDriverWalletApi();
         emit(VersionAppLoaded(versionData: dataVersion));
      }catch(e){
        emit(VersionAppError());
      }
    });
  }
}


@immutable
sealed class VersionAppState {}

final class VersionAppInitial extends VersionAppState {}

final class VersionAppLoading extends VersionAppState {}

final class VersionAppLoaded extends VersionAppState {
  final VersionAppModel versionData;
  VersionAppLoaded({required this.versionData});
}

final class VersionAppError extends VersionAppState {}



@immutable
sealed class VersionAppEvent {}

class GetVersionApp extends VersionAppEvent{}
