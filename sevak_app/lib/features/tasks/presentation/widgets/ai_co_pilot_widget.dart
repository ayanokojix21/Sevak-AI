import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../providers/need_providers.dart';
import '../../domain/entities/task_entity.dart';

/// AI Co-Pilot chat widget — overlaid on the task detail / live tracking page.
/// Full M3: uses colorScheme tokens, no hardcoded AppColors.
class AiCoPilotWidget extends ConsumerStatefulWidget {
  final TaskEntity task;
  const AiCoPilotWidget({super.key, required this.task});

  @override
  ConsumerState<AiCoPilotWidget> createState() => _AiCoPilotWidgetState();
}

class _AiCoPilotWidgetState extends ConsumerState<AiCoPilotWidget> {
  bool _isExpanded = false;
  final TextEditingController _chatController = TextEditingController();
  final List<Map<String, String>> _messages = [
    {
      'role': 'assistant',
      'content':
          'I am your SevakAI Co-Pilot. How can I assist you at the scene?'
    }
  ];
  bool _isTyping = false;

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _chatController.clear();
      _isTyping = true;
    });

    try {
      final ai = ref.read(aiDatasourceProvider);
      final ctx =
          'Task: ${widget.task.needType}. Description: ${widget.task.description}. Status: ${widget.task.status}.';
      final response = await ai.generateCoPilotResponse(ctx, text);
      if (mounted) {
        setState(() {
          _messages.add({'role': 'assistant', 'content': response});
          _isTyping = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({
            'role': 'assistant',
            'content':
                'Sorry, I am having trouble connecting. Please follow local safety protocols.'
          });
          _isTyping = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Positioned(
      bottom: 20,
      right: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_isExpanded)
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 4,
              shadowColor: Colors.black26,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: cs.outlineVariant)),
              color: cs.surfaceContainerHigh,
              child: SizedBox(
                width: 300,
                height: 400,
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.auto_awesome_rounded,
                              color: cs.onPrimaryContainer, size: 18),
                          const SizedBox(width: 8),
                          Text('SevakAI Co-Pilot',
                              style: TextStyle(
                                  color: cs.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14)),
                          const Spacer(),
                          IconButton(
                            onPressed: () =>
                                setState(() => _isExpanded = false),
                            icon: Icon(Icons.close_rounded,
                                color: cs.onPrimaryContainer, size: 18),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                    // Messages
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _messages.length + (_isTyping ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _messages.length) {
                            return const Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: EdgeInsets.all(8),
                                child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2)),
                              ),
                            );
                          }
                          final msg = _messages[index];
                          final isUser = msg['role'] == 'user';
                          return Align(
                            alignment: isUser
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isUser
                                    ? cs.primaryContainer
                                    : cs.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12).copyWith(
                                  bottomRight:
                                      isUser ? Radius.zero : null,
                                  bottomLeft:
                                      !isUser ? Radius.zero : null,
                                ),
                              ),
                              child: Text(
                                msg['content']!,
                                style: TextStyle(
                                  color: isUser
                                      ? cs.onPrimaryContainer
                                      : cs.onSurface,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Input
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _chatController,
                              decoration: InputDecoration(
                                hintText: 'Ask for advice...',
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide:
                                      BorderSide(color: cs.outlineVariant),
                                ),
                              ),
                              style: const TextStyle(fontSize: 13),
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                          const SizedBox(width: 6),
                          IconButton.filled(
                            onPressed: _sendMessage,
                            icon: const Icon(Icons.send_rounded, size: 18),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().scale(
                alignment: Alignment.bottomRight,
                curve: Curves.easeOutBack,
                duration: 350.ms),

          // FAB
          FloatingActionButton.extended(
            heroTag: 'ai_copilot_fab',
            onPressed: () => setState(() => _isExpanded = !_isExpanded),
            icon: const Icon(Icons.auto_awesome_rounded),
            label:
                Text(_isExpanded ? 'Close AI' : 'Ask AI Co-Pilot'),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
              .shimmer(duration: 3.seconds, color: Colors.white24),
        ],
      ),
    );
  }
}
