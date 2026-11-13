import 'python_engine_channel.dart';

/// The channel of this platform: none — the web has no embedded Python.
///
/// Chosen by a conditional import where `dart:ffi` is missing.
PythonEngineChannel? createPythonEngineChannel() => null;
