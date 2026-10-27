import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NativeMaterials {
  static bool available = false;
  static Future<void> initialize() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;
    try {
      final data = await const MethodChannel('aura/native_ui')
          .invokeMapMethod<String, dynamic>('capabilities');
      available = data?['liquidGlass'] == true;
    } catch (_) {
      available = false;
    }
  }
}

class NativeGlassControl extends StatefulWidget {
  const NativeGlassControl({
    super.key,
    required this.kind,
    required this.config,
    required this.onEvent,
  });
  final String kind;
  final Map<String, dynamic> config;
  final void Function(String, dynamic) onEvent;
  @override
  State<NativeGlassControl> createState() => _NativeGlassControlState();
}

class _NativeGlassControlState extends State<NativeGlassControl> {
  MethodChannel? _channel;
  @override
  void didUpdateWidget(covariant NativeGlassControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!mapEquals(oldWidget.config, widget.config)) {
      unawaited(_channel?.invokeMethod<void>('update', widget.config));
    }
  }

  @override
  void dispose() {
    _channel?.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => UiKitView(
    viewType: 'aura/native_${widget.kind}',
    layoutDirection: Directionality.of(context),
    creationParams: widget.config,
    creationParamsCodec: const StandardMessageCodec(),
    onPlatformViewCreated: (id) {
      _channel = MethodChannel('aura/native_${widget.kind}/$id');
      _channel!.setMethodCallHandler((call) async {
        widget.onEvent(call.method, call.arguments);
      });
      unawaited(_channel!.invokeMethod<void>('update', widget.config));
    },
  );
}
