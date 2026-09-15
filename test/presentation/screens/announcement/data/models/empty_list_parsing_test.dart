import 'package:flutter_test/flutter_test.dart';
import 'package:tara_driver_application/presentation/screens/announcement/data/models/notifcation_model.dart';

/// Same defect as the wallet's (N-01): these models parsed their lists with
/// `List<T>.from(json["key"].map(...))`, so an absent or null key was a
/// NoSuchMethodError rather than an empty list. Found by grepping for the
/// shape after the wallet fix; eleven sites across both apps.
///
/// These are the new-driver cases: no notifications yet.
void main() {
  group('NotificationModel — a driver with no notifications', () {
    test('a null data list parses instead of crashing', () {
      expect(NotificationModel.fromJson({'data': null}).data, isEmpty);
    });

    test('an absent data key is survivable', () {
      expect(NotificationModel.fromJson({}).data, isEmpty);
    });
  });
}