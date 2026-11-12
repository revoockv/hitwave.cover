import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import '../../../../core/domain/entities/disposable_resource.dart';
import '../models/enhance_progress_model.dart';
import '../models/enhance_report_model.dart';
import '../models/recording_analysis_model.dart';
import 'python_engine_channel.dart';
import 'vocal_enhance_data_source.dart';

/// [VocalEnhanceDataSource] speaking the vocal_enhance worker protocol over a [PythonEngineChannel].
///
/// The engine starts on the first request (Python and numpy take a few seconds to load) and then
/// stays up. Requests carry an id; the engine answers each with progress events and one `done`,
/// `analysis` or `error` event with the same id. The protocol is described in the skill's
/// `WorkerProtocol` (vocal_enhance/features/enhance/presentation/worker/enhance_worker.py).
final class PythonVocalEnhanceDataSource implements VocalEnhanceDataSource, DisposableResource {
  static const int _protocolVersion = 1;
  static const Duration _startTimeout = Duration(seconds: 90);
  static const Duration _sendRetryDelay = Duration(milliseconds: 50);
  static const String _idPrefix = 'request-';

  static const String _opKey = 'op';
  static const String _eventKey = 'event';
  static const String _idKey = 'id';
  static const String _inputKey = 'input';
  static const String _outputKey = 'output';
  static const String _presetKey = 'preset';
  static const String _settingsKey = 'settings';
  static const String _messageKey = 'message';
  static const String _protocolKey = 'protocol';
  static const String _analysisKey = 'analysis';
  static const String _reportKey = 'report';
  static const String _analyzeOp = 'analyze';
  static const String _enhanceOp = 'enhance';
  static const String _readyEvent = 'ready';
  static const String _startupErrorEvent = 'startup_error';
  static const String _progressEvent = 'progress';
  static const String _analysisEvent = 'analysis';
  static const String _doneEvent = 'done';
  static const String _errorEvent = 'error';

  static const String _unavailableError = 'Покращення звуку недоступне на цій платформі';
  static const String _notStartedError = 'Аудіорушій не запустився';
  static const String _protocolError = 'Аудіорушій має іншу версію протоколу';
  static const String _closedError = 'Аудіорушій зупинено';
  static const String _separator = ': ';

  final PythonEngineChannel? _channel;
  final Map<String, _PendingRequest> _pending = <String, _PendingRequest>{};
  StreamSubscription<Uint8List>? _subscription;
  Completer<void>? _ready;
  int _nextId = 0;

  /// Creates the data source over [channel]; `null` means the platform has no embedded Python.
  PythonVocalEnhanceDataSource(this._channel);

  @override
  Future<RecordingAnalysisModel> analyze(String inputPath) async {
    final Map<String, dynamic> event = await _request(<String, dynamic>{
      _opKey: _analyzeOp,
      _inputKey: inputPath,
    }, onProgress: null);
    return RecordingAnalysisModel.fromJson(event[_analysisKey] as Map<String, dynamic>);
  }

  @override
  Future<EnhanceReportModel> enhance({
    required String inputPath,
    required String outputPath,
    required String preset,
    required Map<String, double> settings,
    required void Function(EnhanceProgressModel progress) onProgress,
  }) async {
    final Map<String, dynamic> event = await _request(<String, dynamic>{
      _opKey: _enhanceOp,
      _inputKey: inputPath,
      _outputKey: outputPath,
      _presetKey: preset,
      _settingsKey: settings,
    }, onProgress: onProgress);
    return EnhanceReportModel.fromJson(event[_reportKey] as Map<String, dynamic>);
  }

  /// Stops listening and fails the requests that are still waiting.
  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    _channel?.close();
    for (final _PendingRequest pending in _pending.values) {
      pending.answer.completeError(const VocalEnhanceEngineException(_closedError));
    }
    _pending.clear();
  }

  Future<Map<String, dynamic>> _request(
    Map<String, dynamic> message, {
    required void Function(EnhanceProgressModel progress)? onProgress,
  }) async {
    final PythonEngineChannel channel = _channel ?? (throw const VocalEnhanceEngineException(_unavailableError));
    await _start(channel);
    final String id = '$_idPrefix${_nextId++}';
    final _PendingRequest pending = _PendingRequest(onProgress);
    _pending[id] = pending;
    try {
      await _send(channel, <String, dynamic>{...message, _idKey: id});
    } on VocalEnhanceEngineException {
      _pending.remove(id);
      rethrow;
    }
    return pending.answer.future;
  }

  Future<void> _start(PythonEngineChannel channel) {
    final Completer<void>? started = _ready;
    if (started != null) {
      return started.future;
    }
    final Completer<void> ready = Completer<void>();
    _ready = ready;
    _subscription = channel.messages.listen(_onMessage);
    channel.start().catchError((Object error) => _failStart('$_notStartedError$_separator$error'));
    return ready.future.timeout(_startTimeout, onTimeout: _onStartTimeout);
  }

  void _onStartTimeout() {
    _failStart(_notStartedError);
    throw const VocalEnhanceEngineException(_notStartedError);
  }

  void _failStart(String message) {
    final Completer<void>? ready = _ready;
    if (ready != null && !ready.isCompleted) {
      ready.completeError(VocalEnhanceEngineException(message));
    }
  }

  Future<void> _send(PythonEngineChannel channel, Map<String, dynamic> message) async {
    final Uint8List bytes = utf8.encode(jsonEncode(message));
    final Stopwatch waited = Stopwatch()..start();
    while (!channel.send(bytes)) {
      if (waited.elapsed > _startTimeout) {
        throw const VocalEnhanceEngineException(_notStartedError);
      }
      await Future<void>.delayed(_sendRetryDelay);
    }
  }

  void _onMessage(Uint8List bytes) {
    final Object? decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map<String, dynamic>) {
      return;
    }
    final String? event = decoded[_eventKey] as String?;
    final String? id = decoded[_idKey] as String?;
    switch (event) {
      case _readyEvent:
        _onReady(decoded);
      case _startupErrorEvent:
        _failStart('$_notStartedError$_separator${decoded[_messageKey]}');
      case _progressEvent:
        _pending[id]?.onProgress?.call(EnhanceProgressModel.fromJson(decoded));
      case _analysisEvent || _doneEvent:
        _pending.remove(id)?.answer.complete(decoded);
      case _errorEvent:
        _pending.remove(id)?.answer.completeError(VocalEnhanceEngineException(decoded[_messageKey] as String));
    }
  }

  void _onReady(Map<String, dynamic> event) {
    final Completer<void>? ready = _ready;
    if (ready == null || ready.isCompleted) {
      return;
    }
    if (event[_protocolKey] != _protocolVersion) {
      ready.completeError(const VocalEnhanceEngineException(_protocolError));
      return;
    }
    ready.complete();
  }
}

/// A request waiting for its answer.
final class _PendingRequest {
  final void Function(EnhanceProgressModel progress)? onProgress;
  final Completer<Map<String, dynamic>> answer = Completer<Map<String, dynamic>>();

  _PendingRequest(this.onProgress);
}
