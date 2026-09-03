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
  static Map<String, List<List<LatLng>>>? _cachedAllStates;

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

  static Future<Map<String, List<List<LatLng>>>> getAllStatePolygons() async {
    try {
      if (_cachedAllStates != null) return _cachedAllStates!;

      _cachedJson ??= await rootBundle.loadString('assets/india_states.geojson');
      
      // We parse the entire file once and group by state name
      final Map<String, List<List<LatLng>>> allPolygons = {};
      
      final geojson = jsonDecode(_cachedJson!);
      final features = geojson['features'] as List;
      
      for (final feature in features) {
        final props = feature['properties'];
        final rawName = (props['NAME_1'] as String? ?? '').trim();
        if (rawName.isEmpty) continue;
        
        // Reverse lookup alias (e.g. if NAME_1 is 'Orissa', we want to store it as 'Odisha' for UI)
        String uiName = rawName;
        for (var entry in _geoJsonNameMap.entries) {
          if (entry.value.toLowerCase() == rawName.toLowerCase()) {
            uiName = entry.key;
            break;
          }
        }
        
        final geom = feature['geometry'];
        final type = geom['type'] as String;
        final coordinates = geom['coordinates'] as List;
        
        allPolygons.putIfAbsent(uiName, () => []);
        
        if (type == 'Polygon') {
          allPolygons[uiName]!.add(_parseRing(coordinates[0] as List));
        } else if (type == 'MultiPolygon') {
          for (final polygon in coordinates) {
            allPolygons[uiName]!.add(_parseRing((polygon as List)[0] as List));
          }
        }
      }
      
      _cachedAllStates = allPolygons;
      return allPolygons;
    } catch (e) {
      debugPrint('[GeoJsonHelper] Error loading all states geojson: $e');
      return {};
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
