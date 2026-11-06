import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'ai_tutor_provider.dart';

class AiAcademicTutorView extends StatefulWidget {
  const AiAcademicTutorView({super.key});

  @override
  State<AiAcademicTutorView> createState() => _AiAcademicTutorViewState();
}

class _AiAcademicTutorViewState extends State<AiAcademicTutorView> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  static const List<String> _promptChips = [
    'Check My Attendance Risk & Required Classes',
    'Summarize My Borrowed Library Books',
    'Generate 7-Day Exam Revision Schedule',
    'Draft Faculty Project Proposal',
  ];

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage(String text, AiTutorProvider provider) {
    if (text.trim().isEmpty) return;
    _inputController.clear();
    provider.sendPrompt(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Consumer<AiTutorProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: colors.surface,
          resizeToAvoidBottomInset: true, // Essential: docks against software keyboard
          floatingActionButton: FloatingActionButton.small(
            heroTag: 'fab_ai_tutor_clear', // Unique Hero Tag
            backgroundColor: colors.surfaceContainerHighest,
            foregroundColor: colors.onSurface,
            tooltip: 'Clear Chat History',
            onPressed: () => provider.clearChat(),
            child: const Icon(Icons.refresh_rounded, size: 18),
          ),
          body: isLandscape
              ? _buildLandscapeLayout(context, provider, colors)
              : _buildPortraitLayout(context, provider, colors),
        );
      },
    );
  }

  Widget _buildPortraitLayout(
    BuildContext context,
    AiTutorProvider provider,
    ColorScheme colors,
  ) {
    return Column(
      children: [
        _buildPromptChipsBar(provider, colors),
        if (provider.transientStatus != null) _buildTransientIndicator(provider, colors),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            itemCount: provider.messages.length,
            itemBuilder: (context, index) {
              return _buildMessageBubble(provider.messages[index], colors);
            },
          ),
        ),
        _buildInputDock(provider, colors),
      ],
    );
  }

  Widget _buildLandscapeLayout(
    BuildContext context,
    AiTutorProvider provider,
    ColorScheme colors,
  ) {
    return Row(
      children: [
        // Left pane: Context summary & Prompt Suggestions
        Expanded(
          flex: 4,
          child: Container(
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: colors.outlineVariant)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.psychology_rounded, color: colors.primary, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'AI Research Companion',
                        style: TextStyle(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Synchronized with live SQLite ledger for course attendance, active library records, and exam milestones.',
                    style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'RESEARCH PROMPTS',
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ..._promptChips.map((prompt) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: provider.isStreaming ? null : () => _sendMessage(prompt, provider),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: colors.surfaceContainer,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: colors.outlineVariant),
                          ),
                          child: Text(
                            prompt,
                            style: TextStyle(
                              color: colors.onSurface,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
        // Right pane: Chat messages & docked input
        Expanded(
          flex: 6,
          child: Column(
            children: [
              if (provider.transientStatus != null) _buildTransientIndicator(provider, colors),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: provider.messages.length,
                  itemBuilder: (context, index) {
                    return _buildMessageBubble(provider.messages[index], colors);
                  },
                ),
              ),
              _buildInputDock(provider, colors),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPromptChipsBar(AiTutorProvider provider, ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: _promptChips.map((prompt) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                elevation: 0,
                backgroundColor: colors.surfaceContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: colors.outlineVariant),
                ),
                label: Text(
                  prompt,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: provider.isStreaming ? null : () => _sendMessage(prompt, provider),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTransientIndicator(AiTutorProvider provider, ColorScheme colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: colors.primaryContainer.withValues(alpha: 0.6),
      child: Row(
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: colors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              provider.transientStatus!,
              style: TextStyle(
                color: colors.onPrimaryContainer,
                fontSize: 11,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(AiChatMessage message, ColorScheme colors) {
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isUser ? colors.primary : colors.surfaceContainer,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: Border.all(
            color: isUser ? colors.primary : colors.outlineVariant,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isUser ? Icons.person_rounded : Icons.psychology_rounded,
                  size: 13,
                  color: isUser ? colors.onPrimary : colors.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  isUser ? 'Safeer Hussain' : 'Cityzens AI Tutor',
                  style: TextStyle(
                    color: isUser ? colors.onPrimary.withValues(alpha: 0.8) : colors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              message.text,
              style: TextStyle(
                color: isUser ? colors.onPrimary : colors.onSurface,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            if (message.isStreaming) ...[
              const SizedBox(height: 6),
              SizedBox(
                width: 10,
                height: 10,
                child: CircularProgressIndicator(strokeWidth: 1.5, color: colors.secondary),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInputDock(AiTutorProvider provider, ColorScheme colors) {
    // Critical safety rule: rely on Scaffold(resizeToAvoidBottomInset: true) + SafeArea(top: false)
    // NEVER double-apply MediaQuery.of(context).viewInsets.bottom!
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(top: BorderSide(color: colors.outlineVariant)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _inputController,
                textInputAction: TextInputAction.send,
                onSubmitted: (val) => _sendMessage(val, provider),
                decoration: InputDecoration(
                  hintText: 'Ask academic inquiry or research question...',
                  hintStyle: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
                  filled: true,
                  fillColor: colors.surfaceContainer,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: colors.outlineVariant),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: colors.outlineVariant),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: colors.primary, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              style: IconButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
              ),
              icon: const Icon(Icons.send_rounded, size: 18),
              onPressed: provider.isStreaming
                  ? null
                  : () => _sendMessage(_inputController.text, provider),
            ),
          ],
        ),
      ),
    );
  }
}
