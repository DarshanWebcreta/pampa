import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pampa/data/service/di.dart';
import 'package:provider/provider.dart';

import 'package:pampa/core/values/app_text_value.dart';
import 'package:pampa/core/values/colors.dart';
import 'package:pampa/core/widgets/text_widget.dart';
import 'package:pampa/core/utils/functional_component.dart';
import 'package:pampa/features/messaging/data/models/conversation_model.dart';
import 'package:pampa/features/messaging/presentation/provider/messaging_provider.dart';
import 'package:pampa/features/provider_home/presentation/provider/provider_messaging_provider.dart';
import 'package:pampa/features/support/presentation/widgets/report_issue_bottom_sheet.dart';

/// Chat screen used by the provider side.
/// "From me" = senderType == 'provider'.
class ProviderChatScreen extends StatefulWidget {
  final ConversationModel conversation;
  final String? customerName;

  const ProviderChatScreen({
    super.key,
    required this.conversation,
    this.customerName,
  });

  @override
  State<ProviderChatScreen> createState() => _ProviderChatScreenState();
}

class _ProviderChatScreenState extends State<ProviderChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProviderMessagingProvider>().openConversation(
        widget.conversation.id,
      );
    });
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    Future.microtask(() => getIt<ProviderMessagingProvider>().clearActiveConversation());
    super.dispose();
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();
    context.read<ProviderMessagingProvider>().sendMessage(
      conversationId: widget.conversation.id,
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
    final other = widget.conversation.otherUser;
    final customerName = (widget.customerName?.trim().isNotEmpty ?? false)
        ? widget.customerName!.trim()
        : other.name;

    return Scaffold(
      backgroundColor: AppColor.authBg,
      appBar: AppBar(
        backgroundColor: AppColor.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColor.darkGrey,
            size: 18,
          ),
        ),
        title: Row(
          children: [
            _MiniAvatar(name: customerName),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    customerName,
                    fontSize: FontSizes.regular,
                    fontWeight: FontWeights.bold,
                    color: AppColor.darkGrey,
                    maxLines: 1,
                  ),
                  AppText('Customer', fontSize: 11, color: AppColor.grey),
                ],
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'report') {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => ReportIssueBottomSheet(
                    conversationId: widget.conversation.id,
                  ),
                );
              }
            },
            icon: const Icon(Icons.more_vert, color: AppColor.darkGrey),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.report_problem_outlined,
                        color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    AppText('Report', color: Colors.red),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<ProviderMessagingProvider>(
        builder: (context, provider, _) {
          final isLoading = provider.msgStatus == MessagesFetchStatus.loading;
          final isError = provider.msgStatus == MessagesFetchStatus.error;
          final msgs = provider.messages;

          // Show the 3-dot typing loader explicitly when receiving a push notification for this chat
          final showTypingLoader = provider.isReceivingNewMessage;

          if (msgs.isNotEmpty || showTypingLoader) {
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _scrollToBottom(),
            );
          }

          return Column(
            children: [
              // ── Messages area ────────────────────────────────────────
              Expanded(
                child: isError
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.wifi_off_rounded,
                                color: AppColor.authButton,
                                size: 40,
                              ),
                              const SizedBox(height: 12),
                              AppText(
                                provider.msgError,
                                fontSize: FontSizes.small,
                                color: AppColor.grey,
                                align: TextAlign.center,
                                maxLines: 3,
                              ),
                              const SizedBox(height: 16),
                              GestureDetector(
                                onTap: () => provider.openConversation(
                                  widget.conversation.id,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColor.authButton,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: AppText(
                                    'Retry',
                                    fontSize: FontSizes.small,
                                    fontWeight: FontWeights.semiBold,
                                    color: AppColor.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : isLoading
                    ? const _ChatLoadingShimmer()
                    : msgs.isEmpty && !showTypingLoader
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.chat_bubble_outline_rounded,
                              color: AppColor.authButton,
                              size: 40,
                            ),
                            const SizedBox(height: 12),
                            AppText(
                              'No messages yet',
                              fontSize: FontSizes.regular,
                              color: AppColor.grey,
                            ),
                            const SizedBox(height: 4),
                            AppText(
                              'Say hi to $customerName!',
                              fontSize: FontSizes.small,
                              color: AppColor.mediumGrey,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        itemCount: msgs.length + (showTypingLoader ? 1 : 0),
                        itemBuilder: (context, i) {
                          if (i == msgs.length) {
                            return const _TypingLoader();
                          }
                          final msg = msgs[i];
                          final showDate =
                              i == 0 ||
                              !_isSameDay(msgs[i - 1].createdAt, msg.createdAt);
                          return Column(
                            children: [
                              if (showDate) _DateDivider(date: msg.createdAt),
                              _MessageBubble(
                                message: msg,
                                conversationId: widget.conversation.id,
                              ),
                            ],
                          );
                        },
                      ),
              ),

              // ── Input bar always visible ─────────────────────────────
              _InputBar(
                controller: _msgCtrl,
                isSending: provider.isSending,
                onSend: isLoading ? null : _send,
              ),
            ],
          );
        },
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ─── Message bubble (provider side: isFromMe = senderType == 'provider') ─────

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final int conversationId;

  const _MessageBubble({
    required this.message,
    required this.conversationId,
  });

  @override
  Widget build(BuildContext context) {
    final isMe = message.isFromProvider;
    final timeStr = DateFormat('h:mm a').format(message.createdAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            _MiniAvatar(name: message.senderName, size: 28),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => ReportIssueBottomSheet(
                    conversationId: conversationId,
                    messageId: message.id,
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.68,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
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
                                .read<ProviderMessagingProvider>()
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
            child: Divider(color: AppColor.mediumGrey.withValues(alpha: 0.5)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: AppText(
              label,
              fontSize: 11,
              color: AppColor.grey,
              fontWeight: FontWeights.medium,
            ),
          ),
          Expanded(
            child: Divider(color: AppColor.mediumGrey.withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
  }
}

// ─── Input bar ────────────────────────────────────────────────────────────────

class _InputBar extends StatefulWidget {
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback? onSend;

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
      () => setState(() => _hasText = widget.controller.text.trim().isNotEmpty),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        MediaQuery.of(context).padding.bottom + 10,
      ),
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
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
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

// ─── Typing Loader ────────────────────────────────────────────────────────────

class _TypingLoader extends StatefulWidget {
  const _TypingLoader();

  @override
  State<_TypingLoader> createState() => _TypingLoaderState();
}

class _TypingLoaderState extends State<_TypingLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomRight: Radius.circular(18),
              bottomLeft: Radius.circular(4),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              return AnimatedBuilder(
                animation: _ctrl,
                builder: (context, child) {
                  final delay = i * 0.28;
                  final t = (((_ctrl.value - delay) % 1.0 + 1.0) % 1.0);
                  final y = math.sin(t * math.pi) * 3.5;
                  return Transform.translate(
                    offset: Offset(0, -y),
                    child: Container(
                      width: 6,
                      height: 6,
                      margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                      decoration: BoxDecoration(
                        color: AppColor.authButton.withValues(
                          alpha: 0.4 + 0.6 * math.sin(t * math.pi).clamp(0, 1),
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _ChatLoadingShimmer extends StatefulWidget {
  const _ChatLoadingShimmer();

  @override
  State<_ChatLoadingShimmer> createState() => _ChatLoadingShimmerState();
}

class _ChatLoadingShimmerState extends State<_ChatLoadingShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final pulse = 0.45 + (0.25 * _controller.value);
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          children: [
            _ShimmerBubble(alignRight: false, widthFactor: 0.56, alpha: pulse),
            _ShimmerBubble(
              alignRight: true,
              widthFactor: 0.42,
              alpha: pulse - 0.08,
            ),
            _ShimmerBubble(alignRight: false, widthFactor: 0.66, alpha: pulse),
            _ShimmerBubble(
              alignRight: true,
              widthFactor: 0.34,
              alpha: pulse - 0.1,
            ),
            _ShimmerBubble(
              alignRight: false,
              widthFactor: 0.5,
              alpha: pulse - 0.03,
            ),
          ],
        );
      },
    );
  }
}

class _ShimmerBubble extends StatelessWidget {
  const _ShimmerBubble({
    required this.alignRight,
    required this.widthFactor,
    required this.alpha,
  });

  final bool alignRight;
  final double widthFactor;
  final double alpha;

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width * 0.68;
    final bubbleWidth = maxWidth * widthFactor;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: alignRight
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Container(
            width: bubbleWidth,
            height: 42,
            decoration: BoxDecoration(
              color: AppColor.mediumGrey.withValues(
                alpha: alpha.clamp(0.2, 0.9),
              ),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(alignRight ? 18 : 4),
                bottomRight: Radius.circular(alignRight ? 4 : 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
