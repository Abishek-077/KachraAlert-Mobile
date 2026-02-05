import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smart_waste_app/core/extensions/async_value_extensions.dart';

import '../../../../core/ui/snackbar.dart';
import '../../../../core/widgets/k_widgets.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/models/chat_contact.dart';
import '../../data/models/chat_message.dart';
import '../providers/message_providers.dart';

class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  final TextEditingController _composerController = TextEditingController();
  String? _selectedContactId;
  bool _sending = false;
  bool _pollInProgress = false;
  bool _autoSelectScheduled = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _pollTimer = Timer.periodic(const Duration(seconds: 12), (_) async {
      if (!mounted ||
          _selectedContactId == null ||
          _sending ||
          _pollInProgress) {
        return;
      }
      _pollInProgress = true;
      try {
        await ref.read(messageConversationProvider.notifier).refresh();
      } finally {
        _pollInProgress = false;
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _composerController.dispose();
    super.dispose();
  }

  Future<void> _selectContact(ChatContact contact) async {
    if (_selectedContactId == contact.id) return;
    final previousSelectedId = _selectedContactId;
    setState(() => _selectedContactId = contact.id);
    _autoSelectScheduled = false;
    try {
      await ref
          .read(messageConversationProvider.notifier)
          .openConversation(contact.id);
    } catch (e) {
      if (!mounted) return;
      setState(() => _selectedContactId = previousSelectedId);
      _autoSelectScheduled = false;
      AppSnack.show(context, 'Failed to open conversation: $e');
    }
  }

  Future<void> _refreshAll() async {
    await ref.read(messageContactsProvider.notifier).load();
    await ref.read(messageConversationProvider.notifier).refresh();
  }

  Future<void> _send() async {
    if (_sending) return;
    final text = _composerController.text.trim();
    if (text.isEmpty) return;

    setState(() => _sending = true);
    _composerController.clear();
    HapticFeedback.selectionClick();

    try {
      await ref.read(messageConversationProvider.notifier).sendMessage(text);
    } catch (e) {
      if (!mounted) return;
      _composerController.text = text;
      AppSnack.show(context, 'Failed to send message: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _ensureSelectedContact(List<ChatContact> contacts) {
    if (contacts.isEmpty) {
      _autoSelectScheduled = false;
      return;
    }

    final selectedId = _selectedContactId;
    final hasSelected = selectedId != null &&
        contacts.any((contact) => contact.id == selectedId);
    if (hasSelected || _autoSelectScheduled) return;

    _autoSelectScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || contacts.isEmpty) {
        _autoSelectScheduled = false;
        return;
      }
      final selectedId = _selectedContactId;
      final hasSelected = selectedId != null &&
          contacts.any((contact) => contact.id == selectedId);
      if (hasSelected) {
        _autoSelectScheduled = false;
        return;
      }
      unawaited(_selectContact(contacts.first).whenComplete(() {
        _autoSelectScheduled = false;
      }));
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final auth = ref.watch(authStateProvider).valueOrNull;
    final myUserId = auth?.session?.userId ?? '';

    final contactsAsync = ref.watch(messageContactsProvider);
    final conversationAsync = ref.watch(messageConversationProvider);

    final contacts = contactsAsync.valueOrNull ?? const <ChatContact>[];
    _ensureSelectedContact(contacts);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Row(
                children: [
                  const Text(
                    'Messages',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Refresh',
                    onPressed: _refreshAll,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: contactsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: KCard(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 42),
                        const SizedBox(height: 10),
                        const Text(
                          'Could not load contacts',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$e',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: cs.onSurface.withOpacity(0.65)),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () =>
                                ref.read(messageContactsProvider.notifier).load(),
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Retry'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (contacts) {
                  if (contacts.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: KCard(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.forum_outlined,
                              size: 46,
                              color: cs.onSurface.withOpacity(0.6),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'No contacts available',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Residents can message admins and admins can message residents.',
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(color: cs.onSurface.withOpacity(0.65)),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final activeContact = _findSelectedContact(contacts);

                  return Column(
                    children: [
                      SizedBox(
                        height: 84,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (_, i) {
                            final c = contacts[i];
                            final selected = c.id == activeContact?.id;
                            return _ContactChip(
                              contact: c,
                              selected: selected,
                              onTap: () => _selectContact(c),
                            );
                          },
                          separatorBuilder: (_, __) => const SizedBox(width: 10),
                          itemCount: contacts.length,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _ConversationPane(
                          selectedContact: activeContact,
                          conversationAsync: conversationAsync,
                          myUserId: myUserId,
                          onRetry: () => ref
                              .read(messageConversationProvider.notifier)
                              .refresh(),
                        ),
                      ),
                      _ComposerBar(
                        controller: _composerController,
                        enabled: activeContact != null && !_sending,
                        onSend: activeContact == null ? null : _send,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  ChatContact? _findSelectedContact(List<ChatContact> contacts) {
    final selectedId = _selectedContactId;
    if (selectedId == null) return null;
    for (final c in contacts) {
      if (c.id == selectedId) return c;
    }
    return null;
  }
}

class _ContactChip extends StatelessWidget {
  const _ContactChip({
    required this.contact,
    required this.selected,
    required this.onTap,
  });

  final ChatContact contact;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = selected ? cs.primary : cs.surface;
    final fg = selected ? cs.onPrimary : cs.onSurface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 180,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : cs.outlineVariant.withOpacity(0.4),
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: cs.primary.withOpacity(0.24),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: selected
                    ? cs.onPrimary.withOpacity(0.2)
                    : cs.primary.withOpacity(0.12),
                child: Text(
                  contact.name.isEmpty ? 'U' : contact.name[0].toUpperCase(),
                  style: TextStyle(
                    color: selected ? cs.onPrimary : cs.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      contact.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: fg,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      contact.subtitle,
                      style: TextStyle(
                        color: selected
                            ? cs.onPrimary.withOpacity(0.85)
                            : cs.onSurface.withOpacity(0.6),
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConversationPane extends ConsumerWidget {
  const _ConversationPane({
    required this.selectedContact,
    required this.conversationAsync,
    required this.myUserId,
    required this.onRetry,
  });

  final ChatContact? selectedContact;
  final AsyncValue<List<ChatMessage>> conversationAsync;
  final String myUserId;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final activeContact = selectedContact;
    if (activeContact == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
        child: KCard(
          child: Center(
            child: Text(
              'Select a contact to start chatting.',
              style: TextStyle(color: cs.onSurface.withOpacity(0.68)),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: KCard(
        child: conversationAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 42),
              const SizedBox(height: 10),
              const Text(
                'Could not load messages',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                '$e',
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurface.withOpacity(0.65)),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
          data: (messages) {
            if (messages.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 70),
                  Icon(
                    Icons.mark_chat_unread_outlined,
                    size: 42,
                    color: cs.onSurface.withOpacity(0.55),
                  ),
                  const SizedBox(height: 12),
                  const Center(
                    child: Text(
                      'No messages yet',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      'Say hello to ${activeContact.name}.',
                      style: TextStyle(color: cs.onSurface.withOpacity(0.62)),
                    ),
                  ),
                ],
              );
            }

            final ordered = messages.reversed.toList();
            return RefreshIndicator(
              onRefresh: () =>
                  ref.read(messageConversationProvider.notifier).refresh(),
              child: ListView.builder(
                reverse: true,
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: ordered.length,
                itemBuilder: (_, i) {
                  final message = ordered[i];
                  final mine = message.senderId == myUserId;
                  return _MessageBubble(message: message, mine: mine);
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.mine,
  });

  final ChatMessage message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final time = DateFormat('h:mm a').format(message.createdAt.toLocal());

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.68,
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: mine ? cs.primary : cs.surfaceVariant.withOpacity(0.45),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(14),
              topRight: const Radius.circular(14),
              bottomLeft: Radius.circular(mine ? 14 : 4),
              bottomRight: Radius.circular(mine ? 4 : 14),
            ),
          ),
          child: Column(
            crossAxisAlignment:
                mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                message.body,
                style: TextStyle(
                  color: mine ? cs.onPrimary : cs.onSurface,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                time,
                style: TextStyle(
                  color: mine
                      ? cs.onPrimary.withOpacity(0.78)
                      : cs.onSurface.withOpacity(0.56),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComposerBar extends StatelessWidget {
  const _ComposerBar({
    required this.controller,
    required this.enabled,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool enabled;
  final VoidCallback? onSend;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend?.call(),
              decoration: InputDecoration(
                hintText: enabled
                    ? 'Type a message'
                    : 'Select a contact to start chatting',
                filled: true,
                fillColor: cs.surface,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      BorderSide(color: cs.outlineVariant.withOpacity(0.35)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      BorderSide(color: cs.outlineVariant.withOpacity(0.35)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: cs.primary, width: 1.4),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(
            onPressed: enabled ? onSend : null,
            style: FilledButton.styleFrom(
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(14),
            ),
            child: const Icon(Icons.send_rounded),
          ),
        ],
      ),
    );
  }
}
