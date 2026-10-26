import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aura/core/design/aura_mark.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('render original AURA icon for native platforms', () async {
    Future<void> render(String path, int dimension) async {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      AuraMarkPainter().paint(
        canvas,
        Size(dimension.toDouble(), dimension.toDouble()),
      );
      final picture = recorder.endRecording();
      final image = await picture.toImage(dimension, dimension);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File(path).writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
      picture.dispose();
    }

    await render('assets/icons/aura-icon.png', 1024);
    final manifest = jsonDecode(
      await File('ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json')
          .readAsString(),
    ) as Map<String, dynamic>;
    for (final entry in manifest['images'] as List) {
      final px =
          (double.parse((entry['size'] as String).split('x').first) *
                  double.parse((entry['scale'] as String).replaceAll('x', '')))
              .round();
      await render(
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/${entry['filename']}',
        px,
      );
    }
    for (final entry in {
      'mdpi': 48,
      'hdpi': 72,
      'xhdpi': 96,
      'xxhdpi': 144,
      'xxxhdpi': 192,
    }.entries) {
      await render(
        'android/app/src/main/res/mipmap-${entry.key}/ic_launcher.png',
        entry.value,
      );
    }
    expect(await File('assets/icons/aura-icon.png').exists(), isTrue);
  });
}
