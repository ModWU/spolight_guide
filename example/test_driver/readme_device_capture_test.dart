import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  final Directory output = Directory('../doc/images/readme/device_frames');
  await output.create(recursive: true);

  await integrationDriver(
    onScreenshot:
        (String name, List<int> image, [Map<String, Object?>? args]) async {
          final File file = File('${output.path}/$name.png');
          await file.writeAsBytes(image, flush: true);
          return true;
        },
    responseDataCallback: (_) async {},
  );
}
