import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceService {
  final SpeechToText _speechToText = SpeechToText();
  bool _isInitialized = false;

  /// Inicializa el motor de voz.
  Future<bool> initVoice() async {
    if (_isInitialized) return true;
    
    try {
      _isInitialized = await _speechToText.initialize(
        onError: (val) => debugPrint('Error de voz: $val'),
        onStatus: (val) => debugPrint('Estado de voz: $val'),
      );
      return _isInitialized;
    } catch (e) {
      debugPrint('Error inicializando SpeechToText: $e');
      return false;
    }
  }

  /// Inicia la escucha. 
  /// [onResult] devuelve el texto mientras hablas.
  /// [onDone] es opcional y se ejecuta al terminar la frase final.
  Future<void> startListening({
    required Function(String) onResult,
    VoidCallback? onDone, // Ahora es opcional con el signo '?'
  }) async {
    if (!_isInitialized) {
      bool ok = await initVoice();
      if (!ok) return;
    }

    // Cancelamos cualquier escucha previa para evitar conflictos
    if (_speechToText.isListening) {
      await _speechToText.stop();
    }

    await _speechToText.listen(
      onResult: (SpeechRecognitionResult result) {
        onResult(result.recognizedWords);
        
        // Solo llamamos a onDone si el resultado es final y el callback existe
        if (result.finalResult && onDone != null) {
          onDone();
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 15),
      cancelOnError: true,
      partialResults: true,
      listenMode: ListenMode.dictation, // Optimizado para dictado de notas
    );
  }

  /// Detiene la escucha manualmente
  Future<void> stopListening() async {
    await _speechToText.stop();
  }

  /// Verifica si está escuchando actualmente
  bool get isListening => _speechToText.isListening;
}