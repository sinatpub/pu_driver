import 'package:flutter/material.dart';
import 'package:tara_driver_application/core/theme/colors.dart';
import 'package:tara_driver_application/core/theme/text_styles.dart';
import 'package:tara_driver_application/core/utils/app_constant.dart';
import 'package:tara_driver_application/core/utils/check_platform_device.dart';
import 'package:url_launcher/url_launcher.dart';

class WidgetUpdate extends StatefulWidget {
  const WidgetUpdate({Key? key}) : super(key: key);

  @override
  State<WidgetUpdate> createState() => _WidgetUpdateState();
}

class _WidgetUpdateState extends State<WidgetUpdate> {
  var platform = checkPlatformDevice();
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      margin: EdgeInsets.symmetric(horizontal: 20),
      constraints: BoxConstraints(
        minHeight: 200,
        maxHeight: 280,
      ),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10), color: Colors.white),
      child: Column(
        spacing: 12,
        children: [
          Image.asset(
            "assets/image/png/Tara2.png",
            width: 80,
            height: 80,
          ),
          Text(
            "App must update",
            style:
                ThemeConstands.font20SemiBold.copyWith(color: AppColors.dark1),
            textAlign: TextAlign.center,
          ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 28, horizontal: 28),
            height: 45,
            child: MaterialButton(
              color: AppColors.main,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              padding: const EdgeInsets.all(0),
              onPressed: () {
                setState(() {
                  if (platform == "Android") {
                    launchUrl(
                      Uri.parse(
                        AppConstant.playStoreUrl,
                      ),
                      mode: LaunchMode.externalApplication,
                    );
                  } else {
                    launchUrl(
                      Uri.parse(
                        AppConstant.appStoreUrl,
                      ),
                      mode: LaunchMode.externalApplication,
                    );
                  }
                });
              },
              child: Center(
                child: Text(
                  "Update Now",
                  style: ThemeConstands.font16SemiBold
                      .copyWith(color: AppColors.light4),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
