import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smart_waste_app/core/localization/app_localizations.dart';
import 'package:smart_waste_app/core/extensions/async_value_extensions.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/ui/snackbar.dart';
import '../../../../core/utils/media_url.dart';
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
  String? _lastFailedContactId;
  bool _sending = false;
  bool _pollInProgress = false;
  bool _autoSelectScheduled = false;
  bool _isAutoSelecting = false;
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
    _isAutoSelecting = true;
    try {
      await ref
          .read(messageConversationProvider.notifier)
          .openConversation(contact.id);
      _lastFailedContactId = null;
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      _lastFailedContactId = contact.id;
      final contacts = ref.read(messageContactsProvider).valueOrNull ?? [];
      final hasPrevious = previousSelectedId != null &&
          contacts.any((contact) => contact.id == previousSelectedId);
      final fallbackSelectedId = hasPrevious ? previousSelectedId : null;
      setState(() => _selectedContactId = fallbackSelectedId);
      _autoSelectScheduled = true;
      AppSnack.show(
        context,
        l10n.choice(
          'Failed to open conversation: $e',
          'कुराकानी खोल्न सकिएन: $e',
        ),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _autoSelectScheduled = false;
      });
      await ref
          .read(messageConversationProvider.notifier)
          .restoreConversation(fallbackSelectedId);
    } finally {
      _isAutoSelecting = false;
    }
  }

  Future<void> _refreshAll() async {
    await ref.read(messageContactsProvider.notifier).load(silent: true);
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
      final l10n = AppLocalizations.of(context);
      _composerController.text = text;
      AppSnack.show(
        context,
        l10n.choice(
          'Failed to send message: $e',
          'सन्देश पठाउन सकिएन: $e',
        ),
      );
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
    if (hasSelected || _autoSelectScheduled || _isAutoSelecting) return;

    // Avoid automatically re-selecting a contact that just failed.
    final firstValidContact = contacts.firstWhere(
      (c) => c.id != _lastFailedContactId,
      orElse: () => contacts.first,
    );

    if (firstValidContact.id == _lastFailedContactId) {
      // If the only contact available is the one that just failed, stop auto-selecting.
      return;
    }

    _autoSelectScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || contacts.isEmpty) {
        _autoSelectScheduled = false;
        return;
      }
      final selectedId = _selectedContactId;
      if (selectedId != null) {
        _autoSelectScheduled = false;
        return;
      }
      unawaited(_selectContact(firstValidContact).whenComplete(() {
        _autoSelectScheduled = false;
      }));
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final auth = ref.watch(authStateProvider).valueOrNull;
    final myUserId = auth?.session?.userId ?? '';
    final myDisplayName = _displayNameFromEmail(
      auth?.session?.email,
      fallback: l10n.choice('You', 'तपाईं'),
    );
    final apiBase = ref.watch(apiBaseUrlProvider);
    final myProfilePhotoUrl =
        resolveMediaUrl(apiBase, auth?.session?.profilePhotoUrl);
    final token = auth?.session?.accessToken;
    final mediaHeaders =
        token?.isNotEmpty == true ? {'Authorization': 'Bearer $token'} : null;
    final isWide = MediaQuery.of(context).size.width >= 900;

    final contactsAsync = ref.watch(messageContactsProvider);
    final conversationAsync = ref.watch(messageConversationProvider);

    final contacts = contactsAsync.valueOrNull ?? const <ChatContact>[];
    if (isWide) {
      _ensureSelectedContact(contacts);
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Row(
                children: [
                  Text(
                    l10n.choice('Messages', 'सन्देशहरू'),
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: l10n.retry,
                    onPressed: _refreshAll,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: contactsAsync.when(
                loading: () {
                  if (contacts.isNotEmpty) {
                    return isWide
                        ? _buildContactsAndPane(
                            contacts,
                            conversationAsync,
                            myUserId,
                            cs,
                            apiBase,
                            mediaHeaders,
                            myDisplayName,
                            myProfilePhotoUrl,
                          )
                        : _buildMobileContactsList(
                            contacts,
                            myUserId,
                            cs,
                            apiBase,
                            mediaHeaders,
                            myDisplayName,
                            myProfilePhotoUrl,
                          );
                  }
                  return const Center(child: CircularProgressIndicator());
                },
                error: (e, _) {
                  if (contacts.isNotEmpty) {
                    return isWide
                        ? _buildContactsAndPane(
                            contacts,
                            conversationAsync,
                            myUserId,
                            cs,
                            apiBase,
                            mediaHeaders,
                            myDisplayName,
                            myProfilePhotoUrl,
                          )
                        : _buildMobileContactsList(
                            contacts,
                            myUserId,
                            cs,
                            apiBase,
                            mediaHeaders,
                            myDisplayName,
                            myProfilePhotoUrl,
                          );
                  }
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: KCard(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline_rounded, size: 42),
                          const SizedBox(height: 10),
                          Text(
                            l10n.choice('Could not load contacts',
                                'सम्पर्कहरू लोड गर्न सकिएन'),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '$e',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: cs.onSurface.withOpacity(0.65),
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: () => ref
                                  .read(messageContactsProvider.notifier)
                                  .load(),
                              icon: const Icon(Icons.refresh_rounded),
                              label: Text(l10n.retry),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                data: (contacts) => isWide
                    ? _buildContactsAndPane(
                        contacts,
                        conversationAsync,
                        myUserId,
                        cs,
                        apiBase,
                        mediaHeaders,
                        myDisplayName,
                        myProfilePhotoUrl,
                      )
                    : _buildMobileContactsList(
                        contacts,
                        myUserId,
                        cs,
                        apiBase,
                        mediaHeaders,
                        myDisplayName,
                        myProfilePhotoUrl,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileContactsList(
    List<ChatContact> contacts,
    String myUserId,
    ColorScheme cs,
    String apiBase,
    Map<String, String>? mediaHeaders,
    String myDisplayName,
    String? myProfilePhotoUrl,
  ) {
    final l10n = AppLocalizations.of(context);
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
              Text(
                l10n.choice('No contacts available', 'कुनै सम्पर्क उपलब्ध छैन'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.choice(
                  'Residents can message admins and admins can message residents.',
                  'बसोबासकर्ताले एडमिनलाई र एडमिनले बसोबासकर्तालाई सन्देश पठाउन सक्छन्।',
                ),
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurface.withOpacity(0.65)),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: KCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.choice('Chats', 'च्याटहरू'),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.choice(
                      '${contacts.length} contacts',
                      '${contacts.length} सम्पर्क',
                    ),
                    style: TextStyle(color: cs.onSurface.withOpacity(0.6)),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: cs.outlineVariant.withOpacity(0.45)),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemBuilder: (_, i) {
                  final c = contacts[i];
                  final selected = _selectedContactId == c.id;
                  return _ContactTile(
                    contact: c,
                    selected: selected,
                    apiBase: apiBase,
                    mediaHeaders: mediaHeaders,
                    onTap: () => _openMobileConversation(
                      c,
                      myUserId,
                      apiBase,
                      mediaHeaders,
                      myDisplayName,
                      myProfilePhotoUrl,
                    ),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemCount: contacts.length,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openMobileConversation(
    ChatContact contact,
    String myUserId,
    String apiBase,
    Map<String, String>? mediaHeaders,
    String myDisplayName,
    String? myProfilePhotoUrl,
  ) async {
    await _selectContact(contact);
    if (!mounted || _selectedContactId != contact.id) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _MobileConversationScreen(
          contact: contact,
          myUserId: myUserId,
          apiBase: apiBase,
          mediaHeaders: mediaHeaders,
          myDisplayName: myDisplayName,
          myProfilePhotoUrl: myProfilePhotoUrl,
        ),
      ),
    );
  }

  Widget _buildContactsAndPane(
    List<ChatContact> contacts,
    AsyncValue<List<ChatMessage>> conversationAsync,
    String myUserId,
    ColorScheme cs,
    String apiBase,
    Map<String, String>? mediaHeaders,
    String myDisplayName,
    String? myProfilePhotoUrl,
  ) {
    final l10n = AppLocalizations.of(context);
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
              Text(
                l10n.choice('No contacts available', 'कुनै सम्पर्क उपलब्ध छैन'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.choice(
                  'Residents can message admins and admins can message residents.',
                  'बसोबासकर्ताले एडमिनलाई र एडमिनले बसोबासकर्तालाई सन्देश पठाउन सक्छन्।',
                ),
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurface.withOpacity(0.65)),
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
                apiBase: apiBase,
                mediaHeaders: mediaHeaders,
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
            apiBase: apiBase,
            mediaHeaders: mediaHeaders,
            myDisplayName: myDisplayName,
            myProfilePhotoUrl: myProfilePhotoUrl,
            onRetry: () =>
                ref.read(messageConversationProvider.notifier).refresh(),
          ),
        ),
        _ComposerBar(
          controller: _composerController,
          enabled: activeContact != null && !_sending,
          onSend: activeContact == null ? null : _send,
          compact: false,
        ),
      ],
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
    required this.apiBase,
    required this.mediaHeaders,
    required this.onTap,
  });

  final ChatContact contact;
  final bool selected;
  final String apiBase;
  final Map<String, String>? mediaHeaders;
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
              _ContactAvatar(
                name: contact.name,
                photoUrl: contact.profileImageUrl,
                apiBase: apiBase,
                headers: mediaHeaders,
                radius: 20,
                backgroundColor: selected
                    ? cs.onPrimary.withOpacity(0.2)
                    : cs.primary.withOpacity(0.12),
                foregroundColor: selected ? cs.onPrimary : cs.primary,
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
    required this.apiBase,
    required this.mediaHeaders,
    required this.myDisplayName,
    required this.myProfilePhotoUrl,
    required this.onRetry,
  });

  final ChatContact? selectedContact;
  final AsyncValue<List<ChatMessage>> conversationAsync;
  final String myUserId;
  final String apiBase;
  final Map<String, String>? mediaHeaders;
  final String myDisplayName;
  final String? myProfilePhotoUrl;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final activeContact = selectedContact;
    if (activeContact == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
        child: KCard(
          child: Center(
            child: Text(
              l10n.choice(
                'Select a contact to start chatting.',
                'च्याट सुरु गर्न सम्पर्क छान्नुहोस्।',
              ),
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
              Text(
                l10n.choice(
                    'Could not load messages', 'सन्देशहरू लोड गर्न सकिएन'),
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
                label: Text(l10n.retry),
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
                  Center(
                    child: Text(
                      l10n.choice('No messages yet', 'अहिलेसम्म सन्देश छैन'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      l10n.choice(
                        'Say hello to ${activeContact.name}.',
                        '${activeContact.name} लाई नमस्ते भन्नुहोस्।',
                      ),
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
                  final senderName = _resolveSenderName(
                    message: message,
                    mine: mine,
                    contact: activeContact,
                    myDisplayName: myDisplayName,
                    unknownUserLabel:
                        l10n.choice('Unknown user', 'अज्ञात प्रयोगकर्ता'),
                  );
                  final senderPhotoUrl = _resolveSenderPhotoUrl(
                    message: message,
                    mine: mine,
                    contact: activeContact,
                    myProfilePhotoUrl: myProfilePhotoUrl,
                  );
                  return _MessageBubble(
                    message: message,
                    mine: mine,
                    senderName: senderName,
                    senderPhotoUrl: senderPhotoUrl,
                    apiBase: apiBase,
                    photoHeaders: mediaHeaders,
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.contact,
    required this.selected,
    required this.apiBase,
    required this.mediaHeaders,
    required this.onTap,
  });

  final ChatContact contact;
  final bool selected;
  final String apiBase;
  final Map<String, String>? mediaHeaders;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = selected ? cs.primary : cs.surface;
    final fg = selected ? cs.onPrimary : cs.onSurface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : cs.outlineVariant.withOpacity(0.4),
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: cs.primary.withOpacity(0.22),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              _ContactAvatar(
                name: contact.name,
                photoUrl: contact.profileImageUrl,
                apiBase: apiBase,
                headers: mediaHeaders,
                radius: 20,
                backgroundColor: selected
                    ? cs.onPrimary.withOpacity(0.2)
                    : cs.primary.withOpacity(0.12),
                foregroundColor: selected ? cs.onPrimary : cs.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: fg,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      contact.subtitle,
                      style: TextStyle(
                        color: selected
                            ? cs.onPrimary.withOpacity(0.85)
                            : cs.onSurface.withOpacity(0.6),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: selected
                    ? cs.onPrimary.withOpacity(0.7)
                    : cs.onSurface.withOpacity(0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileConversationScreen extends ConsumerStatefulWidget {
  const _MobileConversationScreen({
    required this.contact,
    required this.myUserId,
    required this.apiBase,
    required this.mediaHeaders,
    required this.myDisplayName,
    required this.myProfilePhotoUrl,
  });

  final ChatContact contact;
  final String myUserId;
  final String apiBase;
  final Map<String, String>? mediaHeaders;
  final String myDisplayName;
  final String? myProfilePhotoUrl;

  @override
  ConsumerState<_MobileConversationScreen> createState() =>
      _MobileConversationScreenState();
}

class _MobileConversationScreenState
    extends ConsumerState<_MobileConversationScreen> {
  final TextEditingController _composerController = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(messageConversationProvider.notifier)
          .openConversation(widget.contact.id);
    });
  }

  @override
  void dispose() {
    _composerController.dispose();
    super.dispose();
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
      final l10n = AppLocalizations.of(context);
      _composerController.text = text;
      AppSnack.show(
        context,
        l10n.choice(
          'Failed to send message: $e',
          'सन्देश पठाउन सकिएन: $e',
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final conversationAsync = ref.watch(messageConversationProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            _ContactAvatar(
              name: widget.contact.name,
              photoUrl: widget.contact.profileImageUrl,
              apiBase: widget.apiBase,
              headers: widget.mediaHeaders,
              radius: 16,
              backgroundColor: cs.primary.withOpacity(0.12),
              foregroundColor: cs.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.contact.name),
                  Text(
                    widget.contact.subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: AppLocalizations.of(context).retry,
            onPressed: () =>
                ref.read(messageConversationProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _ConversationPane(
              selectedContact: widget.contact,
              conversationAsync: conversationAsync,
              myUserId: widget.myUserId,
              apiBase: widget.apiBase,
              mediaHeaders: widget.mediaHeaders,
              myDisplayName: widget.myDisplayName,
              myProfilePhotoUrl: widget.myProfilePhotoUrl,
              onRetry: () =>
                  ref.read(messageConversationProvider.notifier).refresh(),
            ),
          ),
          _ComposerBar(
            controller: _composerController,
            enabled: !_sending,
            onSend: _send,
            compact: true,
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.mine,
    required this.senderName,
    required this.senderPhotoUrl,
    required this.apiBase,
    required this.photoHeaders,
  });

  final ChatMessage message;
  final bool mine;
  final String senderName;
  final String? senderPhotoUrl;
  final String apiBase;
  final Map<String, String>? photoHeaders;

  String _formatTime(BuildContext context, DateTime value) {
    final local = value.toLocal();
    try {
      final locale = Localizations.localeOf(context).toLanguageTag();
      return DateFormat('h:mm a', locale).format(local);
    } catch (_) {
      final tod = TimeOfDay.fromDateTime(local);
      return MaterialLocalizations.of(context)
          .formatTimeOfDay(tod, alwaysUse24HourFormat: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final time = _formatTime(context, message.createdAt);
    final displayBody = message.isDeleted
        ? l10n.choice(
            'This message was deleted.',
            'यो सन्देश हटाइएको छ।',
          )
        : message.body;
    final bubbleColor = mine ? cs.primary : cs.surfaceVariant.withOpacity(0.48);
    final bodyColor = mine ? cs.onPrimary : cs.onSurface;
    final hasReply = message.replyTo != null;
    final timeLabel = message.editedAt != null && !message.isDeleted
        ? l10n.choice('$time | Edited', '$time | सम्पादन गरिएको')
        : time;

    final bubble = Container(
      margin: const EdgeInsets.only(top: 4, bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bubbleColor,
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
          if (hasReply) ...[
            _ReplyPreview(
              mine: mine,
              senderName: message.replyTo!.senderName,
              body: message.replyTo!.body,
            ),
            const SizedBox(height: 8),
          ],
          Text(
            displayBody.isEmpty
                ? l10n.choice('Message unavailable', 'सन्देश उपलब्ध छैन')
                : displayBody,
            style: TextStyle(
              color: message.isDeleted ? bodyColor.withOpacity(0.8) : bodyColor,
              fontWeight: FontWeight.w600,
              height: 1.3,
              fontStyle:
                  message.isDeleted ? FontStyle.italic : FontStyle.normal,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            timeLabel,
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
    );

    return Row(
      mainAxisAlignment: mine ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!mine) ...[
          _ContactAvatar(
            name: senderName,
            photoUrl: senderPhotoUrl,
            apiBase: apiBase,
            headers: photoHeaders,
            radius: 16,
            backgroundColor: cs.primary.withOpacity(0.12),
            foregroundColor: cs.primary,
          ),
          const SizedBox(width: 8),
        ],
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.66,
          ),
          child: Column(
            crossAxisAlignment:
                mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                senderName,
                style: TextStyle(
                  color: cs.onSurface.withOpacity(0.62),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              bubble,
            ],
          ),
        ),
        if (mine) ...[
          const SizedBox(width: 8),
          _ContactAvatar(
            name: senderName,
            photoUrl: senderPhotoUrl,
            apiBase: apiBase,
            headers: photoHeaders,
            radius: 16,
            backgroundColor: cs.primary.withOpacity(0.12),
            foregroundColor: cs.primary,
          ),
        ],
      ],
    );
  }
}

class _ReplyPreview extends StatelessWidget {
  const _ReplyPreview({
    required this.mine,
    required this.senderName,
    required this.body,
  });

  final bool mine;
  final String senderName;
  final String body;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final safeBody = body.trim().isEmpty
        ? l10n.choice('This message was deleted', 'यो सन्देश हटाइएको छ')
        : body.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: mine
            ? Colors.white.withOpacity(0.15)
            : cs.onSurface.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: mine
              ? Colors.white.withOpacity(0.18)
              : cs.outlineVariant.withOpacity(0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            senderName.trim().isEmpty
                ? l10n.choice('Unknown user', 'अज्ञात प्रयोगकर्ता')
                : senderName,
            style: TextStyle(
              color: mine ? Colors.white : cs.onSurface,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            safeBody,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: mine
                  ? Colors.white.withOpacity(0.92)
                  : cs.onSurface.withOpacity(0.72),
              fontSize: 11,
              fontStyle:
                  body.trim().isEmpty ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactAvatar extends StatelessWidget {
  const _ContactAvatar({
    required this.name,
    required this.photoUrl,
    required this.apiBase,
    required this.headers,
    this.radius = 20,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String name;
  final String? photoUrl;
  final String apiBase;
  final Map<String, String>? headers;
  final double radius;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final resolvedPhotoUrl = resolveMediaUrl(apiBase, photoUrl);
    final fallbackInitial =
        name.trim().isEmpty ? 'U' : name.trim()[0].toUpperCase();

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? cs.primary.withOpacity(0.12),
      foregroundImage: resolvedPhotoUrl == null
          ? null
          : NetworkImage(
              resolvedPhotoUrl,
              headers: headers,
            ),
      child: Text(
        fallbackInitial,
        style: TextStyle(
          color: foregroundColor ?? cs.primary,
          fontWeight: FontWeight.w900,
          fontSize: radius * 0.62,
        ),
      ),
    );
  }
}

String _displayNameFromEmail(String? email, {String fallback = 'You'}) {
  final cleaned = (email ?? '').trim();
  if (cleaned.isEmpty) return fallback;
  final beforeAt = cleaned.split('@').first.trim();
  if (beforeAt.isEmpty) return fallback;
  final display = beforeAt
      .split(RegExp(r'[^a-zA-Z0-9]+'))
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
  return display.isEmpty ? fallback : display;
}

String _resolveSenderName({
  required ChatMessage message,
  required bool mine,
  required ChatContact contact,
  required String myDisplayName,
  required String unknownUserLabel,
}) {
  final sender = message.senderName.trim();
  if (sender.isNotEmpty && sender.toLowerCase() != 'unknown user') {
    return sender;
  }
  if (mine) {
    return myDisplayName.trim().isEmpty ? unknownUserLabel : myDisplayName;
  }
  return contact.name.trim().isEmpty ? unknownUserLabel : contact.name.trim();
}

String? _resolveSenderPhotoUrl({
  required ChatMessage message,
  required bool mine,
  required ChatContact contact,
  required String? myProfilePhotoUrl,
}) {
  final messagePhoto = message.senderProfileImageUrl;
  if (messagePhoto != null && messagePhoto.trim().isNotEmpty) {
    return messagePhoto;
  }
  if (mine) return myProfilePhotoUrl;
  return contact.profileImageUrl;
}

class _ComposerBar extends StatelessWidget {
  const _ComposerBar({
    required this.controller,
    required this.enabled,
    required this.onSend,
    this.compact = true,
  });

  final TextEditingController controller;
  final bool enabled;
  final VoidCallback? onSend;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
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
                    ? l10n.choice('Type a message', 'सन्देश टाइप गर्नुहोस्')
                    : l10n.choice(
                        'Select a contact to start chatting',
                        'च्याट सुरु गर्न सम्पर्क छान्नुहोस्',
                      ),
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
          compact
              ? FilledButton(
                  onPressed: enabled ? onSend : null,
                  style: FilledButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(14),
                  ),
                  child: const Icon(Icons.send_rounded),
                )
              : FilledButton.icon(
                  onPressed: enabled ? onSend : null,
                  icon: const Icon(Icons.send_rounded),
                  label: Text(l10n.choice('Send', 'पठाउनुहोस्')),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
