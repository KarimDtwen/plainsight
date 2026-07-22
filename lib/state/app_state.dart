import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_exception.dart';
import '../api/api_service.dart';
import '../models/models.dart';

/// App-wide state: auth token (persisted) + the registered sites list.
/// Hand-rolled ChangeNotifier + InheritedNotifier — same pattern as UniMatch,
/// no state-management package.
class AppState extends ChangeNotifier {
  static const _tokenPrefsKey = 'plainsight_token';
  final ApiService _api = ApiService();

  String? _token;
  bool _initializing = true;
  List<Site> _sites = [];
  bool _sitesLoading = false;
  String? _sitesError;

  bool get isLoggedIn => _token != null;
  bool get initializing => _initializing;
  List<Site> get sites => _sites;
  bool get sitesLoading => _sitesLoading;
  String? get sitesError => _sitesError;

  AppState() {
    unawaited(_restoreToken());
  }

  Future<void> _restoreToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_tokenPrefsKey);
      if (saved != null) {
        _token = saved;
        _api.token = saved;
      }
    } catch (_) {
      // No persisted session — fall through to the login screen.
    }
    _initializing = false;
    notifyListeners();
    if (isLoggedIn) unawaited(loadSites());
  }

  Future<void> login(String password) async {
    final token = await _api.login(password);
    _token = token;
    _api.token = token;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenPrefsKey, token);
    } catch (_) {}
    unawaited(loadSites());
  }

  Future<void> logout() async {
    _token = null;
    _api.token = null;
    _sites = [];
    _sitesError = null;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenPrefsKey);
    } catch (_) {}
  }

  Future<void> loadSites() async {
    _sitesLoading = true;
    _sitesError = null;
    notifyListeners();
    try {
      _sites = await _api.listSites();
    } on ApiException catch (e) {
      if (e.kind == ApiErrorKind.unauthorized) {
        await logout();
        return;
      }
      _sitesError = e.message;
    } finally {
      _sitesLoading = false;
      notifyListeners();
    }
  }

  Future<Site> createSite({required String name, required String domain}) async {
    final site = await _api.createSite(name: name, domain: domain);
    _sites = [..._sites, site];
    notifyListeners();
    return site;
  }

  Future<void> deleteSite(String id) async {
    await _api.deleteSite(id);
    _sites = _sites.where((s) => s.id != id).toList();
    notifyListeners();
  }
}

class AppStateProvider extends InheritedNotifier<AppState> {
  const AppStateProvider({
    super.key,
    required AppState state,
    required super.child,
  }) : super(notifier: state);

  static AppState of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<AppStateProvider>();
    assert(provider != null, 'No AppStateProvider found in context');
    return provider!.notifier!;
  }
}
