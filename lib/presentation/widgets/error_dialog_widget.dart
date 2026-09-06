import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

Future<void> showErrorCustomDialog(
    BuildContext context, String title, String description, bool comfirmBook) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text(description),
            ],
          ),
        ),
        actions: <Widget>[
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              // primary: Colors.red, // Customize your button color
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24),
            ),
            child: Text(comfirmBook == true ? "OK".tr() : 'Try Again'),
            onPressed: () {
              if (comfirmBook == true) {
                Navigator.of(context).pop();
                // Navigator.of(context).popUntil((route) => route.isFirst);
              }
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}
