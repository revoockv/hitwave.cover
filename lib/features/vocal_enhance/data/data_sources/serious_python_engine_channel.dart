import 'dart:typed_data';

import 'package:serious_python/bridge.dart';
import 'package:serious_python/serious_python.dart';

import 'python_engine_channel.dart';

/// The channel of this platform: embedded CPython (serious_python) over an in-process bridge.
///
/// Chosen by a conditional import where `dart:ffi` exists (Android, iOS, macOS, Windows, Linux).
PythonEngineChannel? createPythonEngineChannel() => SeriousPythonEngineChannel();

/// [PythonEngineChannel] backed by serious_python's [PythonBridge].
///
/// The bridge's native port goes to `python/app/main.py` in an environment variable; Python
/// registers its handler under that port and sends its events to it.
final class SeriousPythonEngineChannel implements PythonEngineChannel {
  static const String _portVariable = 'HITWAVE_ENHANCE_PORT';

  final PythonBridge _bridge = PythonBridge();

  @override
  Stream<Uint8List> get messages => _bridge.messages;

  @override
  Future<void> start() async {
    await SeriousPython.run(environmentVariables: <String, String>{_portVariable: '${_bridge.port}'});
  }

  @override
  bool send(Uint8List bytes) => _bridge.send(bytes);

  @override
  void close() => _bridge.close();
}
