import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_extension.dart';
import '../models/support_message.dart';
import '../services/support_chat_service.dart';

class _PendingMessage {
  const _PendingMessage({
    required this.id,
    required this.text,
    required this.createdAt,
    this.failed = false,
  });

  final String id;
  final String text;
  final DateTime createdAt;
  final bool failed;

  _PendingMessage copyWith({bool? failed}) {
    return _PendingMessage(
      id: id,
      text: text,
      createdAt: createdAt,
      failed: failed ?? this.failed,
    );
  }
}

class _ChatListItem {
  const _ChatListItem.server(this.message, this.sortTime)
      : pending = null;

  const _ChatListItem.pending(this.pending, this.sortTime) : message = null;

  final SupportMessage? message;
  final _PendingMessage? pending;
  final DateTime sortTime;

  bool get isUser =>
      message?.isFromUser ?? true;

  bool get isPending => pending != null;

  bool get isFailed => pending?.failed ?? false;

  String get text => message?.text ?? pending!.text;

  String? get senderName => message?.senderName;

  DateTime? get createdAt => message?.createdAt ?? pending?.createdAt;
}

class LiveChatScreen extends StatefulWidget {
  const LiveChatScreen({super.key});

  @override
  State<LiveChatScreen> createState() => _LiveChatScreenState();
}

