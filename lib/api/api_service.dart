import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/models.dart';
import 'api_exception.dart';

/// Singleton HTTP client for the Plainsight backend.
///
/// Base URL comes from a build-time define so a single build works against
/// local/dev/prod without editing code:
///   flutter build web --dart-define=API_BASE_URL=https://plainsight-backend.onrender.com
class ApiService {
  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  static String get baseUrl => _baseUrl;

  static const Duration _requestTimeout = Duration(seconds: 15);
  // Render's free tier can take 30-60s to wake from sleep (see UniMatch's
  // ApiService — the same infra, the same trade-off).
  static const Duration _coldStartTimeout = Duration(seconds: 45);
  static const int _coldStartRetries = 2;

  /// True while a request is waiting on a likely cold start. The UI shows a
  /// "waking up the server" banner while this is true.
  static final ValueNotifier<bool> serverWaking = ValueNotifier<bool>(false);

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  /// Set by AppState after login / on load from persisted storage. Every
  /// authenticated request attaches it as `Authorization: Bearer <token>`.
  String? token;

  Map<String, String> get _authHeaders =>
      token == null ? {} : {'Authorization': 'Bearer $token'};

  // ── Auth ───────────────────────────────────────────────────────────────

  Future<String> login(String password) async {
    final response = await _send(() => http.post(
          Uri.parse('$_baseUrl/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'password': password}),
        ));
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body['token'] as String;
    }
    if (response.statusCode == 401) {
      throw const ApiException(ApiErrorKind.unauthorized, 'Wrong password.');
    }
    throw ApiException(
        ApiErrorKind.server, 'Login failed (${response.statusCode}).');
  }

  // ── Sites ──────────────────────────────────────────────────────────────

