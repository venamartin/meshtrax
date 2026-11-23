import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

/// `LiteRtLayout` from LiteRT 2.3.0's `litert_layout.h`: a 7-bit rank and a
/// has-strides bit in one word, then up to 8 dimensions and strides.
final class LiteRtLayout extends Struct {
  @Uint32()
  external int rankBits;

  @Array(8)
  external Array<Int32> dimensions;

  @Array(8)
  external Array<Uint32> strides;
}

/// `LiteRtRankedTensorType` from `litert_model_types.h` (72 bytes).
final class LiteRtRankedTensorType extends Struct {
  @Int32()
  external int elementType;

  external LiteRtLayout layout;
}

const int _kElementTypeFloat32 = 1;
const int _kHwAcceleratorCpu = 1;
const int _kHostMemoryAlignment = 64;

/// XNNPACK's TFLITE_XNNPACK_DELEGATE_FLAG_FORCE_FP16: a float32 model's
/// operators run in half precision.
const int kXnnpackForceFp16 = 0x4;

class LiteRtException implements Exception {
  final String call;
  final int status;
  final String message;

  const LiteRtException(this.call, this.status, this.message);

  @override
  String toString() => 'LiteRT $call failed: $message ($status)';
}

typedef _Out = Pointer<Pointer<Void>>;
typedef _FreeNative = Void Function(Pointer<Void>);

/// The parts of LiteRT 2.3.0's C API the photo codec uses, from the library
/// each platform ships: `libLiteRt.so` from Google's Android package, the
/// `CLiteRT` framework on iPhones, `libCLiteRT_mac.dylib` on the Mac.
class LiteRtApi {
  final DynamicLibrary _lib;

  LiteRtApi._(this._lib);

  static LiteRtApi? _instance;

  /// Opens the library once per isolate. [path] overrides the platform's
  /// default, for host tests.
  static LiteRtApi open([String? path]) =>
      _instance ??= LiteRtApi._(_openLibrary(path));

  static DynamicLibrary _openLibrary(String? path) {
    try {
      return DynamicLibrary.open(path ?? _defaultPath());
    } on ArgumentError {
      // The app links LiteRT's library, so on iPhones and Macs its symbols
      // are in the process even when the library's path doesn't resolve.
      if (path == null && (Platform.isIOS || Platform.isMacOS)) {
        return DynamicLibrary.process();
      }
      rethrow;
    }
  }

  static String _defaultPath() {
    if (Platform.isAndroid) return 'libLiteRt.so';
    if (Platform.isIOS) return 'CLiteRT.framework/CLiteRT';
    if (Platform.isMacOS) return 'libCLiteRT_mac.dylib';
    throw UnsupportedError('LiteRT is not set up for this platform.');
  }

