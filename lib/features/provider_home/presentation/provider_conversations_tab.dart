import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:pampa/core/values/app_text_value.dart';
import 'package:pampa/core/values/colors.dart';
import 'package:pampa/core/widgets/text_widget.dart';
import 'package:pampa/features/messaging/data/models/conversation_model.dart';
import 'package:pampa/features/messaging/presentation/provider/messaging_provider.dart';
import 'package:pampa/features/provider_home/presentation/provider/provider_messaging_provider.dart';
import 'package:pampa/features/provider_home/presentation/provider_chat_screen.dart';

class ProviderConversationsTab extends StatefulWidget {
  const ProviderConversationsTab({super.key});

  @override
  State<ProviderConversationsTab> createState() =>
      _ProviderConversationsTabState();
}

class _ProviderConversationsTabState extends State<ProviderConversationsTab> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openChat(ConversationModel conversation) {
    final provider = context.read<ProviderMessagingProvider>();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: ProviderChatScreen(conversation: conversation),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProviderMessagingProvider>(
      builder: (context, provider, _) {
        final allConvs = provider.conversations;
        final filteredConvs = _query.isEmpty
            ? allConvs
            : allConvs
                .where((c) =>
                    c.otherUser.name
                        .toLowerCase()
                        .contains(_query.toLowerCase()) ||
                    (c.lastMessage?.body
                            .toLowerCase()
                            .contains(_query.toLowerCase()) ??
                        false))
                .toList();
        final convs = [...filteredConvs]
          ..sort((a, b) {
            final aPinned = _isAdminPinnedConversation(a);
            final bPinned = _isAdminPinnedConversation(b);
            if (aPinned != bPinned) return aPinned ? -1 : 1;
            return b.lastMessageAt.compareTo(a.lastMessageAt);
          });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Container(
              color: AppColor.white,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                left: 20,
                right: 20,
                bottom: 12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    'Messages',
                    fontSize: 20,
                    fontWeight: FontWeights.bold,
                    color: AppColor.darkGrey,
                  ),
                  const SizedBox(height: 12),
                  // Search bar
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColor.authBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _query = v),
                      style: const TextStyle(
                          fontSize: 14, color: AppColor.darkGrey),
                      decoration: InputDecoration(
                        hintText: 'Search conversations...',
                        hintStyle: const TextStyle(
                            fontSize: 14, color: AppColor.grey),
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: AppColor.grey, size: 20),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                        suffixIcon: _query.isNotEmpty
                            ? GestureDetector(
                                onTap: () {
                                  _searchCtrl.clear();
                                  setState(() => _query = '');
                                },
                                child: const Icon(Icons.close_rounded,
                                    color: AppColor.grey, size: 18),
                              )
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Content ─────────────────────────────────────────────────────
            Expanded(child: _buildBody(provider, convs)),
          ],
        );
      },
    );
  }

  Widget _buildBody(
      ProviderMessagingProvider provider, List<ConversationModel> convs) {
    switch (provider.convStatus) {
      case ConversationsFetchStatus.loading:
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: 5,
          itemBuilder: (_, __) => const _ConvShimmer(),
        );

      case ConversationsFetchStatus.error:
        return _ErrorState(
          message: provider.convError,
          onRetry: provider.refreshConversations,
        );

      case ConversationsFetchStatus.initial:
      case ConversationsFetchStatus.success:
        if (convs.isEmpty) {
          return _EmptyState(isSearch: _query.isNotEmpty);
        }
        return RefreshIndicator(
          color: AppColor.authButton,
          onRefresh: provider.refreshConversations,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: convs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _ConversationTile(
              conversation: convs[i],
              onTap: () => _openChat(convs[i]),
            ),
          ),
        );
    }
  }
}

bool _isAdminPinnedConversation(ConversationModel conversation) {
  final otherName = conversation.otherUser.name.trim().toLowerCase();
  return conversation.otherUser.id == 1 || otherName == 'super admin';
}

// ─── Conversation tile ────────────────────────────────────────────────────────

class _ConversationTile extends StatelessWidget {
  final ConversationModel conversation;
  final VoidCallback onTap;