  Future<List<Site>> listSites() async {
    final response = await _send(() => http.get(
          Uri.parse('$_baseUrl/sites'),
          headers: _authHeaders,
        ));
    _throwIfUnauthorizedOrError(response);
    final list = jsonDecode(response.body) as List;
    return list
        .map((e) => Site.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Site> createSite({required String name, required String domain}) async {
    final response = await _send(() => http.post(
          Uri.parse('$_baseUrl/sites'),
          headers: {..._authHeaders, 'Content-Type': 'application/json'},
          body: jsonEncode({'name': name, 'domain': domain}),
        ));
    if (response.statusCode == 201) {
      return Site.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    _throwIfUnauthorizedOrError(response);
    throw ApiException(ApiErrorKind.server, 'Could not create the site.');
  }

  Future<void> deleteSite(String id) async {
    final response = await _send(() => http.delete(
          Uri.parse('$_baseUrl/sites/$id'),
          headers: _authHeaders,
        ));
    if (response.statusCode != 204) _throwIfUnauthorizedOrError(response);
  }

  /// (Re)generates the site's share link, revoking any previous one.
  Future<String?> createShareSlug(String siteId) async {
    final response = await _send(() => http.post(
          Uri.parse('$_baseUrl/sites/$siteId/share-slug'),
          headers: _authHeaders,
        ));
    _throwIfUnauthorizedOrError(response);
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['share_slug'] as String?;
  }

  Future<void> revokeShareSlug(String siteId) async {
    final response = await _send(() => http.delete(
          Uri.parse('$_baseUrl/sites/$siteId/share-slug'),
          headers: _authHeaders,
        ));
    if (response.statusCode != 204) _throwIfUnauthorizedOrError(response);
  }

  // ── Stats ──────────────────────────────────────────────────────────────

  Future<List<StatsPoint>> timeseries({
    required String siteId,
    required DateTime from,
    required DateTime to,
    required String bucket,
  }) async {
    final uri = Uri.parse('$_baseUrl/sites/$siteId/stats/timeseries').replace(
        queryParameters: {
          'from': _isoDate(from),
          'to': _isoDate(to),
          'bucket': bucket,
        });
    final response = await _send(() => http.get(uri, headers: _authHeaders));
    _throwIfUnauthorizedOrError(response);
    final list = jsonDecode(response.body) as List;
    return list
        .map((e) => StatsPoint.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<BreakdownRow>> breakdown({
    required String siteId,
    required BreakdownDimension dim,
    required DateTime from,
    required DateTime to,
    int limit = 8,
  }) async {
    final uri = Uri.parse('$_baseUrl/sites/$siteId/stats/breakdown').replace(
        queryParameters: {
          'dim': dim.apiValue,
          'from': _isoDate(from),
          'to': _isoDate(to),
          'limit': '$limit',
        });
    final response = await _send(() => http.get(uri, headers: _authHeaders));
    _throwIfUnauthorizedOrError(response);
    final list = jsonDecode(response.body) as List;
    return list
        .map((e) => BreakdownRow.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<StatsSummary> summary({
    required String siteId,
    required DateTime from,
    required DateTime to,
  }) async {
    final uri = Uri.parse('$_baseUrl/sites/$siteId/stats/summary').replace(
        queryParameters: {'from': _isoDate(from), 'to': _isoDate(to)});
    final response = await _send(() => http.get(uri, headers: _authHeaders));
    _throwIfUnauthorizedOrError(response);
    return StatsSummary.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<int> live(String siteId) async {
    final response = await _send(() => http.get(
          Uri.parse('$_baseUrl/sites/$siteId/stats/live'),
          headers: _authHeaders,
        ));
    _throwIfUnauthorizedOrError(response);
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return (body['online'] as num).toInt();
  }

  // ── Public (share link — no auth) ─────────────────────────────────────

  Future<PublicSite> publicSite(String slug) async {
    final response = await _send(() => http.get(Uri.parse('$_baseUrl/public/$slug/site')));
    _throwIfNotFoundOrError(response);
    return PublicSite.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<StatsSummary> publicSummary({
    required String slug,
    required DateTime from,
    required DateTime to,
  }) async {
    final uri = Uri.parse('$_baseUrl/public/$slug/stats/summary')
        .replace(queryParameters: {'from': _isoDate(from), 'to': _isoDate(to)});
    final response = await _send(() => http.get(uri));
    _throwIfNotFoundOrError(response);
    return StatsSummary.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<List<StatsPoint>> publicTimeseries({
    required String slug,
    required DateTime from,
    required DateTime to,
    required String bucket,
  }) async {
    final uri = Uri.parse('$_baseUrl/public/$slug/stats/timeseries').replace(
        queryParameters: {'from': _isoDate(from), 'to': _isoDate(to), 'bucket': bucket});
    final response = await _send(() => http.get(uri));
    _throwIfNotFoundOrError(response);
    final list = jsonDecode(response.body) as List;
    return list.map((e) => StatsPoint.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<BreakdownRow>> publicBreakdown({
    required String slug,
    required BreakdownDimension dim,
    required DateTime from,
    required DateTime to,
    int limit = 8,
  }) async {
    final uri = Uri.parse('$_baseUrl/public/$slug/stats/breakdown').replace(queryParameters: {
      'dim': dim.apiValue,
      'from': _isoDate(from),
      'to': _isoDate(to),
      'limit': '$limit',
    });
    final response = await _send(() => http.get(uri));
    _throwIfNotFoundOrError(response);
    final list = jsonDecode(response.body) as List;
    return list.map((e) => BreakdownRow.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<int> publicLive(String slug) async {
    final response = await _send(() => http.get(Uri.parse('$_baseUrl/public/$slug/stats/live')));
    _throwIfNotFoundOrError(response);
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return (body['online'] as num).toInt();
  }

  // ── Internals ──────────────────────────────────────────────────────────

  String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _throwIfUnauthorizedOrError(http.Response response) {
    if (response.statusCode == 401) {
      throw const ApiException(
          ApiErrorKind.unauthorized, 'Session expired — please log in again.');
    }
    if (response.statusCode >= 400) {
      throw ApiException(
          ApiErrorKind.server, 'Request failed (${response.statusCode}).');
    }
  }

  void _throwIfNotFoundOrError(http.Response response) {
    if (response.statusCode == 404) {
      throw const ApiException(
          ApiErrorKind.notFound, 'This share link is no longer active.');
    }
    if (response.statusCode >= 400) {
      throw ApiException(
          ApiErrorKind.server, 'Request failed (${response.statusCode}).');
    }
  }

  /// Runs [attempt] with the normal timeout; on timeout, retries a couple of
  /// times with a longer cold-start timeout while [serverWaking] is true so
  /// the UI can show a "waking up" banner (same trade-off as UniMatch).
  Future<http.Response> _send(
    Future<http.Response> Function() attempt,
  ) async {
    try {
      return await attempt().timeout(_requestTimeout);
    } on TimeoutException {
      serverWaking.value = true;
      try {
        for (var i = 0; i < _coldStartRetries; i++) {
          try {
            return await attempt().timeout(_coldStartTimeout);
          } on TimeoutException {
            continue;
          }
        }
        throw const ApiException(
            ApiErrorKind.timeout, 'The server is taking too long to respond.');
      } finally {
        serverWaking.value = false;
      }
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
          ApiErrorKind.offline, 'Could not reach the server.');
    }
  }
}
