import 'dart:ffi' as ffi;
import 'dart:typed_data';
import 'package:ffi/ffi.dart' as pffi;

typedef _ffi_get_version_func = ffi.Int Function();
typedef _dart_get_version_func = int Function();

typedef _ffi_count_capture_devices = ffi.Int Function();
typedef _dart_count_capture_devices = int Function();

typedef _ffi_init_capture = ffi.Int Function(
    ffi.UnsignedInt, ffi.Pointer<_FfiEscapiParams>);
typedef _dart_init_capture = int Function(int, ffi.Pointer<_FfiEscapiParams>);

typedef _ffi_deinit_capture = ffi.Void Function(ffi.UnsignedInt);
typedef _dart_deinit_capture = void Function(int);

typedef _ffi_do_capture = ffi.Void Function(ffi.UnsignedInt);
typedef _dart_do_capture = void Function(int);

typedef _ffi_is_capture_done = ffi.Int Function(ffi.UnsignedInt);
typedef _dart_is_capture_done = int Function(int);

enum EscapiVersionType {
  dll,
  library,
}

class _FfiEscapiParams extends ffi.Struct {
  external ffi.Pointer<ffi.Uint8> buf;
  @ffi.UnsignedInt()
  external int w;
  @ffi.UnsignedInt()
  external int h;
}

class EscapiParams {
  final int bufferLength;
  final int width;
  final int height;
  final ffi.Pointer<_FfiEscapiParams> p;

  EscapiParams(this.width, this.height)
      : bufferLength = width * height * 4,
        p = pffi.calloc
            .allocate<_FfiEscapiParams>(ffi.sizeOf<_FfiEscapiParams>()) {
    p.ref.w = width;
    p.ref.h = height;
    p.ref.buf = pffi.calloc.allocate(bufferLength * ffi.sizeOf<ffi.Uint8>());
  }

  void free() {
    pffi.calloc.free(p.ref.buf);
    pffi.calloc.free(p);
  }

  @override
  String toString() {
    return "EscapiParams{ width: $width, height: $height, bufferLength: $bufferLength, p: $p }";
  }
}

class Escapi {
  static ffi.DynamicLibrary? _lib;
  Escapi({String libpath = 'escapi.dll'}) {
    _lib ??= ffi.DynamicLibrary.open(libpath);
  }

  Device? initCapture(int width, int height, {int deviceIndex = 0}) {
    final params = EscapiParams(width, height);
    final f = _lib!
        .lookupFunction<_ffi_init_capture, _dart_init_capture>('initCapture');
    if (f(deviceIndex, params.p) > 0) {
      return Device(deviceIndex, params, this);
    }
    return null;
  }

  void doCapture(int deviceIndex) {
    final f =
        _lib!.lookupFunction<_ffi_do_capture, _dart_do_capture>('doCapture');
    f(deviceIndex);
  }

  int isCaptureDone(int deviceIndex) {
    final f = _lib!.lookupFunction<_ffi_is_capture_done, _dart_is_capture_done>(
        'isCaptureDone');
    return f(deviceIndex);
  }

  void deinitCapture(int deviceIndex) {
    final f = _lib!.lookupFunction<_ffi_deinit_capture, _dart_deinit_capture>(
        'deinitCapture');
    f(deviceIndex);
  }

  int countCaptureDevices() {
    return _lib!.lookupFunction<_ffi_count_capture_devices,
        _dart_count_capture_devices>('countCaptureDevices')();
  }

  int getVersion({EscapiVersionType type = EscapiVersionType.library}) {
    switch (type) {
      case EscapiVersionType.dll:
        return _getDllVersion();
      default:
        return _getVersion();
    }
  }

  int _getDllVersion() {
    return _lib!.lookupFunction<_ffi_get_version_func, _dart_get_version_func>(
        'ESCAPIDLLVersion')();
  }

  int _getVersion() {
    return _lib!.lookupFunction<_ffi_get_version_func, _dart_get_version_func>(
        'ESCAPIVersion')();
  }
}

class Device {
  final int index;
  final EscapiParams params;
  final Escapi escapi;

  Device(this.index, this.params, this.escapi);

  Uint8List capture() {
    escapi.doCapture(index);
    while (escapi.isCaptureDone(index) == 0) {}
    var buf = Uint8List(params.bufferLength);
    for (var i = 0; i < params.bufferLength; i++) {
      buf[i] = params.p.ref.buf.elementAt(i).value;
    }
    return buf;
  }

  void free() {
    escapi.deinitCapture(index);
    params.free();
  }

  @override
  String toString() {
    return "Device{ index: $index, params: $params }";
  }
}
