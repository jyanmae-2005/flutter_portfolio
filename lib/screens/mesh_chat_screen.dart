import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/mesh_chat_provider.dart';
import '../utils/responsive.dart';
import '../widgets/custom_button.dart';

class MeshChatScreen extends StatefulWidget {
  const MeshChatScreen({super.key});

  static const routeName = '/mesh_chat';

  @override
  State<MeshChatScreen> createState() => _MeshChatScreenState();
}

class _MeshChatScreenState extends State<MeshChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<MeshMessage>? _messageSub;
  StreamSubscription<String>? _statusSub;
  StreamSubscription<List<DiscoveredEndpoint>>? _discoveredSub;
  String _connectionStatus = 'Not connected';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<MeshChatProvider>(context, listen: false);
      _messageSub = provider.messageStream.listen((msg) {
        _scrollToBottom();
      });
      _statusSub = provider.connectionStatusStream.listen((status) {
        if (mounted) {
          setState(() => _connectionStatus = status);
        }
      });
      _discoveredSub = provider.discoveredStream.listen((_) {
        if (mounted) setState(() {});
      });
      provider.initialize().then((_) {
        provider.startAdvertising();
        provider.startDiscovery();
      }).catchError((e) {
        if (mounted) {
          setState(() => _connectionStatus = 'Init failed: $e');
        }
      });
    });
  }

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

  @override
  void dispose() {
    _messageSub?.cancel();
    _statusSub?.cancel();
    _discoveredSub?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MeshChatProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Mesh Chat'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: Icon(provider.isAdvertising ? Icons.visibility : Icons.visibility_off),
            onPressed: () {
              if (provider.isAdvertising) {
                provider.stopAdvertising();
              } else {
                provider.startAdvertising();
              }
            },
            tooltip: provider.isAdvertising ? 'Stop Advertising' : 'Start Advertising',
          ),
          IconButton(
            icon: Icon(provider.isDiscovering ? Icons.search : Icons.search_off),
            onPressed: () {
              if (provider.isDiscovering) {
                provider.stopDiscovery();
              } else {
                provider.startDiscovery();
              }
            },
            tooltip: provider.isDiscovering ? 'Stop Discovery' : 'Start Discovery',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear') {
                provider.clearMessages();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'clear', child: Text('Clear Messages')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatusBar(context, provider),
          Expanded(
            child: _buildMessagesList(context, provider),
          ),
          _buildMessageInput(context, provider),
        ],
      ),
    );
  }

  Widget _buildStatusBar(BuildContext context, MeshChatProvider provider) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.horizontalPadding(context),
        vertical: Responsive.padding(context) / 2,
      ),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: provider.connectedEndpointNames.isNotEmpty
                    ? Colors.green
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                child: Text(
                  provider.connectedEndpointNames.length.toString(),
                  style: TextStyle(
                    fontSize: Responsive.fontSizeMultiplier(context) * 10,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
              SizedBox(width: Responsive.padding(context)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'You: ${provider.localName}',
                      style: TextStyle(
                        fontSize: Responsive.fontSizeMultiplier(context) * 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _connectionStatus,
                      style: TextStyle(
                        fontSize: Responsive.fontSizeMultiplier(context) * 11,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              if (provider.discoveredEndpoints.isNotEmpty)
                Text(
                  '${provider.discoveredEndpoints.length} nearby',
                  style: TextStyle(
                    fontSize: Responsive.fontSizeMultiplier(context) * 12,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
            ],
          ),
          if (provider.discoveredEndpoints.isNotEmpty)
            SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: provider.discoveredEndpoints.length,
                itemBuilder: (context, index) {
                  final endpoint = provider.discoveredEndpoints[index];
                  final isConnected = provider.connectedEndpointNames.contains(endpoint.name);
                  return Padding(
                    padding: EdgeInsets.only(right: Responsive.padding(context) / 2),
                    child: ActionChip(
                      label: Text(endpoint.name),
                      avatar: Icon(
                        isConnected ? Icons.link : Icons.bluetooth,
                        size: 16,
                        color: isConnected ? Colors.green : null,
                      ),
                      backgroundColor: isConnected
                          ? Colors.green.withValues(alpha: 0.1)
                          : null,
                      onPressed: isConnected
                          ? () => provider.disconnectFromEndpoint(endpoint.endpointId)
                          : () => provider.connectToEndpoint(endpoint),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(BuildContext context, MeshChatProvider provider) {
    final messages = provider.messages;

    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            SizedBox(height: Responsive.padding(context)),
            Text(
              provider.connectedEndpointNames.isEmpty
                  ? 'Connect to a nearby device to start chatting'
                  : 'No messages yet. Send one!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: Responsive.fontSizeMultiplier(context) * 16,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(Responsive.padding(context)),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return _buildMessageBubble(context, message);
      },
    );
  }

  Widget _buildMessageBubble(BuildContext context, MeshMessage message) {
    final isOwn = message.isOwn;
    final isCompact = Responsive.isCompact(context);
    final bubbleColor = isOwn
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.surfaceContainerHighest;
    final textColor = isOwn
        ? Theme.of(context).colorScheme.onPrimary
        : Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: Responsive.padding(context) / 4),
      child: Row(
        mainAxisAlignment: isOwn ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isOwn)
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                message.senderName.isNotEmpty ? message.senderName[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: Responsive.fontSizeMultiplier(context) * 12,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          if (!isOwn) SizedBox(width: Responsive.padding(context) / 2),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: isCompact
                    ? MediaQuery.of(context).size.width * 0.75
                    : MediaQuery.of(context).size.width * 0.6,
              ),
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.padding(context),
                vertical: Responsive.padding(context) / 2,
              ),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isOwn ? const Radius.circular(16) : Radius.zero,
                  bottomRight: isOwn ? Radius.zero : const Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (!isOwn)
                    Text(
                      message.senderName,
                      style: TextStyle(
                        fontSize: Responsive.fontSizeMultiplier(context) * 11,
                        fontWeight: FontWeight.w600,
                        color: textColor.withValues(alpha: 0.8),
                      ),
                    ),
                  if (!isOwn) SizedBox(height: 4),
                  Text(
                    message.text,
                    style: TextStyle(
                      fontSize: Responsive.fontSizeMultiplier(context) * 14,
                      color: textColor,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      fontSize: Responsive.fontSizeMultiplier(context) * 10,
                      color: textColor.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isOwn) SizedBox(width: Responsive.padding(context) / 2),
          if (isOwn)
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.person,
                size: 16,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageInput(BuildContext context, MeshChatProvider provider) {
    final canSend = provider.connectedEndpointNames.isNotEmpty;

    return Container(
      padding: EdgeInsets.all(Responsive.padding(context)),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              enabled: canSend,
              maxLines: null,
              decoration: InputDecoration(
                hintText: canSend ? 'Type a message...' : 'Connect to a device first',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: Responsive.padding(context),
                  vertical: Responsive.padding(context) / 2,
                ),
              ),
              onSubmitted: (_) => _sendMessage(provider),
            ),
          ),
          SizedBox(width: Responsive.padding(context) / 2),
          CustomButton(
            label: 'Send',
            icon: Icons.send,
            onPressed: canSend ? () => _sendMessage(provider) : null,
          ),
        ],
      ),
    );
  }

  void _sendMessage(MeshChatProvider provider) {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      provider.sendMessage(text);
      _messageController.clear();
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inDays > 0) {
      return '${time.day}/${time.month} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}