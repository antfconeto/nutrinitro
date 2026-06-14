import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

class DroneMapTiles {
  const DroneMapTiles._();

  static const userAgent = 'nutrinitro.com.nutrinitro';
  static const standardUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const satelliteUrl =
      'https://mt1.google.com/vt/lyrs=y&x={x}&y={y}&z={z}';

  /// Cada camada precisa do seu próprio provider — compartilhar um único
  /// [NetworkTileProvider] faz o dispose de um mapa (ex.: PiP) fechar o
  /// cliente HTTP e deixar os outros mapas em branco.
  static TileLayer layer({required bool isSatellite}) {
    return TileLayer(
      key: ValueKey(isSatellite ? 'satellite' : 'standard'),
      urlTemplate: isSatellite ? satelliteUrl : standardUrl,
      userAgentPackageName: userAgent,
      maxNativeZoom: isSatellite ? 20 : 19,
      tileProvider: NetworkTileProvider(
        cachingProvider: const DisabledMapCachingProvider(),
      ),
    );
  }
}
