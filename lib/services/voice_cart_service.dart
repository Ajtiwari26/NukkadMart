import 'dart:async';
import 'dart:typed_data';
import 'dart:io';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import '../config/api_config.dart';
import '../screens/ai_voice_cart_screen.dart';
import '../models/product_model.dart';

class VoiceCartService {
  WebSocketChannel? _channel;
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  bool _isActive = false;
  bool _isStreaming = false;
  int _audioChunkCounter = 0;
  StreamSubscription? _audioStreamSub;
  
  
  // Buffer for incoming audio chunks from backend
  List<int> _audioBuffer = [];
  Timer? _playAudioTimer;
  
  // Flag to discard mic input while AI is talking
  bool _isAiSpeaking = false;
  // Hold AI text until the TTS audio actually plays
  String? _pendingAITranscript;

  bool get isConnected => _isActive;
  bool get isStreaming => _isStreaming;

  // Streams for UI updates
  final _conversationController = StreamController<ConversationMessage>.broadcast();
  final _cartUpdateController = StreamController<Map<String, dynamic>>.broadcast();
  final _cartActionController = StreamController<CartAction>.broadcast();
  final _stateController = StreamController<VoiceAssistantState>.broadcast();

  Stream<ConversationMessage> get conversationStream => _conversationController.stream;
  Stream<Map<String, dynamic>> get cartUpdateStream => _cartUpdateController.stream;
  Stream<CartAction> get cartActionStream => _cartActionController.stream;
  Stream<VoiceAssistantState> get stateStream => _stateController.stream;

  VoiceCartService() {
    _player.setVolume(1.0);
  }

  /// Connect to WebSocket and start a live session
  Future<void> startSession(
    String userId, {
    required double latitude,
    required double longitude,
  }) async {
    try {
      final wsUrl = ApiConfig.baseUrl.replaceFirst('http', 'ws');
      _channel = WebSocketChannel.connect(
        Uri.parse('$wsUrl/api/v1/ws/voice/customer/$userId?latitude=$latitude&longitude=$longitude'),
      );

      _isActive = true;
      _stateController.add(VoiceAssistantState.connecting);

      // Listen for responses from server
      _channel!.stream.listen(
        (data) {
          if (data is String) {
            _handleJsonMessage(data);
          } else if (data is Uint8List) {
            // Audio data from Server (Sarvam TTS)
            _isAiSpeaking = true;
            _stateController.add(VoiceAssistantState.aiSpeaking);
            _queueAudioChunk(data);
          }
        },
        onError: (error) {
          print('WebSocket error: $error');
          _isActive = false;
          _stateController.add(VoiceAssistantState.error);
        },
        onDone: () {
          print('WebSocket closed');
          _isActive = false;
          _stateController.add(VoiceAssistantState.idle);
        },
      );

      _stateController.add(VoiceAssistantState.connected);
    } catch (e) {
      print('Error starting session: $e');
      _stateController.add(VoiceAssistantState.error);
      rethrow;
    }
  }

  /// Start live audio streaming (continuous mode)
  Future<void> startLiveStreaming() async {
    if (!_isActive || _isStreaming) return;

    if (await _recorder.hasPermission()) {
      _isStreaming = true;
      _stateController.add(VoiceAssistantState.listening);

      // Start recording in PCM 16kHz mono (Nova Sonic format)
      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
        ),
      );

