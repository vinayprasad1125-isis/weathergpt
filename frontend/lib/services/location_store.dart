/// Simple global location store.
/// The Map screen writes to this whenever the user selects a state or uses "Locate Me".
/// The Chat screen reads from this to pass as the location context.
class LocationStore {
  static String? _currentCity;
  static double? _currentLat;
  static double? _currentLon;

  static void update({String? city, double? lat, double? lon}) {
    _currentCity = city;
    _currentLat = lat;
    _currentLon = lon;
  }

  static String? get currentCity => _currentCity;
  static double? get currentLat => _currentLat;
  static double? get currentLon => _currentLon;

  /// Returns the location payload for the chat API.
  /// If lat/lon are known, sends coordinates (most accurate).
  /// Otherwise falls back to city name string.
  static dynamic get chatLocationPayload {
    if (_currentLat != null && _currentLon != null) {
      return {'latitude': _currentLat, 'longitude': _currentLon};
    }
    if (_currentCity != null) return _currentCity;
    return null;
  }
}
