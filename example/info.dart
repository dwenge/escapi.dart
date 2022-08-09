import 'package:escapi/escapi.dart';

void main() {
  final ep = Escapi(libpath: 'libraries/escapi.dll');
  final device = ep.initCapture(320, 240, deviceIndex: 0);

  print('countCaptureDevices: ${ep.countCaptureDevices()}');
  print('getCaptureDeviceName: ${ep.getCaptureDeviceName(0)}');

  final device5 = ep.initCapture(5, 5, deviceIndex: 5);
  if (device5 == null) {
    print('getCaptureErrorLine: ${ep.getCaptureErrorLine(5)}');
    print('getCaptureErrorCode: ${ep.getCaptureErrorCode(5)}');
  }

  print('device.getName: ${device?.getName()}');
  print('device.getErrorLine: ${device?.getErrorLine()}');
  print('device.getErrorCode: ${device?.getErrorCode()}');

  for (var prop in CaptureProperties.values) {
    print('device.getPropertyValue(${prop.name}):'
        '${device?.getPropertyValue(prop)}');
  }
}