      // Stream audio chunks directly to WebSocket in real-time
      _audioStreamSub = stream.listen((chunk) {
        if (_channel != null && _isStreaming) {
          // If AI is speaking, do not send user audio back to backend (prevents echo loop)
          if (!_isAiSpeaking) {
            // Send PCM audio directly to backend
            _channel!.sink.add(Uint8List.fromList(chunk));
          }
        }
      });
    } else {
      throw Exception('Microphone permission not granted');
    }
  }

  /// Stop live audio streaming
  Future<void> stopLiveStreaming() async {
    _isStreaming = false;
    await _audioStreamSub?.cancel();
    _audioStreamSub = null;
    await _recorder.stop();

    // Signal end of audio to backend
    if (_channel != null) {
      _channel!.sink.add(json.encode({'event': 'end_audio'}));
    }

    _stateController.add(VoiceAssistantState.processing);
  }

  void _handleJsonMessage(String jsonStr) {
    try {
      final data = json.decode(jsonStr);
      final event = data['event'];

      switch (event) {
        case 'context_loaded':
          // Backend info only — don't show to user
          print('Context loaded: ${data['data']}');
          break;

        case 'cart_update':
          _cartUpdateController.add(data);
          _processCartUpdate(data);
          break;

        case 'transcript':
          final text = data['text'] ?? '';
          final isUser = data['is_user'] ?? false;

          // Only show meaningful transcripts
          if (text.trim().isNotEmpty) {
            if (isUser) {
              // Show user text immediately
              _conversationController.add(ConversationMessage(
                text: text,
                isUser: isUser,
                timestamp: DateTime.now(),
              ));
            } else {
              // Hold AI text until audio is ready to play
              _pendingAITranscript = text;
              _isAiSpeaking = true;
              _stateController.add(VoiceAssistantState.aiSpeaking);
            }
          }
          break;
      }
    } catch (e) {
      print('Error handling JSON message: $e');
    }
  }

  void _queueAudioChunk(Uint8List audioData) {
    print('🎵 Received audio chunk of size: ${audioData.length} bytes');
    // Append the chunk to our buffer
    _audioBuffer.addAll(audioData);

    // Cancel existing timer
    _playAudioTimer?.cancel();

    // Set a timer to play the buffered audio once we stop receiving chunks for 300ms
    _playAudioTimer = Timer(const Duration(milliseconds: 300), () {
      if (_audioBuffer.isNotEmpty) {
        _playBufferedAudio();
      }
    });
  }

  Future<void> _playBufferedAudio() async {
    try {
      if (_audioBuffer.isEmpty) return;

      // Copy buffer and clear it for the next response
      final audioData = Uint8List.fromList(_audioBuffer);
      print('▶️ Playing buffered audio, total size: ${audioData.length} bytes');
      _audioBuffer.clear();

      final tempDir = await getTemporaryDirectory();

      // Backend (Sarvam) sends complete WAV audio, save it directly
      final tempFile = File('${tempDir.path}/sonic_audio_${_audioChunkCounter++}.wav');
      await tempFile.writeAsBytes(audioData);

      // If we have pending text, show it EXACTLY when audio starts playing
      if (_pendingAITranscript != null) {
        _conversationController.add(ConversationMessage(
          text: _pendingAITranscript!,
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _pendingAITranscript = null;
      }

      await _player.setFilePath(tempFile.path);
      await _player.play();

      // When done playing, go back to listening
      _player.playerStateStream
          .where((s) => s.processingState == ProcessingState.completed)
          .first
          .then((_) {
        _isAiSpeaking = false;
        if (_isStreaming) {
          _stateController.add(VoiceAssistantState.listening);
        } else {
          _stateController.add(VoiceAssistantState.connected);
        }
        tempFile.delete().catchError((_) => File(''));
      });
    } catch (e) {
      print('Error playing audio: $e');
    }
  }

  /// Create a WAV file from raw PCM data
  Uint8List _createWavFromPcm(Uint8List pcmData, int sampleRate, int bitsPerSample, int channels) {
    final dataSize = pcmData.length;
    final fileSize = 36 + dataSize;
    final byteRate = sampleRate * channels * (bitsPerSample ~/ 8);
    final blockAlign = channels * (bitsPerSample ~/ 8);

    final header = ByteData(44);
    // RIFF header
    header.setUint8(0, 0x52); // R
    header.setUint8(1, 0x49); // I
    header.setUint8(2, 0x46); // F
    header.setUint8(3, 0x46); // F
    header.setUint32(4, fileSize, Endian.little);
    header.setUint8(8, 0x57);  // W
    header.setUint8(9, 0x41);  // A
    header.setUint8(10, 0x56); // V
    header.setUint8(11, 0x45); // E
    // fmt chunk
    header.setUint8(12, 0x66); // f
    header.setUint8(13, 0x6D); // m
    header.setUint8(14, 0x74); // t
    header.setUint8(15, 0x20); // (space)
    header.setUint32(16, 16, Endian.little); // chunk size
    header.setUint16(20, 1, Endian.little);  // PCM format
    header.setUint16(22, channels, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, blockAlign, Endian.little);
    header.setUint16(34, bitsPerSample, Endian.little);
    // data chunk
    header.setUint8(36, 0x64); // d
    header.setUint8(37, 0x61); // a
    header.setUint8(38, 0x74); // t
    header.setUint8(39, 0x61); // a
    header.setUint32(40, dataSize, Endian.little);

    final result = Uint8List(44 + dataSize);
    result.setRange(0, 44, header.buffer.asUint8List());
    result.setRange(44, 44 + dataSize, pcmData);
    return result;
  }

  /// Process cart_update events and emit CartAction
  void _processCartUpdate(Map<String, dynamic> data) {
    try {
      final action = data['action'] ?? 'add';
      final productData = data['product'];
      if (productData != null) {
        final product = ProductModel.fromJson(productData);
        final quantity = (data['quantity'] ?? 1).toDouble();
        final storeId = data['store_id'] ?? productData['store_id'] ?? '';

        _cartActionController.add(CartAction(
          action: action,
          product: product,
          quantity: quantity,
          storeId: storeId,
        ));
      }
    } catch (e) {
      print('Error processing cart update: $e');
    }
  }

  /// End the entire session
  Future<void> endSession() async {
    _isActive = false;
    _isStreaming = false;
    await _audioStreamSub?.cancel();
    _audioStreamSub = null;
    await _recorder.stop();
    await _player.stop();
    _channel?.sink.close();
    _stateController.add(VoiceAssistantState.idle);
  }

  void dispose() {
    _conversationController.close();
    _cartUpdateController.close();
    _cartActionController.close();
    _stateController.close();
    endSession();
  }
}

/// Voice assistant states for UI
/// A structured cart action from AI
class CartAction {
  final String action; // 'add', 'remove'
  final ProductModel product;
  final double quantity;
  final String storeId;

  CartAction({
    required this.action,
    required this.product,
    required this.quantity,
    required this.storeId,
  });
}

enum VoiceAssistantState {
  idle,
  connecting,
  connected,
  listening,
  processing,
  aiSpeaking,
  error,
}