  late final _statusString = _lib
      .lookupFunction<
        Pointer<Utf8> Function(Int32),
        Pointer<Utf8> Function(int)
      >('LiteRtGetStatusString');
  late final createEnvironment = _lib
      .lookupFunction<
        Int32 Function(Int32, Pointer<Void>, _Out),
        int Function(int, Pointer<Void>, _Out)
      >('LiteRtCreateEnvironment');
  late final destroyEnvironment = _lib
      .lookupFunction<_FreeNative, void Function(Pointer<Void>)>(
        'LiteRtDestroyEnvironment',
      );
  late final createModelFromFile = _lib
      .lookupFunction<
        Int32 Function(Pointer<Void>, Pointer<Utf8>, _Out),
        int Function(Pointer<Void>, Pointer<Utf8>, _Out)
      >('LiteRtCreateModelFromFile');
  late final destroyModel = _lib
      .lookupFunction<_FreeNative, void Function(Pointer<Void>)>(
        'LiteRtDestroyModel',
      );
  late final getModelSignature = _lib
      .lookupFunction<
        Int32 Function(Pointer<Void>, Size, _Out),
        int Function(Pointer<Void>, int, _Out)
      >('LiteRtGetModelSignature');
  late final getNumSignatureInputs = _lib
      .lookupFunction<
        Int32 Function(Pointer<Void>, Pointer<Size>),
        int Function(Pointer<Void>, Pointer<Size>)
      >('LiteRtGetNumSignatureInputs');
  late final getNumSignatureOutputs = _lib
      .lookupFunction<
        Int32 Function(Pointer<Void>, Pointer<Size>),
        int Function(Pointer<Void>, Pointer<Size>)
      >('LiteRtGetNumSignatureOutputs');
  late final getSignatureInputName = _lib
      .lookupFunction<
        Int32 Function(Pointer<Void>, Size, Pointer<Pointer<Utf8>>),
        int Function(Pointer<Void>, int, Pointer<Pointer<Utf8>>)
      >('LiteRtGetSignatureInputName');
  late final getSignatureOutputName = _lib
      .lookupFunction<
        Int32 Function(Pointer<Void>, Size, Pointer<Pointer<Utf8>>),
        int Function(Pointer<Void>, int, Pointer<Pointer<Utf8>>)
      >('LiteRtGetSignatureOutputName');
  late final getSignatureInputTensor = _lib
      .lookupFunction<
        Int32 Function(Pointer<Void>, Size, _Out),
        int Function(Pointer<Void>, int, _Out)
      >('LiteRtGetSignatureInputTensorByIndex');
  late final getSignatureOutputTensor = _lib
      .lookupFunction<
        Int32 Function(Pointer<Void>, Size, _Out),
        int Function(Pointer<Void>, int, _Out)
      >('LiteRtGetSignatureOutputTensorByIndex');
  late final getRankedTensorType = _lib
      .lookupFunction<
        Int32 Function(Pointer<Void>, Pointer<LiteRtRankedTensorType>),
        int Function(Pointer<Void>, Pointer<LiteRtRankedTensorType>)
      >('LiteRtGetRankedTensorType');
  late final createOptions = _lib
      .lookupFunction<Int32 Function(_Out), int Function(_Out)>(
        'LiteRtCreateOptions',
      );
  late final destroyOptions = _lib
      .lookupFunction<_FreeNative, void Function(Pointer<Void>)>(
        'LiteRtDestroyOptions',
      );
  late final setOptionsHardwareAccelerators = _lib
      .lookupFunction<
        Int32 Function(Pointer<Void>, Int32),
        int Function(Pointer<Void>, int)
      >('LiteRtSetOptionsHardwareAccelerators');
  late final createOpaqueOptions = _lib
      .lookupFunction<
        Int32 Function(
          Pointer<Utf8>,
          Pointer<Void>,
          Pointer<NativeFunction<_FreeNative>>,
          _Out,
        ),
        int Function(
          Pointer<Utf8>,
          Pointer<Void>,
          Pointer<NativeFunction<_FreeNative>>,
          _Out,
        )
      >('LiteRtCreateOpaqueOptions');
  late final addOpaqueOptions = _lib
      .lookupFunction<
        Int32 Function(Pointer<Void>, Pointer<Void>),
        int Function(Pointer<Void>, Pointer<Void>)
      >('LiteRtAddOpaqueOptions');
  late final createCompiledModel = _lib
      .lookupFunction<
        Int32 Function(Pointer<Void>, Pointer<Void>, Pointer<Void>, _Out),
        int Function(Pointer<Void>, Pointer<Void>, Pointer<Void>, _Out)
      >('LiteRtCreateCompiledModel');
  late final destroyCompiledModel = _lib
      .lookupFunction<_FreeNative, void Function(Pointer<Void>)>(
        'LiteRtDestroyCompiledModel',
      );
  late final createTensorBufferFromHostMemory = _lib
      .lookupFunction<
        Int32 Function(
          Pointer<LiteRtRankedTensorType>,
          Pointer<Void>,
          Size,
          Pointer<Void>,
          _Out,
        ),
        int Function(
          Pointer<LiteRtRankedTensorType>,
          Pointer<Void>,
          int,
          Pointer<Void>,
          _Out,
        )
      >('LiteRtCreateTensorBufferFromHostMemory');
  late final destroyTensorBuffer = _lib
      .lookupFunction<_FreeNative, void Function(Pointer<Void>)>(
        'LiteRtDestroyTensorBuffer',
      );
  late final runCompiledModel = _lib
      .lookupFunction<
        Int32 Function(Pointer<Void>, Size, Size, _Out, Size, _Out),
        int Function(Pointer<Void>, int, int, _Out, int, _Out)
      >('LiteRtRunCompiledModel');

  static final DynamicLibrary _libc = DynamicLibrary.process();
  static final _posixMemalign = _libc
      .lookupFunction<
        Int32 Function(_Out, Size, Size),
        int Function(_Out, int, int)
      >('posix_memalign');
  static final Pointer<NativeFunction<Void Function(Pointer<Void>)>> libcFree =
      _libc.lookup<NativeFunction<_FreeNative>>('free');

  void check(String call, int status) {
    if (status != 0) {
      throw LiteRtException(call, status, _statusString(status).toDartString());
    }
  }

  /// [bytes] of host memory on LiteRT's 64-byte boundary; free with
  /// [malloc.free].
  static Pointer<Void> alignedAlloc(int bytes) {
    final out = calloc<Pointer<Void>>();
    try {
      final rc = _posixMemalign(out, _kHostMemoryAlignment, bytes);
      if (rc != 0) throw OutOfMemoryError();
      return out.value;
    } finally {
      calloc.free(out);
    }
  }
}

/// One LiteRT environment: what every compiled model belongs to.
class LiteRtEnvironment {
  final LiteRtApi api;
  final Pointer<Void> handle;

