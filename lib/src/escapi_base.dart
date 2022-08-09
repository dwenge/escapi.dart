import 'dart:ffi' as ffi;
import 'dart:typed_data';
import 'package:ffi/ffi.dart' as pffi;

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
    final f = _lib!.lookupFunction<
        ffi.Int Function(ffi.UnsignedInt, ffi.Pointer<_FfiEscapiParams>),
        int Function(int, ffi.Pointer<_FfiEscapiParams>)>('initCapture');
    if (f(deviceIndex, params.p) > 0) {
      return Device(deviceIndex, params, this);
    }
    return null;
  }

  void doCapture(int deviceIndex) => _lib!
      .lookupFunction<ffi.Void Function(ffi.UnsignedInt), void Function(int)>(
          'doCapture')(deviceIndex);

  int isCaptureDone(int deviceIndex) => _lib!
      .lookupFunction<ffi.Int Function(ffi.UnsignedInt), int Function(int)>(
          'isCaptureDone')(deviceIndex);

  void deinitCapture(int deviceIndex) => _lib!
      .lookupFunction<ffi.Void Function(ffi.UnsignedInt), void Function(int)>(
          'deinitCapture')(deviceIndex);

  int countCaptureDevices() =>
      _lib!.lookupFunction<ffi.Int Function(), int Function()>(
          'countCaptureDevices')();

  int getVersion({EscapiVersionType type = EscapiVersionType.library}) {
    switch (type) {
      case EscapiVersionType.dll:
        return _getDllVersion();
      default:
        return _getVersion();
    }
  }

  int _getDllVersion() => _lib!
      .lookupFunction<ffi.Int Function(), int Function()>('ESCAPIDLLVersion')();

  int _getVersion() => _lib!
      .lookupFunction<ffi.Int Function(), int Function()>('ESCAPIVersion')();

  String getCaptureDeviceName(int deviceIndex, {int len = 256}) {
    final f = _lib!.lookupFunction<
        ffi.Void Function(ffi.UnsignedInt, ffi.Pointer<pffi.Utf8>, ffi.Int),
        void Function(
            int, ffi.Pointer<pffi.Utf8>, int)>('getCaptureDeviceName');

    final ffi.Pointer<pffi.Utf8> _buf =
        pffi.calloc.allocate<pffi.Utf8>(ffi.sizeOf<ffi.Uint8>() * len);

    f(deviceIndex, _buf, len);

    final name = _buf.toDartString(length: len);
    pffi.calloc.free(_buf);
    return name;
  }

  int getCaptureErrorLine(int deviceIndex) => _lib!
      .lookupFunction<ffi.Int Function(ffi.UnsignedInt), int Function(int)>(
          'getCaptureErrorLine')(deviceIndex);

  int getCaptureErrorCode(int deviceIndex) => _lib!
      .lookupFunction<ffi.Int Function(ffi.UnsignedInt), int Function(int)>(
          'getCaptureErrorCode')(deviceIndex);
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

  String getName({int len = 256}) =>
      escapi.getCaptureDeviceName(index, len: len);

  int getErrorLine() => escapi.getCaptureErrorLine(index);

  int getErrorCode() => escapi.getCaptureErrorCode(index);

  void free() {
    escapi.deinitCapture(index);
    params.free();
  }

  @override
  String toString() {
    return "Device{ index: $index, params: $params }";
  }
}
