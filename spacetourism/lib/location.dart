import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LocationSearch {
  static final String _nominatimUrl = 'https://nominatim.openstreetmap.org/search';
  
  static Future<List<LocationResult>> search(String query, {int limit = 5}) async {
    try {
      final response = await http.get(
        Uri.parse('$_nominatimUrl?format=json&q=$query&limit=$limit&addressdetails=1'),
        headers: {'User-Agent': 'YourAppName/1.0'}, // Wymagane przez Nominatim
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => LocationResult.fromJson(item)).toList();
      } else {
        throw Exception('Błąd wyszukiwania: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Błąd połączenia: $e');
    }
  }
}

class LocationResult {
  final String displayName;
  final double lat;
  final double lon;
  final String type;
  final Map<String, dynamic>? addressDetails;
  
  LocationResult({
    required this.displayName,
    required this.lat,
    required this.lon,
    required this.type,
    this.addressDetails,
  });
  
  factory LocationResult.fromJson(Map<String, dynamic> json) {
    return LocationResult(
      displayName: json['display_name'],
      lat: double.parse(json['lat']),
      lon: double.parse(json['lon']),
      type: json['type'],
      addressDetails: json['address'],
    );
  }
  
  LatLng get latLng => LatLng(lat, lon);
  
  @override
  String toString() => displayName;
}