class _LiveChatScreenState extends State<LiveChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocus = FocusNode();
  final List<_PendingMessage> _pendingMessages = [];
  int _lastRenderedCount = 0;

  User? get _user => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final user = _user;
    if (user == null) return;
    try {
      await SupportChatService.instance.ensureConversation(user);
      await SupportChatService.instance.markReadByUser(user.uid);
    } on FirebaseException catch (e) {
      debugPrint('[LiveChat] bootstrap failed: ${e.code} ${e.message}');
    } catch (e) {
      debugPrint('[LiveChat] bootstrap failed: $e');
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  Future<void> _sendMessage([String? presetText]) async {
    final user = _user;
    if (user == null) return;

    final text = (presetText ?? _messageController.text).trim();
    if (text.isEmpty) return;

    if (presetText == null) {
      _messageController.clear();
    }

    final pendingId = DateTime.now().microsecondsSinceEpoch.toString();
    setState(() {
      _pendingMessages.removeWhere((item) => item.failed && item.text == text);
      _pendingMessages.add(
        _PendingMessage(
          id: pendingId,
          text: text,
          createdAt: DateTime.now(),
        ),
      );
    });
    _scrollToBottom();

    try {
      await SupportChatService.instance.sendUserMessage(user: user, text: text);
    } on FirebaseException catch (e) {
      if (!mounted) return;
      debugPrint('[LiveChat] send failed: ${e.code} ${e.message}');
      _markPendingFailed(pendingId);
      _showSendError(_friendlySendError(e));
    } catch (e) {
      if (!mounted) return;
      debugPrint('[LiveChat] send failed: $e');
      _markPendingFailed(pendingId);
      _showSendError(_friendlySendError(e));
    }
  }

  void _markPendingFailed(String pendingId) {
    setState(() {
      final index = _pendingMessages.indexWhere((item) => item.id == pendingId);
      if (index == -1) return;
      _pendingMessages[index] = _pendingMessages[index].copyWith(failed: true);
    });
  }

  void _showSendError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  List<_PendingMessage> _pendingStillNeeded(List<SupportMessage> serverMessages) {
    final serverCounts = <String, int>{};
    for (final message in serverMessages) {
      if (!message.isFromUser) continue;
      serverCounts[message.text] = (serverCounts[message.text] ?? 0) + 1;
    }

    final matched = <String, int>{};
    final kept = <_PendingMessage>[];

    for (final pending in _pendingMessages) {
      if (pending.failed) {
        kept.add(pending);
        continue;
      }

      final used = matched[pending.text] ?? 0;
      final onServer = serverCounts[pending.text] ?? 0;
      if (used < onServer) {
        matched[pending.text] = used + 1;
        continue;
      }
      kept.add(pending);
    }

    return kept;
  }

  void _syncPendingWithServer(List<SupportMessage> serverMessages) {
    final kept = _pendingStillNeeded(serverMessages);
    if (kept.length == _pendingMessages.length) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || kept.length == _pendingMessages.length) return;
      setState(() {
        _pendingMessages
          ..clear()
          ..addAll(kept);
      });
    });
  }

  List<_ChatListItem> _mergeMessages(List<SupportMessage> serverMessages) {
    final visiblePending = _pendingStillNeeded(serverMessages);
    final items = <_ChatListItem>[
      for (final message in serverMessages)
        _ChatListItem.server(
          message,
          message.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
        ),
      for (final pending in visiblePending)
        _ChatListItem.pending(pending, pending.createdAt),
    ]..sort((a, b) => a.sortTime.compareTo(b.sortTime));
    return items;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  String _friendlySendError(Object error) {
    if (error is FirebaseException) {
      if (error.code == 'permission-denied') {
        return 'Chat permissions are updating. Close this screen, reopen Live Chat, and try again.';
      }
      if (error.code == 'unavailable') {
        return 'You appear to be offline. Check your connection and try again.';
      }
    }

    final message = error.toString().toLowerCase();
    if (message.contains('permission') || message.contains('denied')) {
      return 'Chat permissions are updating. Close this screen, reopen Live Chat, and try again.';
    }
    return 'Could not send message. Tap the failed message to retry.';
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final suffix = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    final appTheme = context.appTheme;
    final colorScheme = Theme.of(context).colorScheme;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Live Support')),
        body: const Center(child: Text('Please sign in to use live chat.')),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Live Support',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2E7D32),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Support team online',
                  style: TextStyle(
                    fontSize: 12,
                    color: appTheme.subtitle,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: appTheme.border),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<SupportMessage>>(
              stream: SupportChatService.instance.watchMessages(user.uid),
              builder: (context, snapshot) {
                final serverMessages = snapshot.data ?? const [];
                SupportChatService.instance.markReadByUser(user.uid);
                _syncPendingWithServer(serverMessages);

                final items = _mergeMessages(serverMessages);
                if (items.length > _lastRenderedCount) {
                  _scrollToBottom();
                }
                _lastRenderedCount = items.length;

                if (items.isEmpty) {
                  return _EmptyChatState(appTheme: appTheme);
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _MessageBubble(
                      key: item.message != null
                          ? ValueKey('server_${item.message!.id}')
                          : ValueKey('pending_${item.pending!.id}'),
                      item: item,
                      appTheme: appTheme,
                      formatTime: _formatTime,
                      onRetry: item.isFailed
                          ? () => _sendMessage(item.text)
                          : null,
                    );
                  },
                );
              },
            ),
          ),
          _Composer(
            controller: _messageController,
            focusNode: _inputFocus,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    super.key,
    required this.item,
    required this.appTheme,
    required this.formatTime,
    this.onRetry,
  });

  final _ChatListItem item;
  final AppThemeExtension appTheme;
  final String Function(DateTime? time) formatTime;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final isUser = item.isUser;
    final bubbleColor = isUser ? context.brandBlue : appTheme.sectionBg;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: context.brandBlue.withValues(alpha: 0.12),
              child: Icon(
                Icons.support_agent,
                size: 18,
                color: context.brandBlue,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: GestureDetector(
              onTap: onRetry,
              child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: item.isFailed
                        ? Theme.of(context).colorScheme.error.withValues(alpha: 0.12)
                        : bubbleColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                    border: isUser
                        ? item.isFailed
                            ? Border.all(
                                color: Theme.of(context).colorScheme.error,
                              )
                            : null
                        : Border.all(color: appTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isUser)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            item.senderName ?? 'Support',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: context.brandBlue,
                            ),
                          ),
                        ),
                      Text(
                        item.text,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.35,
                          color: item.isFailed
                              ? Theme.of(context).colorScheme.error
                              : isUser
                                  ? Colors.white
                                  : appTheme.navyText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            formatTime(item.createdAt),
                            style: TextStyle(
                              fontSize: 11,
                              color: item.isFailed
                                  ? Theme.of(context).colorScheme.error
                                  : isUser
                                      ? Colors.white.withValues(alpha: 0.75)
                                      : appTheme.subtitle,
                            ),
                          ),
                          if (item.isFailed) ...[
                            const SizedBox(width: 8),
                            Text(
                              'Tap to retry',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyChatState extends StatelessWidget {
  const _EmptyChatState({required this.appTheme});

  final AppThemeExtension appTheme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 56, color: context.brandBlue),
            const SizedBox(height: 16),
            Text(
              'Start a conversation',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: appTheme.navyText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tell us how we can help. Our support team usually replies within a few hours.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: appTheme.subtitle,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final appTheme = context.appTheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(12, 10, 12, 12 + bottomInset),
      decoration: BoxDecoration(
        color: appTheme.cardSurface,
        border: Border(top: BorderSide(color: appTheme.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: 'Type your message...',
                  filled: true,
                  fillColor: appTheme.searchFill,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: context.brandBlue, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: context.brandBlue,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                onTap: onSend,
                borderRadius: BorderRadius.circular(24),
                child: const SizedBox(
                  width: 48,
                  height: 48,
                  child: Icon(Icons.send_rounded, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
