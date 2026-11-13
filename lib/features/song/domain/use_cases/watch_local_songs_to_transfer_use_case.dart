import 'package:flutter/foundation.dart' show ValueListenable;

import '../repositories/song_repository.dart';

/// Use case that watches how many songs on the device may be moved into the account.
final class WatchLocalSongsToTransferUseCase {
  final SongRepository _repository;

  /// Creates a new [WatchLocalSongsToTransferUseCase].
  WatchLocalSongsToTransferUseCase(this._repository);

  /// The number of songs to offer after a sign-in; `0` when there is nothing to ask.
  ValueListenable<int> call() {
    return _repository.watchLocalSongsToTransfer();
  }
}
