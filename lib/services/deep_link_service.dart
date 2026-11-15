import 'package:flutter/foundation.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';

typedef DeepLinkCallback = Future<void> Function(String route);

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  
  factory DeepLinkService() {
    return _instance;
  }
  
  DeepLinkService._internal();

  final _appLinks = AppLinks();
  StreamSubscription<String>? _deepLinkSubscription;
  DeepLinkCallback? _callback;

  Future<void> initialize(DeepLinkCallback callback) async {
    _callback = callback;
    
    try {
      // Verificar deep link inicial si la app fue abierta desde un link
      final initialLink = await _appLinks.getInitialLinkString();
      if (initialLink != null) {
        debugPrint('🔗 Deep link inicial: $initialLink');
        final route = _parseRoute(initialLink);
        await callback(route);
      }
    } catch (e) {
      debugPrint('Error obteniendo deep link inicial: $e');
    }
    
    // Escuchar deep links mientras la app está activa
    _deepLinkSubscription = _appLinks.stringLinkStream.listen(
      (String link) {
        if (link.isNotEmpty) {
          debugPrint('🔗 Deep link recibido: $link');
          final route = _parseRoute(link);
          callback(route);
        }
      },
      onError: (err) {
        debugPrint('Error en deep link stream: $err');
      },
    );
  }

  String _parseRoute(String link) {
    try {
      // Ejemplo: booktracker://finish_session -> /finish_session
      // Ejemplo: booktracker://home -> /home
      final uri = Uri.parse(link);
      if (uri.scheme == 'booktracker') {
        return '/${uri.host}${uri.path}';
      }
    } catch (e) {
      debugPrint('Error parseando route de deep link: $e');
    }
    return '/home';
  }

  void dispose() {
    _deepLinkSubscription?.cancel();
  }
}