  LiteRtEnvironment._(this.api, this.handle);

  factory LiteRtEnvironment.create(LiteRtApi api) {
    final out = calloc<Pointer<Void>>();
    try {
      api.check(
        'LiteRtCreateEnvironment',
        api.createEnvironment(0, nullptr, out),
      );
      return LiteRtEnvironment._(api, out.value);
    } finally {
      calloc.free(out);
    }
  }

  void dispose() => api.destroyEnvironment(handle);
}

/// One `.tflite` model compiled for the CPU (XNNPACK), with host buffers for
/// its signature's float32 inputs and outputs, reused by every run.
///
/// The model file is mapped, not read. With [weightCachePath], XNNPACK keeps
/// its packed weights in that file too (written on first use), so they are
/// mapped from disk instead of taking the app's memory.
class LiteRtModel {
  final LiteRtApi _api;
  final String path;
  final Pointer<Void> _model;
  final Pointer<Void> _options;
  final Pointer<Void> _compiled;
  final List<String> inputNames;
  final List<String> outputNames;
  final List<int> _inputLengths;
  final List<int> _outputLengths;
  final List<Pointer<Void>> _inputMemory;
  final List<Pointer<Void>> _outputMemory;
  final Pointer<Pointer<Void>> _inputBuffers;
  final Pointer<Pointer<Void>> _outputBuffers;
  bool _disposed = false;

  LiteRtModel._(
    this._api,
    this.path,
    this._model,
    this._options,
    this._compiled,
    this.inputNames,
    this.outputNames,
    this._inputLengths,
    this._outputLengths,
    this._inputMemory,
    this._outputMemory,
    this._inputBuffers,
    this._outputBuffers,
  );

  /// [xnnpackFlags] are XNNPACK delegate flags, such as [kXnnpackForceFp16];
  /// zero leaves LiteRT's defaults.
  factory LiteRtModel.load(
    LiteRtEnvironment environment,
    String path, {
    required int threads,
    String? weightCachePath,
    int xnnpackFlags = 0,
  }) {
    final api = environment.api;
    final out = calloc<Pointer<Void>>();
    final count = calloc<Size>();
    final name = calloc<Pointer<Utf8>>();
    final type = calloc<LiteRtRankedTensorType>();
    final filename = path.toNativeUtf8();
    Pointer<Void> model = nullptr;
    Pointer<Void> options = nullptr;
    Pointer<Void> compiled = nullptr;
    final inputMemory = <Pointer<Void>>[];
    final outputMemory = <Pointer<Void>>[];
    final buffers = <Pointer<Void>>[];
    try {
      api.check(
        'LiteRtCreateModelFromFile($path)',
        api.createModelFromFile(environment.handle, filename, out),
      );
      model = out.value;
      api.check(
        'LiteRtGetModelSignature',
        api.getModelSignature(model, 0, out),
      );
      final signature = out.value;

      api.check('LiteRtCreateOptions', api.createOptions(out));
      options = out.value;
      api.check(
        'LiteRtSetOptionsHardwareAccelerators',
        api.setOptionsHardwareAccelerators(options, _kHwAcceleratorCpu),
      );
      // The CPU accelerator's settings are TOML text under "xnnpack", which
      // is what LiteRT's own builder writes (Android's library has no
      // builder). LiteRT frees the text with the destructor.
      final toml = StringBuffer('num_threads = $threads\n');
      if (weightCachePath != null) {
        toml.write('weight_cache_file_path = "$weightCachePath"\n');
      }
      if (xnnpackFlags != 0) toml.write('flags = $xnnpackFlags\n');
      final identifier = 'xnnpack'.toNativeUtf8();
      try {
        api.check(
          'LiteRtCreateOpaqueOptions',
          api.createOpaqueOptions(
            identifier,
            toml.toString().toNativeUtf8(allocator: malloc).cast(),
            LiteRtApi.libcFree,
            out,
          ),
        );
      } finally {
        calloc.free(identifier);
      }
      api.check(
        'LiteRtAddOpaqueOptions',
        api.addOpaqueOptions(options, out.value),
      );
      api.check(
        'LiteRtCreateCompiledModel($path)',
        api.createCompiledModel(environment.handle, model, options, out),
      );
      compiled = out.value;

      List<String> names(bool inputs) {
        api.check(
          'LiteRtGetNumSignature${inputs ? 'In' : 'Out'}puts',
          inputs
              ? api.getNumSignatureInputs(signature, count)
              : api.getNumSignatureOutputs(signature, count),
        );
        return [
          for (var i = 0; i < count.value; i++)
            () {
              api.check(
                'LiteRtGetSignature${inputs ? 'In' : 'Out'}putName',
                inputs
                    ? api.getSignatureInputName(signature, i, name)
                    : api.getSignatureOutputName(signature, i, name),
              );
              return name.value.toDartString();
            }(),
        ];
      }

      final inputNames = names(true);
      final outputNames = names(false);

      List<int> allocate(bool inputs, int n, List<Pointer<Void>> memory) {
        final lengths = <int>[];
        for (var i = 0; i < n; i++) {
          api.check(
            'LiteRtGetSignature${inputs ? 'In' : 'Out'}putTensorByIndex',
            inputs
                ? api.getSignatureInputTensor(signature, i, out)
                : api.getSignatureOutputTensor(signature, i, out),
          );
          api.check(
            'LiteRtGetRankedTensorType',
            api.getRankedTensorType(out.value, type),
          );
          if (type.ref.elementType != _kElementTypeFloat32) {
            throw StateError(
              '$path: tensor ${inputs ? 'input' : 'output'} $i is element '
              'type ${type.ref.elementType}, not float32',
            );
          }
          final rank = type.ref.layout.rankBits & 0x7f;
          var length = 1;
          for (var d = 0; d < rank; d++) {
            length *= type.ref.layout.dimensions[d];
          }
          final bytes = length * 4;
          final host = LiteRtApi.alignedAlloc(bytes);
          memory.add(host);
          api.check(
            'LiteRtCreateTensorBufferFromHostMemory',
            api.createTensorBufferFromHostMemory(
              type,
              host,
              bytes,
              nullptr,
              out,
            ),
          );
          buffers.add(out.value);
          lengths.add(length);
        }
        return lengths;
      }

      final inputLengths = allocate(true, inputNames.length, inputMemory);
      final outputLengths = allocate(false, outputNames.length, outputMemory);
      final inputBuffers = calloc<Pointer<Void>>(inputNames.length);
      final outputBuffers = calloc<Pointer<Void>>(outputNames.length);
      for (var i = 0; i < inputNames.length; i++) {
        inputBuffers[i] = buffers[i];
      }
      for (var i = 0; i < outputNames.length; i++) {
        outputBuffers[i] = buffers[inputNames.length + i];
      }
      return LiteRtModel._(
        api,
        path,
        model,
        options,
        compiled,
        inputNames,
        outputNames,
        inputLengths,
        outputLengths,
        inputMemory,
        outputMemory,
        inputBuffers,
        outputBuffers,
      );
    } catch (_) {
      for (final buffer in buffers) {
        api.destroyTensorBuffer(buffer);
      }
      for (final host in [...inputMemory, ...outputMemory]) {
        malloc.free(host);
      }
      if (compiled != nullptr) api.destroyCompiledModel(compiled);
      if (options != nullptr) api.destroyOptions(options);
      if (model != nullptr) api.destroyModel(model);
      rethrow;
    } finally {
      calloc.free(out);
      calloc.free(count);
      calloc.free(name);
      calloc.free(type);
      calloc.free(filename);
    }
  }

