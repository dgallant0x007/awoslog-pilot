class Port {
  final String id;
  final String city;
  final String state;
  final double lat;
  final double lon;
  final int elevation;
  final String link;
  final bool community;

  const Port({
    required this.id,
    required this.city,
    required this.state,
    required this.lat,
    required this.lon,
    required this.elevation,
    required this.link,
    required this.community,
  });

  factory Port.fromJson(Map<String, dynamic> json) {
    return Port(
      id: json['id'] as String? ?? '',
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lon: (json['lon'] as num?)?.toDouble() ?? 0.0,
      elevation: json['elevation'] as int? ?? 0,
      link: json['link'] as String? ?? '',
      community: json['community'] as bool? ?? false,
    );
  }
}

class LatestMetar {
  final String station;
  final int ceiling;
  final double visibility;
  final int windSpeed;
  final int windGust;
  final int windAngle;
  final int tempC;
  final double barometer;
  final String wx;

  const LatestMetar({
    required this.station,
    required this.ceiling,
    required this.visibility,
    required this.windSpeed,
    required this.windGust,
    required this.windAngle,
    required this.tempC,
    required this.barometer,
    required this.wx,
  });

  factory LatestMetar.fromJson(Map<String, dynamic> json) {
    return LatestMetar(
      station: json['station'] as String? ?? '',
      ceiling: json['ceiling'] as int? ?? 0,
      visibility: (json['visibility'] as num?)?.toDouble() ?? 0.0,
      windSpeed: json['wind_speed'] as int? ?? 0,
      windGust: json['wind_gust'] as int? ?? 0,
      windAngle: json['wind_angle'] as int? ?? 0,
      tempC: json['temp_c'] as int? ?? 0,
      barometer: (json['barometer'] as num?)?.toDouble() ?? 0.0,
      wx: json['wx'] as String? ?? '',
    );
  }
}

class Station {
  final String id;
  final String city;
  final String state;
  final double lat;
  final double lon;
  final int elevation;
  final bool community;
  final double distanceNm;
  final int ceiling;
  final double visibility;
  final int windSpeed;
  final int windGust;
  final int windAngle;
  final int tempC;
  final double barometer;
  final String wx;
  final int densityAltitude;

  const Station({
    required this.id,
    required this.city,
    required this.state,
    required this.lat,
    required this.lon,
    required this.elevation,
    required this.community,
    required this.distanceNm,
    required this.ceiling,
    required this.visibility,
    required this.windSpeed,
    required this.windGust,
    required this.windAngle,
    required this.tempC,
    required this.barometer,
    required this.wx,
    required this.densityAltitude,
  });

  factory Station.fromPortAndMetar(Port port, LatestMetar metar) {
    return Station(
      id: port.id,
      city: port.city,
      state: port.state,
      lat: port.lat,
      lon: port.lon,
      elevation: port.elevation,
      community: port.community,
      distanceNm: 0.0,
      ceiling: metar.ceiling,
      visibility: metar.visibility,
      windSpeed: metar.windSpeed,
      windGust: metar.windGust,
      windAngle: metar.windAngle,
      tempC: metar.tempC,
      barometer: metar.barometer,
      wx: metar.wx,
      densityAltitude: 0,
    );
  }

  String get windDisplay {
    if (windSpeed == 0) return 'calm';
    final dir = (windAngle == 0 ? 360 : windAngle).toString().padLeft(3, '0');
    final base = '$dir@$windSpeed';
    if (windGust > 0) return '${base}G$windGust';
    return base;
  }

  Station copyWith({double? distanceNm, int? densityAltitude}) {
    return Station(
      id: id, city: city, state: state, lat: lat, lon: lon,
      elevation: elevation, community: community,
      distanceNm: distanceNm ?? this.distanceNm,
      ceiling: ceiling, visibility: visibility,
      windSpeed: windSpeed, windGust: windGust, windAngle: windAngle,
      tempC: tempC, barometer: barometer, wx: wx,
      densityAltitude: densityAltitude ?? this.densityAltitude,
    );
  }
}
