// lib/services/audio_recorder_service.dart - VERSIÓN CORREGIDA
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:libre_mercado_final__app/utils/logger.dart';

class AudioRecorderService with ChangeNotifier {
  bool _isRecording = false;
  String? _currentRecordingPath;
  Duration _recordingDuration = Duration.zero;

  bool get isRecording => _isRecording;
  String? get currentRecordingPath => _currentRecordingPath;
  Duration get recordingDuration => _recordingDuration;

  // Verificar permisos de micrófono
  Future<bool> checkMicrophonePermission() async {
    final status = await Permission.microphone.request();
    if (status.isGranted) {
      AppLogger.d('🎤 Permiso de micrófono concedido');
      return true;
    } else {
      AppLogger.e('❌ Permiso de micrófono denegado');
      return false;
    }
  }

  // Iniciar grabación (versión simulada - implementar con librería real)
  Future<bool> startRecording() async {
    try {
      if (!await checkMicrophonePermission()) {
        return false;
      }

      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = '${directory.path}/audio_$timestamp.m4a';

      // Simular inicio de grabación (reemplazar con implementación real)
      _isRecording = true;
      _recordingDuration = Duration.zero;
      
      // Actualizar duración cada segundo
      _startDurationTimer();
      
      notifyListeners();
      AppLogger.d('🎤 Grabación iniciada: $_currentRecordingPath');
      return true;
    } catch (e) {
      AppLogger.e('❌ Error iniciando grabación', e);
      _isRecording = false;
      _currentRecordingPath = null;
      notifyListeners();
      return false;
    }
  }

  // Detener grabación (versión simulada)
  Future<String?> stopRecording() async {
    try {
      _stopDurationTimer();
      
      // Simular archivo de audio creado (reemplazar con implementación real)
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final audioPath = '${directory.path}/audio_$timestamp.m4a';
      
      // Crear archivo vacío de ejemplo
      final audioFile = File(audioPath);
      await audioFile.writeAsBytes([]);
      
      _isRecording = false;
      
      AppLogger.d('⏹️ Grabación detenida. Duración: $_recordingDuration');
      notifyListeners();
      
      return audioPath;
    } catch (e) {
      AppLogger.e('❌ Error deteniendo grabación', e);
      _isRecording = false;
      notifyListeners();
      return null;
    }
  }

  // Cancelar grabación
  Future<void> cancelRecording() async {
    try {
      _stopDurationTimer();
      
      if (_currentRecordingPath != null && await File(_currentRecordingPath!).exists()) {
        await File(_currentRecordingPath!).delete();
      }
      _isRecording = false;
      _currentRecordingPath = null;
      _recordingDuration = Duration.zero;
      
      AppLogger.d('❌ Grabación cancelada');
      notifyListeners();
    } catch (e) {
      AppLogger.e('❌ Error cancelando grabación', e);
    }
  }

  // Timer para duración
  Timer? _durationTimer;
  
  void _startDurationTimer() {
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _recordingDuration += const Duration(seconds: 1);
      notifyListeners();
    });
  }

  void _stopDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = null;
  }

  // Liberar recursos
  // ignore: must_call_super
  Future<void> dispose() async {
    _stopDurationTimer();
    _isRecording = false;
    _currentRecordingPath = null;
    _recordingDuration = Duration.zero;
  }

  // Formatear duración para mostrar
  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    
    if (duration.inHours > 0) {
      return '$hours:$minutes:$seconds';
    } else {
      return '$minutes:$seconds';
    }
  }

  // Método para verificar si hay una grabación en curso
  bool get hasActiveRecording => _isRecording;

  // Método para obtener el path temporal del archivo de audio
  Future<String> getTemporaryAudioPath() async {
    final directory = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${directory.path}/audio_$timestamp.m4a';
  }
}