  /// Runs the model on [inputs], in the signature's input order, and returns
  /// copies of every output by name (`output_0`, `output_1`, ...).
  Map<String, Float32List> run(List<Float32List> inputs) {
    if (_disposed) throw StateError('$path: model already closed');
    if (inputs.length != inputNames.length) {
      throw ArgumentError(
        '$path takes ${inputNames.length} inputs, got ${inputs.length}',
      );
    }
    for (var i = 0; i < inputs.length; i++) {
      if (inputs[i].length != _inputLengths[i]) {
        throw ArgumentError(
          '$path input ${inputNames[i]} takes ${_inputLengths[i]} floats, '
          'got ${inputs[i].length}',
        );
      }
      _inputMemory[i]
          .cast<Float>()
          .asTypedList(_inputLengths[i])
          .setAll(0, inputs[i]);
    }
    _api.check(
      'LiteRtRunCompiledModel($path)',
      _api.runCompiledModel(
        _compiled,
        0,
        inputNames.length,
        _inputBuffers,
        outputNames.length,
        _outputBuffers,
      ),
    );
    return {
      for (var i = 0; i < outputNames.length; i++)
        outputNames[i]: Float32List.fromList(
          _outputMemory[i].cast<Float>().asTypedList(_outputLengths[i]),
        ),
    };
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    for (var i = 0; i < inputNames.length; i++) {
      _api.destroyTensorBuffer(_inputBuffers[i]);
    }
    for (var i = 0; i < outputNames.length; i++) {
      _api.destroyTensorBuffer(_outputBuffers[i]);
    }
    _api.destroyCompiledModel(_compiled);
    _api.destroyOptions(_options);
    _api.destroyModel(_model);
    for (final host in [..._inputMemory, ..._outputMemory]) {
      malloc.free(host);
    }
    calloc.free(_inputBuffers);
    calloc.free(_outputBuffers);
  }
}
