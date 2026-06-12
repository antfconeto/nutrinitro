import 'dart:convert';
import 'dart:io';

class ImageAngleExtractor {
  final Map<String, double?> _cache = {};

  double? extract(String path) {
    if (_cache.containsKey(path)) {
      return _cache[path];
    }
    try {
      final file = File(path);
      if (!file.existsSync()) {
        _cache[path] = null;
        return null;
      }

      final accessor = file.openSync();
      final bytes = accessor.readSync(256 * 1024);
      accessor.closeSync();

      final content = latin1.decode(bytes, allowInvalid: true);

      final gimbalYawReg = RegExp(r'GimbalYawDegree="?([^"\s>]+)"?');
      final flightYawReg = RegExp(r'FlightYawDegree="?([^"\s>]+)"?');
      final gimbalYawTagReg = RegExp(
        r'<[^:>]+:GimbalYawDegree>([^<]+)</[^:>]+:GimbalYawDegree>',
      );
      final flightYawTagReg = RegExp(
        r'<[^:>]+:FlightYawDegree>([^<]+)</[^:>]+:FlightYawDegree>',
      );

      String? gimbalYawStr;
      var match = gimbalYawReg.firstMatch(content);
      if (match != null) {
        gimbalYawStr = match.group(1);
      } else {
        match = gimbalYawTagReg.firstMatch(content);
        if (match != null) gimbalYawStr = match.group(1);
      }

      String? flightYawStr;
      match = flightYawReg.firstMatch(content);
      if (match != null) {
        flightYawStr = match.group(1);
      } else {
        match = flightYawTagReg.firstMatch(content);
        if (match != null) flightYawStr = match.group(1);
      }

      final yawStr = gimbalYawStr ?? flightYawStr;
      if (yawStr != null) {
        final parsed = double.tryParse(yawStr);
        _cache[path] = parsed;
        return parsed;
      }
    } catch (_) {}
    _cache[path] = null;
    return null;
  }
}
