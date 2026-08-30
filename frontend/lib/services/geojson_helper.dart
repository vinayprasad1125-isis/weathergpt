import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

/// Maps our UI state names to their exact GeoJSON NAME_1 equivalents
const Map<String, String> _geoJsonNameMap = {
  'Odisha': 'Orissa',
  'Uttarakhand': 'Uttaranchal',
  'Telangana': 'Andhra Pradesh', // Telangana was carved from AP; fall back to AP
};

class GeoJsonHelper {
  static String? _cachedJson;

  static Future<List<List<LatLng>>> getPolygonsForState(String stateName) async {
    try {
      // Cache the geojson string so we only load it from assets once
      _cachedJson ??= await rootBundle.loadString('assets/india_states.geojson');
      
      // Use the alias if one exists
      final geoJsonName = _geoJsonNameMap[stateName] ?? stateName;

      // Parse synchronously — compute() doesn't work on Flutter Web
      final polygons = _parseGeoJson(_cachedJson!, geoJsonName);
      debugPrint('[GeoJsonHelper] "$stateName" → "$geoJsonName": ${polygons.length} polygon rings found');
      return polygons;
    } catch (e) {
      debugPrint('[GeoJsonHelper] Error loading geojson: $e');
      return [];
    }
  }

  static List<List<LatLng>> _parseGeoJson(String geojsonStr, String targetName) {
    final geojson = jsonDecode(geojsonStr);
    final target = targetName.toLowerCase().trim();
    List<List<LatLng>> polygons = [];

    final features = geojson['features'] as List;
    for (final feature in features) {
      final props = feature['properties'];
      final name1 = (props['NAME_1'] as String? ?? '').toLowerCase().trim();

      // Match on exact name or if one contains the other
      if (name1 != target && !name1.contains(target) && !target.contains(name1)) {
        continue;
      }

      final geom = feature['geometry'];
      final type = geom['type'] as String;
      final coordinates = geom['coordinates'] as List;

      if (type == 'Polygon') {
        // coordinates: [ [outer ring], [inner holes]... ] — only take outer ring
        polygons.add(_parseRing(coordinates[0] as List));
      } else if (type == 'MultiPolygon') {
        // coordinates: [ [ [outer ring], ...], ... ]
        for (final polygon in coordinates) {
          polygons.add(_parseRing((polygon as List)[0] as List));
        }
      }
    }

    return polygons;
  }

  static List<LatLng> _parseRing(List ring) {
    return ring.map<LatLng>((pt) {
      // GeoJSON is [longitude, latitude]
      return LatLng((pt[1] as num).toDouble(), (pt[0] as num).toDouble());
    }).toList();
  }
}
