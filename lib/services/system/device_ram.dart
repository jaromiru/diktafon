/// Total physical RAM on Apple platforms — iOS has no `/proc/meminfo`, so
/// the soft device gate (§6.6) asks `sysctlbyname("hw.memsize")` through FFI
/// instead. Sync on purpose: the gate runs inside widget builds.
library;

import 'dart:ffi';

import 'package:ffi/ffi.dart';

typedef _SysctlByNameC = Int32 Function(
    Pointer<Utf8>, Pointer<Void>, Pointer<Size>, Pointer<Void>, Size);
typedef _SysctlByNameDart = int Function(
    Pointer<Utf8>, Pointer<Void>, Pointer<Size>, Pointer<Void>, int);

/// Null when the lookup fails — callers fail open, like the meminfo path.
int? applePhysicalRamBytes() {
  try {
    final sysctlbyname = DynamicLibrary.process()
        .lookupFunction<_SysctlByNameC, _SysctlByNameDart>('sysctlbyname');
    return using((arena) {
      final name = 'hw.memsize'.toNativeUtf8(allocator: arena);
      final value = arena<Int64>()..value = 0;
      final size = arena<Size>()..value = sizeOf<Int64>();
      final rc = sysctlbyname(name, value.cast(), size, nullptr, 0);
      return rc == 0 ? value.value : null;
    });
  } catch (_) {
    return null;
  }
}
