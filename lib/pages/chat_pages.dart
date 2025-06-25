import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/message.dart'; // Pastikan path ini benar
import '../services/chat_service.dart'; // Pastikan path ini benar

class ChatPage extends StatefulWidget {
  final int orderId;
  final String recipientName;
  final String? recipientAvatarUrl;

  const ChatPage({
    Key? key,
    required this.orderId,
    required this.recipientName,
    this.recipientAvatarUrl,
  }) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  // --- State Variables ---
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Message> _messages = [];
  Timer? _pollingTimer;
  bool _isLoading = true;

  // Variabel untuk identitas pengguna saat ini
  int? _myId;
  String? _myRole;

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // --- Core Logic Methods ---

  Future<void> _initializePage() async {
    await _loadMyIdentity();
    if (mounted && _myId != null) {
      await _fetchMessages();
      _startPolling();
    }
  }

  Future<void> _loadMyIdentity() async {
    print("_[ChatPage]_: Memuat identitas dari SharedPreferences...");
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();

      // ===================================================================
      // === INI PERUBAHANNYA: Disesuaikan agar cocok dengan AuthService ===
      final role = prefs.getString('role');
      // ===================================================================

      String? idString;

      // Logika ini tetap sama, karena AuthService Anda menyimpan 'porter_id'
      if (role == 'porter') {
        idString = prefs.getString('porter_id');
      } else if (role == 'customer') {
        idString = prefs.getString('customer_id');
      }

      if (idString != null && role != null) {
        if (mounted) {
          setState(() {
            _myId = int.tryParse(idString!);
            _myRole = role;
          });
          print(
            "✅ _[ChatPage]_: Identitas Sukses -> Role: $_myRole, ID: $_myId",
          );
        }
      } else {
        print(
          "❌ _[ChatPage]_: GAGAL memuat identitas. Kunci 'role' atau 'porter_id' tidak ditemukan.",
        );
      }
    } catch (e) {
      print("❌ _[ChatPage]_: Terjadi error saat memuat identitas: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        _fetchMessages(isPolling: true);
      }
    });
  }

  Future<void> _fetchMessages({bool isPolling = false}) async {
    if (!isPolling && mounted) {
      setState(() => _isLoading = true);
    }
    try {
      final newMessages = await ChatService.getMessages(widget.orderId);
      if (mounted && newMessages.length != _messages.length) {
        setState(() {
          _messages = newMessages;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (!isPolling && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat pesan: $e')));
      }
    } finally {
      if (!isPolling && mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    final tempMessage = text;
    _messageController.clear();
    try {
      await ChatService.sendMessage(widget.orderId, tempMessage);
      await _fetchMessages(isPolling: true);
    } catch (e) {
      if (mounted) {
        _messageController.text = tempMessage;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal mengirim: $e')));
      }
    }
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

  // --- UI Builder Methods ---

  // (Seluruh UI di bawah ini tidak ada perubahan, sama seperti sebelumnya)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(),
      body: Column(
        children: [Expanded(child: _buildMessagesList()), _buildMessageInput()],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      elevation: 1,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      title: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage:
                widget.recipientAvatarUrl != null
                    ? AssetImage(widget.recipientAvatarUrl!) as ImageProvider
                    : const AssetImage('assets/avatar.png'),
          ),
          const SizedBox(width: 12),
          Text(
            widget.recipientName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Sen',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF7622)),
      );
    }
    if (_messages.isEmpty) {
      return const Center(
        child: Text(
          'Belum ada pesan.\nMulai percakapan Anda!',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16.0),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final senderId = message.porter?.id ?? message.customer?.id;
        final bool isMe = senderId != null && senderId == _myId;
        return _ChatBubble(message: message, isMe: isMe);
      },
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -2),
            blurRadius: 5,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Ketik pesan...',
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: const Color(0xFFFF7622),
              borderRadius: BorderRadius.circular(30),
              child: InkWell(
                borderRadius: BorderRadius.circular(30),
                onTap: _sendMessage,
                child: const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Icon(Icons.send, color: Colors.white, size: 24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final Message message;
  final bool isMe;

  const _ChatBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFFF7622);
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? primaryColor : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft:
                isMe ? const Radius.circular(20) : const Radius.circular(0),
            bottomRight:
                isMe ? const Radius.circular(0) : const Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 3,
              offset: const Offset(1, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.message,
              style: TextStyle(color: isMe ? Colors.white : Colors.black87),
            ),
            const SizedBox(height: 5),
            Text(
              DateFormat('HH:mm').format(message.createdAt.toLocal()),
              style: TextStyle(
                fontSize: 10,
                color: isMe ? Colors.white70 : Colors.black45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
