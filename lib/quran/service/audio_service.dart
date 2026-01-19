// quran/service/audio_service.dart - FINAL FIX
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class QuranAudioService {
  static final QuranAudioService _instance = QuranAudioService._internal();
  factory QuranAudioService() => _instance;
  
  QuranAudioService._internal();

  AudioPlayer? _audioPlayer;
  String? _currentPlayingKey;
  bool _isPlaying = false;
  bool _isDisposed = false;
  StreamController<PlayerState>? _stateController;
  StreamSubscription<PlayerState>? _playerStateSubscription;

  // HANYA 1 QARI - Mishari Rashid Alafasy
  static const String baseUrl = 'https://everyayah.com/data/Alafasy_128kbps';
  static const String qariName = 'Mishari Rashid Alafasy';

  // Getters
  bool get isPlaying => !_isDisposed && _isPlaying;
  String? get currentPlayingKey => _currentPlayingKey;

  Stream<PlayerState> get playerStateStream {
    _ensureInitialized();
    if (_stateController == null || _stateController!.isClosed) {
      _stateController = StreamController<PlayerState>.broadcast();
    }
    return _stateController!.stream;
  }

  /// Ensure player is initialized before use
  void _ensureInitialized() {
    if (_isDisposed) {
      debugPrint('⚠️ Service was disposed, reinitializing...');
      _isDisposed = false;
    }
    
    if (_audioPlayer == null) {
      _initializePlayer();
    }
  }

  void _initializePlayer() {
    try {
      // Cleanup old player if exists
      _cleanupPlayer();

      _audioPlayer = AudioPlayer();
      _stateController = StreamController<PlayerState>.broadcast();
      
      // Set player modes
      _audioPlayer!.setReleaseMode(ReleaseMode.stop);
      _audioPlayer!.setPlayerMode(PlayerMode.mediaPlayer);

      // Setup state listener with error handling
      _playerStateSubscription = _audioPlayer!.onPlayerStateChanged.listen(
        (state) {
          if (!_isDisposed && _stateController != null && !_stateController!.isClosed) {
            _stateController!.add(state);
            _isPlaying = state == PlayerState.playing;
            
            debugPrint('🎵 Player state: $state');
            
            if (state == PlayerState.completed || state == PlayerState.stopped) {
              _currentPlayingKey = null;
            }
          }
        },
        onError: (error) {
          debugPrint('⚠️ Player state error: $error');
          if (!_isDisposed && _stateController != null && !_stateController!.isClosed) {
            _stateController!.add(PlayerState.stopped);
          }
          _isPlaying = false;
          _currentPlayingKey = null;
        },
        cancelOnError: false, // Don't cancel on error
      );

      debugPrint('✅ Audio player initialized');
    } catch (e) {
      debugPrint('❌ Audio initialization error: $e');
      _isPlaying = false;
      _currentPlayingKey = null;
    }
  }

  /// Generate URL audio dengan format EveryAyah
  String getAudioUrl({
    required int surahNumber,
    required int ayahNumber,
  }) {
    // Format: 001001.mp3 (surah 3 digit + ayah 3 digit)
    final surahStr = surahNumber.toString().padLeft(3, '0');
    final ayahStr = ayahNumber.toString().padLeft(3, '0');
    final url = '$baseUrl/$surahStr$ayahStr.mp3';
    
    debugPrint('🎵 Audio URL: $url');
    return url;
  }

  /// Play ayah - ROBUST VERSION
  Future<void> playAyah({
    required int surahNumber,
    required int ayahNumber,
  }) async {
    try {
      // Ensure player is initialized
      _ensureInitialized();
      
      if (_audioPlayer == null) {
        throw Exception('Audio player tidak tersedia');
      }

      final key = '$surahNumber:$ayahNumber';
      debugPrint('▶️  Play request: Surah $surahNumber, Ayah $ayahNumber');
      
      // Jika ayat yang sama sedang diputar, pause
      if (_currentPlayingKey == key && _isPlaying) {
        debugPrint('⏸️  Pausing current audio');
        await pause();
        return;
      }

      // Stop audio sebelumnya
      if (_isPlaying || _currentPlayingKey != null) {
        debugPrint('⏹️  Stopping previous audio');
        await _safeStop();
        await Future.delayed(Duration(milliseconds: 300));
      }

      // Set current playing
      _currentPlayingKey = key;

      // Generate URL
      final url = getAudioUrl(
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
      );

      // Play audio with robust error handling
      debugPrint('🎵 Setting audio source...');
      
      try {
        await _audioPlayer!.setSourceUrl(url);
      } catch (e) {
        debugPrint('⚠️ SetSource error: $e');
        // Reinitialize and retry once
        _initializePlayer();
        await Future.delayed(Duration(milliseconds: 100));
        
        if (_audioPlayer == null) {
          throw Exception('Audio player gagal diinisialisasi');
        }
        
        await _audioPlayer!.setSourceUrl(url);
      }
      
      debugPrint('🎵 Starting playback...');
      await _audioPlayer!.resume();
      
      // Wait for state to update
      await Future.delayed(Duration(milliseconds: 400));
      
      // Verify playback started
      try {
        final currentState = _audioPlayer!.state;
        debugPrint('🎵 Current state after play: $currentState');
        
        if (currentState == PlayerState.playing) {
          _isPlaying = true;
          debugPrint('✅ Playing successfully');
        } else if (currentState == PlayerState.paused || currentState == PlayerState.stopped) {
          // Try resume again
          debugPrint('🔄 Retrying resume...');
          await _audioPlayer!.resume();
          await Future.delayed(Duration(milliseconds: 200));
          _isPlaying = _audioPlayer!.state == PlayerState.playing;
        }
      } catch (e) {
        debugPrint('⚠️ State check error: $e');
        // Assume playing if no error during playback
        _isPlaying = true;
      }

    } catch (e) {
      _isPlaying = false;
      _currentPlayingKey = null;
      debugPrint('❌ Play error: $e');
      
      // Provide specific error messages
      String errorMessage;
      if (e.toString().contains('404') || e.toString().contains('Not Found')) {
        errorMessage = 'Audio tidak tersedia';
      } else if (e.toString().contains('timeout') || 
                 e.toString().contains('network') ||
                 e.toString().contains('connection')) {
        errorMessage = 'Koneksi internet lambat';
      } else if (e.toString().contains('No element')) {
        errorMessage = 'Sedang memuat, coba lagi';
      } else {
        errorMessage = 'Gagal memutar audio';
      }
      
      throw Exception(errorMessage);
    }
  }

  /// Safe stop - tidak throw error
  Future<void> _safeStop() async {
    if (_audioPlayer == null) {
      _isPlaying = false;
      _currentPlayingKey = null;
      return;
    }

    try {
      await _audioPlayer!.stop().timeout(
        Duration(seconds: 2),
        onTimeout: () {
          debugPrint('⚠️ Stop timeout - continuing');
        },
      );
    } catch (e) {
      debugPrint('⚠️ Stop error (ignored): $e');
    } finally {
      _isPlaying = false;
      _currentPlayingKey = null;
    }
  }

  /// Pause audio
  Future<void> pause() async {
    if (_audioPlayer == null) {
      debugPrint('⚠️ Cannot pause: player not initialized');
      return;
    }

    try {
      await _audioPlayer!.pause();
      _isPlaying = false;
      debugPrint('⏸️  Paused');
    } catch (e) {
      debugPrint('❌ Pause error: $e');
      _isPlaying = false;
    }
  }

  /// Resume audio
  Future<void> resume() async {
    if (_audioPlayer == null) {
      debugPrint('⚠️ Cannot resume: player not initialized');
      return;
    }

    try {
      await _audioPlayer!.resume();
      _isPlaying = true;
      debugPrint('▶️  Resumed');
    } catch (e) {
      debugPrint('❌ Resume error: $e');
      _isPlaying = false;
    }
  }

  /// Stop audio (public)
  Future<void> stop() async {
    await _safeStop();
    debugPrint('⏹️  Stopped');
  }

  /// Check apakah ayat tertentu sedang diputar
  bool isAyahPlaying(int surahNumber, int ayahNumber) {
    if (_isDisposed || _audioPlayer == null) return false;
    final key = '$surahNumber:$ayahNumber';
    return _currentPlayingKey == key && _isPlaying;
  }

  /// Cleanup player resources
  void _cleanupPlayer() {
    try {
      _playerStateSubscription?.cancel();
      _playerStateSubscription = null;
      
      if (_audioPlayer != null) {
        _audioPlayer!.dispose();
        _audioPlayer = null;
      }
    } catch (e) {
      debugPrint('⚠️ Cleanup error: $e');
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    if (_isDisposed) {
      debugPrint('⚠️ Already disposed');
      return;
    }

    debugPrint('🗑️  Disposing audio service...');
    _isDisposed = true;
    
    try {
      // 1. Stop audio
      if (_isPlaying) {
        await _safeStop();
      }
      
      // 2. Cancel subscription
      await _playerStateSubscription?.cancel();
      _playerStateSubscription = null;
      
      // 3. Close stream controller
      if (_stateController != null && !_stateController!.isClosed) {
        await _stateController!.close();
        _stateController = null;
      }
      
      // 4. Dispose player
      if (_audioPlayer != null) {
        await _audioPlayer!.dispose();
        _audioPlayer = null;
      }
      
      // 5. Reset state
      _isPlaying = false;
      _currentPlayingKey = null;
      
      debugPrint('✅ Audio service disposed successfully');
      
    } catch (e) {
      debugPrint('⚠️ Error during disposal: $e');
    }
  }

  /// Reset service
  Future<void> reset() async {
    debugPrint('🔄 Resetting audio service...');
    await dispose();
    _isDisposed = false;
    _initializePlayer();
  }
}