/// dart run example/take_picture.dart

import 'dart:io';
import 'dart:typed_data';

import 'package:escapi/escapi.dart';

void main() {
  assert(stdout.supportsAnsiEscapes);

  final size = _getTreminalSize();
  print('size: $size');

  final escapi = Escapi(libpath: './libraries/escapi.dll');
  final device = escapi.initCapture(size[0], size[1]);

  print('start');
  if (device != null) {
    final data = device.capture();
    device.free();

    _drawConsole(data, size[0]);
  }
  print('end');
}

List<int> _getTreminalSize() {
  // Git-Bash: StdoutException: Could not get terminal size
  try {
    return [
      stdout.terminalColumns,
      stdout.terminalLines,
    ];
  } catch (_) {
    return [50, 25];
  }
}

int _getLuminanceRgb(int r, int g, int b) =>
    (0.299 * r + 0.587 * g + 0.114 * b).round();

String _getASCII(int c, String cont) => '\x1b[48;5;${c}m$cont';

void _drawConsole(Uint8List data, int w) {
  print('draw');
  int lastColor = 0;
  final count = data.length ~/ 4;
  final List<String> out = List.filled(count, ' ');
  for (var i = 0; i < count; i++) {
    final color = _getLuminanceRgb(
              data[i * 4 + 2],
              data[i * 4 + 1],
              data[i * 4],
            ) ~/
            24 +
        232;

    if (lastColor != color) {
      out[i] = _getASCII(color, ' ');
      lastColor = color;
    }
    if (i % w == 0) out[i] = '${out[i]}\n';
  }
  stdout.write(out.join());
  stdout.write(_getASCII(0, ' '));
}
