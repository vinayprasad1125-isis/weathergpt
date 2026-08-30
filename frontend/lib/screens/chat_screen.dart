import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../services/voice_service.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/headers.dart';
import '../l10n/l10n.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [
    ChatMessage(
      id: 'welcome',
      role: 'assistant',
      content: 'Namaste! I am WeatherGPT. How can I help you with weather, alerts, or advisories today?',
      timestamp: DateTime.now().toIso8601String(),
      type: 'text',
    ),
  ];
  final TextEditingController _textController = TextEditingController();
  
  final VoiceService _voiceService = VoiceService();
  final TTSService _ttsService = TTSService();
  
  bool _isTyping = false;
  bool _isListening = false;
  String _partialSpeech = '';

  final List<String> _suggestedQuestions = [
    "Will it rain tomorrow?",
    "Is there any cyclone warning?",
    "Should I irrigate my crops?",
    "Show me the forecast for Chennai",
  ];

  @override
  void initState() {
    super.initState();
    _voiceService.init();
  }

  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    await _ttsService.stop();

    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'user',
      content: text,
      timestamp: DateTime.now().toIso8601String(),
      type: 'text',
    );

    setState(() {
      _messages.add(userMsg);
      _textController.clear();
      _isTyping = true;
      _partialSpeech = '';
    });
    _scrollToBottom();
    
    final l10n = AppLocalizations.of(context);
    try {
      final responses = await ChatService.sendMessage(text, l10n.locale.languageCode);

      if (mounted) {
        setState(() {
          _messages.addAll(responses);
          _isTyping = false;
        });
        _scrollToBottom();
        
        for (var res in responses) {
          if (res.type == 'text' && res.content.isNotEmpty) {
            _ttsService.speak(res.content, l10n.locale.languageCode);
            break;
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add(ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            role: 'assistant',
            content: 'Error: ${e.toString().replaceAll("Exception: ", "")}',
            timestamp: DateTime.now().toIso8601String(),
            type: 'text',
          ));
        });
        _scrollToBottom();
      }
    }
  }

  void _toggleListening() async {
    final l10n = AppLocalizations.of(context);
    if (_isListening) {
      await _voiceService.stopListening();
      setState(() {
        _isListening = false;
      });
      if (_partialSpeech.isNotEmpty) {
         _sendMessage(_partialSpeech);
      }
    } else {
      await _ttsService.stop();
      setState(() {
        _isListening = true;
        _partialSpeech = '';
      });
      await _voiceService.startListening(
        localeId: l10n.locale.languageCode,
        onResult: (text) {
          setState(() {
             _partialSpeech = text;
          });
        }
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppHeader(title: l10n.get('chat')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return ChatBubble(message: _messages[index]);
              },
            ),
          ),
          
          if (_isListening)
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              color: AppColors.primary.withOpacity(0.1),
              width: double.infinity,
              child: Column(
                children: [
                   const Icon(LucideIcons.mic, color: Colors.red, size: 32),
                   const SizedBox(height: 8),
                   Text(_partialSpeech.isEmpty ? '${l10n.get('listening')}...' : _partialSpeech, style: Theme.of(context).textTheme.bodyLarge),
                ]
              )
            ),
            
          if (_isTyping)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                      ),
                      const SizedBox(width: 10),
                      Text('WeatherGPT is thinking...', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
              ),
            ),
            
          if (_messages.length == 1)
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                itemCount: _suggestedQuestions.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                    child: ActionChip(
                      label: Text(_suggestedQuestions[index]),
                      onPressed: () => _sendMessage(_suggestedQuestions[index]),
                      backgroundColor: AppColors.card,
                      side: const BorderSide(color: AppColors.primary),
                      labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.primaryDark),
                    ),
                  );
                },
              ),
            ),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(LucideIcons.mic, color: _isListening ? Colors.red : AppColors.textSecondary),
                  onPressed: _toggleListening,
                ),
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: '${l10n.get('search')}...',
                      hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(LucideIcons.send, color: AppColors.surface, size: 20),
                    onPressed: () => _sendMessage(_textController.text),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
