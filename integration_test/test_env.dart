/// Test-parameter lookup that works on every target. Desktop runs read real
/// environment variables; on iOS simulators/devices `flutter test` launches
/// the app without the caller's environment (SIMCTL_CHILD_* included), so the
/// same keys can also arrive baked in as `--dart-define=KEY=value`.
///
/// `String.fromEnvironment` only works with const names, hence the explicit
/// key table instead of a generic lookup.
library;

import 'dart:io';

const _defines = <String, String>{
  'DIKTAFON_TEST_DIR': String.fromEnvironment('DIKTAFON_TEST_DIR'),
  'DIKTAFON_WHISPER_MODEL': String.fromEnvironment('DIKTAFON_WHISPER_MODEL'),
  'DIKTAFON_LLM_MODEL': String.fromEnvironment('DIKTAFON_LLM_MODEL'),
  'DIKTAFON_SHOT_PROFILE': String.fromEnvironment('DIKTAFON_SHOT_PROFILE'),
  'LIBMPV_PATH': String.fromEnvironment('LIBMPV_PATH'),
};

String? testEnv(String name) {
  final env = Platform.environment[name];
  if (env != null && env.isNotEmpty) return env;
  final define = _defines[name];
  if (define != null && define.isNotEmpty) return define;
  return null;
}
