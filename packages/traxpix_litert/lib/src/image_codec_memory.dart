import 'dart:ffi' as ffi;
import 'dart:io';

/// Memory a photo rebuild needs on top of what the app already uses: the
/// decoder, the safety classifier and their working buffers.
///
/// Measured on an iPhone XS (iOS 18.7) with the weight cache: 1.31 GiB from
/// start to the lowest point, the first rebuild (which writes the cache)
/// included, plus 0.1 GiB for the app's own growth.
const int kImageCodecRebuildBytes = 1444 * 1024 * 1024;

final int Function()? _osProcAvailableMemory = Platform.isIOS
    ? ffi.DynamicLibrary.process()
          .lookupFunction<ffi.Size Function(), int Function()>(
            'os_proc_available_memory',
          )
    : null;

/// How many more bytes this app may use before the system stops it, or null
/// where the platform doesn't say (everywhere but iOS, so far).
///
/// On iOS this counts the app's whole footprint, graphics and compressed
/// memory included, which the resident set size leaves out.
int? imageCodecAvailableMemory() => _osProcAvailableMemory?.call();

/// Whether a rebuild fits now. True where the platform can't tell.
bool imageCodecHasRoomToRebuild() {
  final available = imageCodecAvailableMemory();
  return available == null || available >= kImageCodecRebuildBytes;
}

/// Memory a 4x enlargement needs, with the rebuild's models closed.
///
/// Measured on an iPhone XS (iOS 18.7): 0.95 GiB from start to the lowest
/// point, plus 0.1 GiB for the app's own growth.
const int kImageCodecEnhanceBytes = 1075 * 1024 * 1024;

/// Whether an enlargement fits now. On Android, where no limit per app is
/// given, this is the memory the whole phone has available: a little less
/// than the app could get. True where the platform can't tell.
bool imageCodecHasRoomToEnhance() {
  final available = imageCodecAvailableMemory() ?? _androidMemAvailable();
  return available == null || available >= kImageCodecEnhanceBytes;
}

int? _androidMemAvailable() {
  if (!Platform.isAndroid) return null;
  try {
    for (final line in File('/proc/meminfo').readAsLinesSync()) {
      if (line.startsWith('MemAvailable:')) {
        return int.parse(line.split(RegExp(r'\s+'))[1]) * 1024;
      }
    }
  } on Object catch (_) {}
  return null;
}
