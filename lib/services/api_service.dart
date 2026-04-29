import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/aircraft.dart';
import '../models/station.dart';

class ApiService {
  final String baseUrl;
  final http.Client client;

  ApiService({required this.baseUrl, http.Client? client})
      : client = client ?? http.Client();

  Map<String, String> get _headers => {
    'X-API-Key': Config.apiKey,
  };

  Future<List<Port>> fetchPorts() async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/api/v1/stations'),
        headers: _headers,
      );
      if (response.statusCode != 200) return [];
      final List<dynamic> json = jsonDecode(response.body);
      return json.map((j) => Port.fromJson(j)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<LatestMetar>> fetchLatest() async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/api/v1/weather'),
        headers: _headers,
      );
      if (response.statusCode != 200) return [];
      final List<dynamic> json = jsonDecode(response.body);
      return json.map((j) => LatestMetar.fromJson(j)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Aircraft>> fetchAircraft(double lat, double lon, double radiusNm) async {
    try {
      final uri = Uri.parse('$baseUrl/api/aircraft').replace(
        queryParameters: {
          'lat': lat.toStringAsFixed(1),
          'lon': lon.toStringAsFixed(1),
          'radius': radiusNm.toStringAsFixed(0),
        },
      );
      final response = await client.get(uri);
      if (response.statusCode != 200) return [];
      final List<dynamic> json = jsonDecode(response.body);
      return json.map((j) => Aircraft.fromJson(j)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Aircraft>> fetchStratuxAircraft() async {
    try {
      final response = await client.get(Uri.parse('$baseUrl/api/stratux/aircraft'));
      if (response.statusCode != 200) return [];
      final Map<String, dynamic> json = jsonDecode(response.body);
      final List<dynamic> list = (json['aircraft'] as List<dynamic>?) ?? [];
      return list.map((j) => Aircraft.fromJson(j)).toList();
    } catch (_) {
      return [];
    }
  }
}
