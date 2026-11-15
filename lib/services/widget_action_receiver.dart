import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

typedef WidgetActionCallback = Future<void> Function(String action);

class WidgetActionReceiver {
  static final WidgetActionReceiver _instance = WidgetActionReceiver._internal();
  
  factory WidgetActionReceiver() {
    return _instance;
  }
  
  WidgetActionReceiver._internal();

  static const platform = MethodChannel('com.jabc.booktracker/widget');
  WidgetActionCallback? _callback;
  bool _isListening = false;

  Future<void> initialize(WidgetActionCallback callback) async {
    if (_isListening) return;
    
    _callback = callback;
    _isListening = true;
    
    try {
      // Escuchar los broadcasts del widget
      platform.setMethodCallHandler(_handleMethodCall);
      debugPrint('✓ Widget Action Receiver inicializado');
    } catch (e) {
      debugPrint('❌ Error inicializando Widget Action Receiver: $e');
      _isListening = false;
    }
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    try {
      switch (call.method) {
        case 'onWidgetAction':
          final action = call.arguments as String?;
          if (action != null && _callback != null) {
            debugPrint('🔔 Widget action recibida: $action');
            await _callback!(action);
          }
          break;
        default:
          debugPrint('Método desconocido: ${call.method}');
      }
    } catch (e) {
      debugPrint('Error manejando widget action: $e');
    }
  }

  void dispose() {
    _isListening = false;
    _callback = null;
  }
}
