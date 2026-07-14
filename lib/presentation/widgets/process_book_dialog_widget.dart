import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tara_driver_application/core/theme/colors.dart';

Future<void> showPocessBookingLoadingDialog({required Function() onYes, required BuildContext context,required String title,}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(title),
            actions: <Widget>[
               ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                ),
                onPressed: () {
                  
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(child: CircularProgressIndicator(color: AppColors.dark4,),),
                  ],
                )
              ),
            ],
          );
        }
      );
    },
  );
}
