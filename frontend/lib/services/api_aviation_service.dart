import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config.dart';

class ApiAviationService {
  static Future<List<dynamic>> getMetar(String station) async {
    final response = await http.get(Uri.parse('${Config.apiBaseUrl}/aviation/metar?station=$station'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load METAR for $station');
    }
  }

  static Future<List<dynamic>> getTaf(String station) async {
    final response = await http.get(Uri.parse('${Config.apiBaseUrl}/aviation/taf?station=$station'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load TAF for $station');
    }
  }
}
