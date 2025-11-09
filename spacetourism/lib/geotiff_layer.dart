import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart';


class GeoTiffLayer {
  bool isVisible = false;
  List<OverlayImage>? overlayImages;
  LatLngBounds? bounds;
  GeoTiffLayer() {
    _initializeGeoTiff();
  }
  String raster = 'assets/snow_2024comp.tif';

  Future<void> _initializeGeoTiff() async {
    try {
      // Wczytaj plik GeoTIFF z assets
      final ByteData data = await rootBundle.load(raster);
      final Uint8List bytes = data.buffer.asUint8List();
      
      // Tutaj powinna być prawdziwa implementacja parsowania GeoTIFF
      // Na potrzeby demonstracji używamy przykładowych danych
      _setupDemoData();
      
    } catch (e) {
      print('Błąd ładowania GeoTIFF: $e');
      _setupDemoData();
    }
  }

  void _setupDemoData() {
    // Przykładowy obszar w Warszawie dla demonstracji
    bounds = LatLngBounds(
      const LatLng(49.652644, 19.641546),
      const LatLng(48.657021, 21.135214),
    );
    
    // Dla demonstracji używamy kolorowego prostokąta
    // W rzeczywistej aplikacji tutaj powinny być dane z GeoTIFF
    overlayImages = [
      OverlayImage(
        bounds: bounds!,
        opacity: 0.8,
        imageProvider: const AssetImage('assets/snow_2024comp.tif'),
      ),
    ];
  }

  void toggleVisibility() {
    isVisible = !isVisible;
  }

  Widget buildLayer() {
    if (!isVisible || overlayImages == null) {
      return Container(); // Pusty widget gdy warstwa jest niewidoczna
    }
    
    return OverlayImageLayer(
      overlayImages: overlayImages!,
    );
  }
}
