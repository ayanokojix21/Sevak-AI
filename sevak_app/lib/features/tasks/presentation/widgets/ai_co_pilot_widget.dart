import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../providers/need_providers.dart';
import '../../domain/entities/task_entity.dart';

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
    {'role': 'assistant', 'content': 'I am your SevakAI Co-Pilot. How can I assist you at the scene?'}
  ];
  bool _isTyping = false;

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
      final context = 'Task: ${widget.task.needType}. Description: ${widget.task.description}. Status: ${widget.task.status}.';
      final response = await ai.generateCoPilotResponse(context, text);
      
      if (mounted) {
        setState(() {
          _messages.add({'role': 'assistant', 'content': response});
          _isTyping = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({'role': 'assistant', 'content': 'Sorry, I am having trouble connecting. Please follow local safety protocols.'});
          _isTyping = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20,
      right: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_isExpanded)
            Container(
              width: 300,
              height: 400,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.bgSurface.withAlpha(240),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withAlpha(50)),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20)],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        const Text('SevakAI Co-Pilot', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        IconButton(
                          onPressed: () => setState(() => _isExpanded = false),
                          icon: const Icon(Icons.close, color: Colors.white, size: 18),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _messages.length + (_isTyping ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _messages.length) {
                          return const Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                            ),
                          );
                        }
                        final msg = _messages[index];
                        final isUser = msg['role'] == 'user';
                        return Align(
                          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isUser ? AppColors.primary : AppColors.bgElevated,
                              borderRadius: BorderRadius.circular(12).copyWith(
                                bottomRight: isUser ? Radius.zero : null,
                                bottomLeft: !isUser ? Radius.zero : null,
                              ),
                            ),
                            child: Text(
                              msg['content']!,
                              style: TextStyle(
                                color: isUser ? Colors.white : AppColors.textPrimary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _chatController,
                            decoration: InputDecoration(
                              hintText: 'Ask for advice...',
                              fillColor: AppColors.bgBase,
                              filled: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                            style: const TextStyle(fontSize: 13),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _sendMessage,
                          icon: const Icon(Icons.send, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().scale(alignment: Alignment.bottomRight, curve: Curves.easeOutBack, duration: 400.ms),
          
          FloatingActionButton.extended(
            onPressed: () => setState(() => _isExpanded = !_isExpanded),
            backgroundColor: AppColors.primary,
            icon: const Icon(Icons.auto_awesome, color: Colors.white),
            label: Text(_isExpanded ? 'Close AI' : 'Ask AI Co-Pilot', style: const TextStyle(color: Colors.white)),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(duration: 3.seconds, color: Colors.white24),
        ],
      ),
    );
  }
}
