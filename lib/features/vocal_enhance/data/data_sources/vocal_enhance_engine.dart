import 'package_vocal_enhance_data_source.dart';
import 'vocal_enhance_data_source.dart';

/// The audio engine of platforms with a file system: the pure-Dart package.
VocalEnhanceDataSource createVocalEnhanceDataSource() =>
    PackageVocalEnhanceDataSource();
