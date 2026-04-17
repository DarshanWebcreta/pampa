import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pampa/core/utils/functional_component.dart';
import 'package:provider/provider.dart';

import 'package:pampa/core/values/app_text_value.dart';
import 'package:pampa/core/values/colors.dart';
import 'package:pampa/core/widgets/text_widget.dart';
import 'package:pampa/data/service/di.dart';
import 'package:pampa/features/messaging/data/models/conversation_model.dart';
import 'package:pampa/features/messaging/presentation/provider/messaging_provider.dart';

/// Single screen: loads/creates the conversation then shows the chat UI.
/// No pushReplacement needed — avoids GoRouter/Navigator stack conflicts.
class BookingChatScreen extends StatefulWidget {
  final int bookingId;
  final int providerId;
  final String providerName;

  const BookingChatScreen({
    super.key,
    required this.bookingId,
    required this.providerId,
    required this.providerName,
  });

  @override
  State<BookingChatScreen> createState() => _BookingChatScreenState();
}

class _BookingChatScreenState extends State<BookingChatScreen> {
  ConversationModel? _conversation;
  bool _isLoading = true;
  String _error = '';

  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = '';
    });

    final mp = context.read<MessagingProvider>();

    final conv = await mp.createOrGetConversation(
      providerId: widget.providerId,
      bookingId: widget.bookingId,
    );

    if (!mounted) return;

    if (conv == null) {
      setState(() {
        _isLoading = false;
        _error = 'Could not start conversation. Please try again.';
      });
      return;
    }

    _conversation = conv;
    await mp.openConversation(conv.id);

    if (!mounted) return;
    setState(() => _isLoading = false);

    _scrollToBottom();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    Future.microtask(() => getIt<MessagingProvider>().clearActiveConversation());
    super.dispose();
  }

  Future<void> _send() async {
    final conv = _conversation;
    if (conv == null) return;
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();
    context.read<MessagingProvider>().sendMessage(
          conversationId: conv.id,
          body: text,
        ).then((success) {
          if (!success && mounted) {
            FunctionalComponent.showSnackBar(
              context: context,
              title: 'Message failed to send',
              success: false,
            );
          }
        });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.authBg,
      appBar: AppBar(
        backgroundColor: AppColor.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColor.darkGrey, size: 18),
        ),
        title: Row(
          children: [
            _MiniAvatar(name: widget.providerName),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    widget.providerName,
                    fontSize: FontSizes.regular,
                    fontWeight: FontWeights.bold,
                    color: AppColor.darkGrey,
                    maxLines: 1,
                  ),
                  AppText(
                    'Provider',
                    fontSize: 11,
                    color: AppColor.grey,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColor.authButton),
      );
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded,
                  color: AppColor.authButton, size: 40),
              const SizedBox(height: 12),
              AppText(_error,
                  fontSize: FontSizes.small,
                  color: AppColor.grey,
                  align: TextAlign.center,
                  maxLines: 3),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _init,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                      color: AppColor.authButton,
                      borderRadius: BorderRadius.circular(10)),
                  child: AppText('Retry',
                      fontSize: FontSizes.small,
                      fontWeight: FontWeights.semiBold,
                      color: AppColor.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Consumer<MessagingProvider>(
      builder: (context, provider, _) {
        if (provider.msgStatus == MessagesFetchStatus.loading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColor.authButton),
          );
        }

        final msgs = provider.messages;
        if (msgs.isNotEmpty) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _scrollToBottom());
        }

        return Column(
          children: [
            Expanded(
              child: msgs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: AppColor.authButton.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                                Icons.chat_bubble_outline_rounded,
                                color: AppColor.authButton,
                                size: 28),
                          ),
                          const SizedBox(height: 12),
                          AppText('No messages yet',
                              fontSize: FontSizes.regular,
                              color: AppColor.grey),
                          const SizedBox(height: 4),
                          AppText('Say hi to ${widget.providerName}!',
                              fontSize: FontSizes.small,
                              color: AppColor.mediumGrey),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      itemCount: msgs.length,
                      itemBuilder: (_, i) {
                        final msg = msgs[i];
                        final showDate = i == 0 ||
                            !_isSameDay(msgs[i - 1].createdAt, msg.createdAt);
                        return Column(
                          children: [
                            if (showDate) _DateDivider(date: msg.createdAt),
                            _MessageBubble(message: msg),
                          ],
                        );
                      },
                    ),
            ),
            _InputBar(
              controller: _msgCtrl,
              isSending: provider.isSending,
              onSend: _send,
            ),
          ],
        );
      },
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ─── Message bubble ───────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isMe = message.isFromMe;
    final timeStr = DateFormat('h:mm a').format(message.createdAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            _MiniAvatar(name: message.senderName, size: 28),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.68,
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe ? AppColor.authButton : AppColor.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMe ? 18 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: AppText(
                    message.body,
                    fontSize: FontSizes.regular,
                    color: isMe ? AppColor.white : AppColor.darkGrey,
                    maxLines: 100,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppText(timeStr, fontSize: 10, color: AppColor.grey),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      if (message.status == MessageStatus.sending)
                        const Icon(Icons.done_rounded,
                            size: 12, color: AppColor.grey),
                      if (message.status == MessageStatus.sent)
                        Icon(Icons.done_all_rounded,
                            size: 12,
                            color: message.readAt != null
                                ? AppColor.authButton
                                : AppColor.grey),
                      if (message.status == MessageStatus.error)
                        GestureDetector(
                          onTap: () => context
                              .read<MessagingProvider>()
                              .retryMessage(message.id),
                          child: const Icon(Icons.error_outline_rounded,
                              size: 14, color: AppColor.red),
                        ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 4),
        ],
      ),
    );
  }
}

// ─── Date divider ─────────────────────────────────────────────────────────────

class _DateDivider extends StatelessWidget {
  final DateTime date;
  const _DateDivider({required this.date});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;
    final label = diff == 0
        ? 'Today'
        : diff == 1
            ? 'Yesterday'
            : DateFormat('MMM d, yyyy').format(date);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
              child: Divider(
                  color: AppColor.mediumGrey.withValues(alpha: 0.5))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: AppText(label,
                fontSize: 11,
                color: AppColor.grey,
                fontWeight: FontWeights.medium),
          ),
          Expanded(
              child: Divider(
                  color: AppColor.mediumGrey.withValues(alpha: 0.5))),
        ],
      ),
    );
  }
}

// ─── Input bar ────────────────────────────────────────────────────────────────

class _InputBar extends StatefulWidget {
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  @override
  State<_InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<_InputBar> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(
        () => setState(() => _hasText = widget.controller.text.trim().isNotEmpty));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 10, 16, MediaQuery.of(context).padding.bottom + 10),
      decoration: BoxDecoration(
        color: AppColor.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: AppColor.authBg,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: widget.controller,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(fontSize: 14, color: AppColor.darkGrey),
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(fontSize: 14, color: AppColor.grey),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: (_hasText && !widget.isSending) ? widget.onSend : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (_hasText && !widget.isSending)
                    ? AppColor.authButton
                    : AppColor.mediumGrey,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded,
                  color: AppColor.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Mini avatar ──────────────────────────────────────────────────────────────

class _MiniAvatar extends StatelessWidget {
  final String name;
  final double size;
  const _MiniAvatar({required this.name, this.size = 36});

  @override
  Widget build(BuildContext context) {
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColor.authButton.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: AppText(
        initials.isEmpty ? '?' : initials,
        fontSize: size * 0.3,
        fontWeight: FontWeights.bold,
        color: AppColor.authButton,
      ),
    );
  }
}
