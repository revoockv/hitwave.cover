import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:hitwave.cover/features/auth/domain/entities/user.dart';
import 'package:watch_it/watch_it.dart';


/// Returns the current authentication session as a [ValueListenable].
///
/// Use this getter in UI widgets to watch the current user session.
/// Returns [null] when the user is signed out.
ValueListenable<User?> get authSession {
  return GetIt.instance<ValueNotifier<User?>>(
    instanceName: 'auth.session',
  );
}
