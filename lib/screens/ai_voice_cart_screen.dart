import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../services/voice_cart_service.dart';
import '../providers/cart_provider.dart';
import '../services/location_cache_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_theme.dart';

class AIVoiceCartScreen extends StatefulWidget {
  const AIVoiceCartScreen({Key? key}) : super(key: key);

  @override
  State<AIVoiceCartScreen> createState() => _AIVoiceCartScreenState();
}

class _AIVoiceCartScreenState extends State<AIVoiceCartScreen>
    with TickerProviderStateMixin {
  final VoiceCartService _voiceService = VoiceCartService();
  VoiceAssistantState _state = VoiceAssistantState.idle;

  final List<ConversationMessage> _conversation = [];
  final ScrollController _scrollController = ScrollController();

  late AnimationController _pulseController;
  late AnimationController _waveController;
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    // Listen to state changes
    _voiceService.stateStream.listen((state) {
      if (mounted) setState(() => _state = state);
    });

    // Listen to transcripts only
    _voiceService.conversationStream.listen((message) {
      if (mounted) {
        setState(() => _conversation.add(message));
        _scrollToBottom();
      }
    });

    // Listen to cart actions and apply to CartProvider
    _voiceService.cartActionStream.listen((cartAction) {
      if (!mounted) return;
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      if (cartAction.action == 'add') {
        cartProvider.addItem(
          cartAction.product,
          storeId: cartAction.storeId,
          quantity: cartAction.quantity,
        );
      } else if (cartAction.action == 'remove') {
        cartProvider.removeItem(cartAction.product.productId);
      }
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _toggleSession() async {
    if (_state == VoiceAssistantState.idle || _state == VoiceAssistantState.error) {
      // Start session
      try {
        final cachedLocation = await LocationCacheService.getLocation();
        if (cachedLocation == null) {
          throw Exception('Location not available');
        }

        await _voiceService.startSession(
          'user_123',
          latitude: cachedLocation['lat'],
          longitude: cachedLocation['lng'],
        );

        // Auto-start live streaming after connecting
        await Future.delayed(const Duration(milliseconds: 500));
        await _voiceService.startLiveStreaming();

        // Add greeting
        setState(() {
          _conversation.add(ConversationMessage(
            text: 'Namaste! Bataiye aapko kya chahiye?',
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Connection failed: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } else {
      // End session
      await _voiceService.endSession();
      setState(() {
        _state = VoiceAssistantState.idle;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            _buildStateIndicator(),
            Expanded(child: _buildConversationView()),
            _buildCartPreview(),
            _buildVoiceButton(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: AppColors.textPrimary,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Voice Shopping',
                style: AppTheme.heading3.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 2),
              Text(
                _getStatusText(),
                style: AppTheme.caption.copyWith(
                  color: _getStatusColor(),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Cart icon with badge
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/cart'),
            child: Consumer<CartProvider>(
              builder: (context, cart, _) {
                return Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(
                        Icons.shopping_cart_rounded,
                        color: AppColors.textPrimary,
                        size: 20,
                      ),
                      if (cart.items.isNotEmpty)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${cart.itemCount}',
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: AppColors.buttonText,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          if (_state != VoiceAssistantState.idle)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor().withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _getStatusColor().withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getStatusColor(),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'LIVE',
                    style: AppTheme.caption.copyWith(
                      color: _getStatusColor(),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStateIndicator() {
    if (_state == VoiceAssistantState.listening) {
      return AnimatedBuilder(
        animation: _waveController,
        builder: (context, _) {
          return Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(20, (i) {
                final phase = (i / 20) * 2 * pi + _waveController.value * 2 * pi;
                final height = 8 + sin(phase) * 12;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  width: 3,
                  height: height.abs(),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.4 + sin(phase).abs() * 0.6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
          );
        },
      );
    } else if (_state == VoiceAssistantState.aiSpeaking) {
      return AnimatedBuilder(
        animation: _waveController,
        builder: (context, _) {
          return Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(20, (i) {
                final phase = (i / 20) * 2 * pi - _waveController.value * 2 * pi;
                final height = 6 + sin(phase) * 10;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  width: 3,
                  height: height.abs(),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.4 + sin(phase).abs() * 0.6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
          );
        },
      );
    } else if (_state == VoiceAssistantState.processing) {
      return const SizedBox(
        height: 40,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
        ),
      );
    }
    return const SizedBox(height: 40);
  }

  Widget _buildConversationView() {
    if (_conversation.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _glowController,
              builder: (context, child) {
                return Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surface,
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.1 + _glowController.value * 0.2),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.05 + _glowController.value * 0.1),
                        blurRadius: 20 + _glowController.value * 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.mic_none_rounded,
                    size: 48,
                    color: AppColors.textTertiary.withOpacity(0.5 + _glowController.value * 0.3),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Voice Shopping',
              style: AppTheme.heading2.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the mic to start talking\nSpeak naturally in Hindi or Hinglish',
              textAlign: TextAlign.center,
              style: AppTheme.bodyMedium.copyWith(
                color: AppColors.textTertiary,
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: _conversation.length,
      itemBuilder: (context, index) {
        final message = _conversation[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(ConversationMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: message.isUser
              ? AppColors.primary.withOpacity(0.12)
              : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(message.isUser ? 18 : 4),
            bottomRight: Radius.circular(message.isUser ? 4 : 18),
          ),
          border: Border.all(
            color: message.isUser
                ? AppColors.primary.withOpacity(0.25)
                : AppColors.border,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  message.isUser ? Icons.person_rounded : Icons.storefront_rounded,
                  size: 14,
                  color: message.isUser ? AppColors.primary : AppColors.info,
                ),
                const SizedBox(width: 6),
                Text(
                  message.isUser ? 'You' : 'AI Shopkeeper',
                  style: AppTheme.caption.copyWith(
                    color: message.isUser ? AppColors.primary : AppColors.info,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              message.text,
              style: AppTheme.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.timestamp),
              style: AppTheme.caption.copyWith(
                fontSize: 10,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartPreview() {
    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        if (cart.items.isEmpty) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.shopping_cart_rounded, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text('Your Cart', style: AppTheme.heading3.copyWith(fontSize: 15)),
                  const Spacer(),
                  Text(
                    '${cart.items.length} items',
                    style: AppTheme.caption.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 65,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: cart.items.length,
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item.product.name,
                            style: AppTheme.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '${item.quantity}x ₹${item.product.price}',
                            style: AppTheme.caption.copyWith(
                              color: AppColors.primary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total', style: AppTheme.label),
                  Text(
                    '₹${cart.total.toStringAsFixed(0)}',
                    style: AppTheme.priceStyle.copyWith(
                      color: AppColors.primary,
                      fontSize: 17,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVoiceButton() {
    final bool isActive = _state != VoiceAssistantState.idle &&
        _state != VoiceAssistantState.error;
    final bool isListening = _state == VoiceAssistantState.listening;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          Text(
            _getButtonLabel(),
            style: AppTheme.bodySmall.copyWith(
              color: AppColors.textTertiary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: _state == VoiceAssistantState.connecting ? null : _toggleSession,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final double extra = isListening ? _pulseController.value * 15 : 0;
                return Container(
                  width: 80 + extra,
                  height: 80 + extra,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isActive
                        ? LinearGradient(
                            colors: isListening
                                ? [AppColors.primary, AppColors.primaryDark]
                                : [AppColors.info, const Color(0xFF0066CC)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : LinearGradient(
                            colors: [AppColors.surface, AppColors.surfaceVariant],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    border: Border.all(
                      color: isActive
                          ? (isListening ? AppColors.primary : AppColors.info)
                          : AppColors.border,
                      width: 2,
                    ),
                    boxShadow: isListening
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(
                                  0.2 + _pulseController.value * 0.25),
                              blurRadius: 20 + _pulseController.value * 15,
                              spreadRadius: 3 + _pulseController.value * 5,
                            ),
                          ]
                        : isActive
                            ? [
                                BoxShadow(
                                  color: AppColors.info.withOpacity(0.15),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                ),
                              ]
                            : [],
                  ),
                  child: Icon(
                    _getButtonIcon(),
                    size: 36,
                    color: isActive ? AppColors.buttonText : AppColors.textTertiary,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText() {
    switch (_state) {
      case VoiceAssistantState.idle:
        return 'Tap mic to start';
      case VoiceAssistantState.connecting:
        return 'Connecting...';
      case VoiceAssistantState.connected:
        return 'Connected';
      case VoiceAssistantState.listening:
        return 'Listening...';
      case VoiceAssistantState.processing:
        return 'Processing...';
      case VoiceAssistantState.aiSpeaking:
        return 'AI is speaking...';
      case VoiceAssistantState.error:
        return 'Connection error';
    }
  }

  Color _getStatusColor() {
    switch (_state) {
      case VoiceAssistantState.idle:
        return AppColors.textTertiary;
      case VoiceAssistantState.connecting:
        return AppColors.warning;
      case VoiceAssistantState.connected:
        return AppColors.primary;
      case VoiceAssistantState.listening:
        return AppColors.primary;
      case VoiceAssistantState.processing:
        return AppColors.warning;
      case VoiceAssistantState.aiSpeaking:
        return AppColors.info;
      case VoiceAssistantState.error:
        return AppColors.error;
    }
  }

  String _getButtonLabel() {
    switch (_state) {
      case VoiceAssistantState.idle:
      case VoiceAssistantState.error:
        return 'Tap to start voice shopping';
      case VoiceAssistantState.connecting:
        return 'Connecting...';
      case VoiceAssistantState.listening:
        return 'Speak naturally — I\'m listening';
      case VoiceAssistantState.aiSpeaking:
        return 'AI is responding...';
      case VoiceAssistantState.processing:
        return 'Processing your request...';
      case VoiceAssistantState.connected:
        return 'Ready';
    }
  }

  IconData _getButtonIcon() {
    switch (_state) {
      case VoiceAssistantState.idle:
      case VoiceAssistantState.error:
        return Icons.mic_rounded;
      case VoiceAssistantState.connecting:
        return Icons.hourglass_top_rounded;
      case VoiceAssistantState.listening:
        return Icons.graphic_eq_rounded;
      case VoiceAssistantState.aiSpeaking:
        return Icons.volume_up_rounded;
      case VoiceAssistantState.processing:
        return Icons.auto_awesome;
      case VoiceAssistantState.connected:
        return Icons.mic_rounded;
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _glowController.dispose();
    _scrollController.dispose();
    _voiceService.dispose();
    super.dispose();
  }
}

class ConversationMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ConversationMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