  const _ConversationTile({required this.conversation, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final last = conversation.lastMessage;
    final hasUnread = conversation.unreadCount > 0;
    final isPinnedAdmin = _isAdminPinnedConversation(conversation);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: isPinnedAdmin
              ? AppColor.authButton.withValues(alpha: 0.08)
              : AppColor.white,
          borderRadius: BorderRadius.circular(16),
          border: isPinnedAdmin
              ? Border.all(
                  color: AppColor.authButton.withValues(alpha: 0.35),
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _Avatar(name: conversation.otherUser.name),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: AppText(
                            isPinnedAdmin
                                ? '${conversation.otherUser.name} (Pinned)'
                                : conversation.otherUser.name,
                            fontSize: FontSizes.regular,
                            fontWeight: hasUnread
                                ? FontWeights.bold
                                : FontWeights.semiBold,
                            color: AppColor.darkGrey,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (isPinnedAdmin) ...[
                          Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColor.authButton.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.push_pin_rounded,
                              size: 11,
                              color: AppColor.authButton,
                            ),
                          ),
                        ],
                        AppText(
                          _timeLabel(conversation.lastMessageAt),
                          fontSize: 11,
                          color: hasUnread
                              ? AppColor.authButton
                              : AppColor.grey,
                          fontWeight: hasUnread
                              ? FontWeights.semiBold
                              : FontWeights.regular,
                        ),
                      ],
                    ),
                    if (last != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: AppText(
                              last.body,
                              fontSize: FontSizes.small,
                              color: hasUnread
                                  ? AppColor.darkGrey
                                  : AppColor.grey,
                              maxLines: 1,
                              fontWeight: hasUnread
                                  ? FontWeights.medium
                                  : FontWeights.regular,
                            ),
                          ),
                          if (hasUnread) ...[
                            const SizedBox(width: 8),
                            Container(
                              width: 20,
                              height: 20,
                              decoration: const BoxDecoration(
                                color: AppColor.authButton,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: AppText(
                                conversation.unreadCount > 9
                                    ? '9+'
                                    : '${conversation.unreadCount}',
                                fontSize: 10,
                                fontWeight: FontWeights.bold,
                                color: AppColor.white,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColor.mediumGrey, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  String _timeLabel(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return DateFormat('h:mm a').format(dt);
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return DateFormat('EEE').format(dt);
    return DateFormat('MMM d').format(dt);
  }
}

// ─── Avatar ───────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String name;
  const _Avatar({required this.name});

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
      width: 52,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColor.authButton.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: AppText(
        initials.isEmpty ? '?' : initials,
        fontSize: 16,
        fontWeight: FontWeights.bold,
        color: AppColor.authButton,
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool isSearch;
  const _EmptyState({required this.isSearch});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                  color: AppColor.authBg, shape: BoxShape.circle),
              child: const Icon(Icons.chat_bubble_outline_rounded,
                  size: 34, color: AppColor.authButton),
            ),
            const SizedBox(height: 20),
            AppText(
              isSearch ? 'No results' : 'No Messages Yet',
              fontSize: FontSizes.medium,
              fontWeight: FontWeights.semiBold,
              color: AppColor.darkGrey,
            ),
            const SizedBox(height: 8),
            AppText(
              isSearch
                  ? 'Try a different search term.'
                  : 'Your conversations with customers will appear here.',
              fontSize: FontSizes.small,
              color: AppColor.grey,
              align: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Error state ──────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                  color: AppColor.authBg, shape: BoxShape.circle),
              child: const Icon(Icons.wifi_off_rounded,
                  size: 36, color: AppColor.authButton),
            ),
            const SizedBox(height: 20),
            AppText('Something went wrong',
                fontSize: FontSizes.medium,
                fontWeight: FontWeights.semiBold,
                color: AppColor.darkGrey),
            const SizedBox(height: 8),
            AppText(message,
                fontSize: FontSizes.small,
                color: AppColor.grey,
                align: TextAlign.center,
                maxLines: 3),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                decoration: BoxDecoration(
                    color: AppColor.authButton,
                    borderRadius: BorderRadius.circular(12)),
                child: AppText('Try Again',
                    fontSize: FontSizes.regular,
                    fontWeight: FontWeights.semiBold,
                    color: AppColor.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shimmer ──────────────────────────────────────────────────────────────────

class _ConvShimmer extends StatefulWidget {
  const _ConvShimmer();

  @override
  State<_ConvShimmer> createState() => _ConvShimmerState();
}

class _ConvShimmerState extends State<_ConvShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Opacity(
        opacity: _anim.value,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: AppColor.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                _box(52, 52, radius: 26),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _box(140, 14),
                          const Spacer(),
                          _box(48, 11),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _box(200, 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _box(double w, double h, {double radius = 6}) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
            color: AppColor.lightGrey,
            borderRadius: BorderRadius.circular(radius)),
      );
}
