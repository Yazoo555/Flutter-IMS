import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';
import '../../main.dart';

// ─── Data Model ───────────────────────────────────────────────────────────────

class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final MessageStatus status;

  ChatMessage({
    String? id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.status = MessageStatus.sent,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  Map<String, String> toHistoryJson() => {
        'role': isUser ? 'user' : 'assistant',
        'content': content,
      };

  ChatMessage copyWith({MessageStatus? status}) => ChatMessage(
        id: id,
        content: content,
        isUser: isUser,
        timestamp: timestamp,
        status: status ?? this.status,
      );
}

enum MessageStatus { sending, sent, error }

// ─── Suggestion Model ─────────────────────────────────────────────────────────

class _Suggestion {
  final String text;
  final IconData icon;
  const _Suggestion(this.text, this.icon);
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _showScrollFab = false;
  late AnimationController _fabAnimController;

  static const _supabaseUrl =
      'https://zinognrruckgcmrxgzro.supabase.co/functions/v1/chat-ai';

  final List<_Suggestion> _suggestions = const [
    _Suggestion("What items are low on stock?", Icons.warning_amber_rounded),
    _Suggestion("Give me a full inventory report", Icons.inventory_2_rounded),
    _Suggestion("What's my total inventory value?", Icons.monetization_on_rounded),
    _Suggestion("Recent stock movements", Icons.swap_vert_rounded),
    _Suggestion("Which items are out of stock?", Icons.remove_shopping_cart_rounded),
    _Suggestion("Show my profit margins", Icons.trending_up_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _fabAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _fabAnimController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final atBottom = _scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 80;
    if (!atBottom && !_showScrollFab) {
      setState(() => _showScrollFab = true);
      _fabAnimController.forward();
    } else if (atBottom && _showScrollFab) {
      _fabAnimController.reverse().then((_) {
        if (mounted) setState(() => _showScrollFab = false);
      });
    }
  }

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      if (animated) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      } else {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isLoading) return;

    HapticFeedback.lightImpact();

    final userMsg = ChatMessage(
      content: trimmed,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMsg);
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final userId = supabase.auth.currentUser!.id;
      final history = _messages
          .take(_messages.length - 1)
          .map((m) => m.toHistoryJson())
          .toList();

      final response = await http
          .post(
            Uri.parse(_supabaseUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $supabaseAnonKey',
            },
            body: jsonEncode({
              'message': trimmed,
              'user_id': userId,
              if (history.isNotEmpty) 'history': history,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = data['reply'] ?? "I couldn't process that request.";
        setState(() {
          _messages.add(ChatMessage(
            content: reply,
            isUser: false,
            timestamp: DateTime.now(),
          ));
          _isLoading = false;
        });
      } else {
        throw Exception('Error ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(
          content:
              "⚠️ Couldn't reach the AI assistant. Please check your connection and try again.",
          isUser: false,
          timestamp: DateTime.now(),
          status: MessageStatus.error,
        ));
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }

  void _copyMessage(String content) {
    Clipboard.setData(ClipboardData(text: content));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Message copied'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.darkBackground : AppTheme.background;
    final surface = Theme.of(context).cardColor;
    final primary = AppTheme.primary;

    return Scaffold(
      backgroundColor: bg,
      appBar: _buildAppBar(isDark, surface, primary),
      body: Stack(
        children: [
          Column(
            children: [
              _buildStatusBar(isDark, primary),
              Expanded(
                child: _messages.isEmpty
                    ? _buildWelcome(isDark)
                    : _buildMessageList(isDark),
              ),
              _buildInputBar(isDark, surface, primary),
            ],
          ),
          // Scroll to bottom FAB
          if (_showScrollFab)
            Positioned(
              bottom: 90,
              right: 16,
              child: ScaleTransition(
                scale: CurvedAnimation(
                  parent: _fabAnimController,
                  curve: Curves.elasticOut,
                ),
                child: GestureDetector(
                  onTap: () => _scrollToBottom(),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primary.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
      bool isDark, Color surface, Color primary) {
    final textPrimary =
        isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;

    return AppBar(
      backgroundColor: surface,
      elevation: 0,
      titleSpacing: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded,
            color: textPrimary, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          // AI avatar
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primary, primary.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "AI Assistant",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF22C55E),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    "LLaMA 3 · Online",
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      actions: [
        if (_messages.isNotEmpty)
          IconButton(
            icon: Icon(Icons.delete_sweep_rounded,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.textSecondary,
                size: 22),
            onPressed: _confirmClearChat,
            tooltip: 'Clear chat',
          ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(
          height: 1,
          color: isDark ? AppTheme.darkBorder : AppTheme.border,
        ),
      ),
    );
  }

  Widget _buildStatusBar(bool isDark, Color primary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: primary.withOpacity(0.06),
      child: Row(
        children: [
          Icon(Icons.inventory_2_outlined, size: 14, color: primary),
          const SizedBox(width: 6),
          Text(
            "Connected to your live inventory data",
            style: TextStyle(
              fontSize: 12,
              color: primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Icon(Icons.shield_outlined, size: 13, color: primary.withOpacity(0.7)),
          const SizedBox(width: 4),
          Text(
            "Secure",
            style: TextStyle(
              fontSize: 11,
              color: primary.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Welcome / Empty State ──────────────────────────────────────────────────

  Widget _buildWelcome(bool isDark) {
    final textPrimary =
        isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final textSecondary =
        isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
    final primary = AppTheme.primary;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
      child: Column(
        children: [
          // Hero icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primary, primary.withOpacity(0.6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: primary.withOpacity(0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 38,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Your Inventory AI",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "I have real-time access to your stock levels,\ncategories, movements, and financials.",
            style: TextStyle(
              fontSize: 14,
              color: textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Capability cards
          Row(
            children: [
              _capabilityCard(
                  isDark, Icons.inventory_rounded, "Stock", "Live data"),
              const SizedBox(width: 10),
              _capabilityCard(
                  isDark, Icons.trending_up_rounded, "Financials", "P&L info"),
              const SizedBox(width: 10),
              _capabilityCard(
                  isDark, Icons.swap_vert_rounded, "Movements", "Audit trail"),
            ],
          ),
          const SizedBox(height: 28),

          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Try asking",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Suggestion chips
          ..._suggestions.map((s) => _suggestionRow(s, isDark)),
        ],
      ),
    );
  }

  Widget _capabilityCard(
      bool isDark, IconData icon, String title, String sub) {
    final primary = AppTheme.primary;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: primary.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: primary.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, color: primary, size: 22),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
              ),
            ),
            Text(
              sub,
              style: TextStyle(
                fontSize: 10,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _suggestionRow(_Suggestion s, bool isDark) {
    final primary = AppTheme.primary;
    return GestureDetector(
      onTap: () => _sendMessage(s.text),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isDark ? AppTheme.darkBorder : AppTheme.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(s.icon, color: primary, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                s.text,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color:
                      isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 13,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Message List ───────────────────────────────────────────────────────────

  Widget _buildMessageList(bool isDark) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: _messages.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length) return _buildTypingBubble(isDark);
        final msg = _messages[index];
        final showDate = index == 0 ||
            !_isSameDay(_messages[index - 1].timestamp, msg.timestamp);
        return Column(
          children: [
            if (showDate) _buildDateChip(msg.timestamp, isDark),
            _buildBubble(msg, isDark),
          ],
        );
      },
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Widget _buildDateChip(DateTime dt, bool isDark) {
    final now = DateTime.now();
    String label;
    if (_isSameDay(dt, now)) {
      label = 'Today';
    } else if (_isSameDay(dt, now.subtract(const Duration(days: 1)))) {
      label = 'Yesterday';
    } else {
      label = DateFormat('MMM d, yyyy').format(dt);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.07)
                : Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBubble(ChatMessage msg, bool isDark) {
    final isUser = msg.isUser;
    final primary = AppTheme.primary;
    final isError = msg.status == MessageStatus.error;

    return GestureDetector(
      onLongPress: () => _copyMessage(msg.content),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Row(
          mainAxisAlignment:
              isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // AI avatar dot
            if (!isUser) ...[
              Container(
                width: 28,
                height: 28,
                margin: const EdgeInsets.only(right: 8, bottom: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primary, primary.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.auto_awesome_rounded,
                    color: Colors.white, size: 14),
              ),
            ],

            // Bubble
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: isUser
                    ? primary
                    : isError
                        ? (isDark
                            ? const Color(0xFF3D1A1A)
                            : const Color(0xFFFFF0F0))
                        : (isDark ? AppTheme.darkSurface : Colors.white),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                border: isUser
                    ? null
                    : Border.all(
                        color: isError
                            ? Colors.red.withOpacity(0.3)
                            : (isDark
                                ? AppTheme.darkBorder
                                : Colors.black.withOpacity(0.06)),
                        width: 1,
                      ),
                boxShadow: [
                  BoxShadow(
                    color: isUser
                        ? primary.withOpacity(0.25)
                        : Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    msg.content,
                    style: TextStyle(
                      color: isUser
                          ? Colors.white
                          : isError
                              ? Colors.red
                              : (isDark
                                  ? AppTheme.darkTextPrimary
                                  : AppTheme.textPrimary),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('HH:mm').format(msg.timestamp),
                        style: TextStyle(
                          color: isUser
                              ? Colors.white.withOpacity(0.65)
                              : (isDark
                                  ? AppTheme.darkTextSecondary
                                  : AppTheme.textSecondary),
                          fontSize: 10,
                        ),
                      ),
                      if (!isUser) ...[
                        const SizedBox(width: 6),
                        Icon(
                          Icons.copy_rounded,
                          size: 10,
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.textSecondary,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingBubble(bool isDark) {
    final primary = AppTheme.primary;
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(right: 8, bottom: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primary, primary.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 14),
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
              border: Border.all(
                color: isDark
                    ? AppTheme.darkBorder
                    : Colors.black.withOpacity(0.06),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                3,
                (i) => _AnimatedDot(index: i, color: primary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Input Bar ──────────────────────────────────────────────────────────────

  Widget _buildInputBar(bool isDark, Color surface, Color primary) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: surface,
        border: Border(
          top: BorderSide(
            color: isDark ? AppTheme.darkBorder : AppTheme.border,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Text field
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.darkInputBackground
                      : AppTheme.inputBackground,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isDark ? AppTheme.darkBorder : AppTheme.border,
                  ),
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.textPrimary,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: "Ask about your inventory...",
                    hintStyle: const TextStyle(
                        color: AppTheme.textHint, fontSize: 14),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 11),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  onSubmitted: (v) => _sendMessage(v),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Send button
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _isLoading
                    ? (isDark ? AppTheme.darkBorder : AppTheme.border)
                    : primary,
                shape: BoxShape.circle,
                boxShadow: _isLoading
                    ? []
                    : [
                        BoxShadow(
                          color: primary.withOpacity(0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: _isLoading
                      ? null
                      : () => _sendMessage(_controller.text),
                  child: Center(
                    child: _isLoading
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: isDark
                                  ? AppTheme.darkTextSecondary
                                  : AppTheme.textSecondary,
                            ),
                          )
                        : const Icon(Icons.send_rounded,
                            color: Colors.white, size: 20),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  void _confirmClearChat() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text("Clear chat?"),
        content: const Text(
            "This will remove all messages from this session."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _messages.clear());
            },
            child: Text("Clear",
                style: TextStyle(color: AppTheme.primary)),
          ),
        ],
      ),
    );
  }
}

// ─── Animated Typing Dot ──────────────────────────────────────────────────────

class _AnimatedDot extends StatefulWidget {
  final int index;
  final Color color;
  const _AnimatedDot({required this.index, required this.color});

  @override
  State<_AnimatedDot> createState() => _AnimatedDotState();
}

class _AnimatedDotState extends State<_AnimatedDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _anim = CurvedAnimation(
      parent: _ctrl,
      curve: Interval(
        widget.index * 0.2,
        widget.index * 0.2 + 0.6,
        curve: Curves.easeInOut,
      ),
    );

    // Stagger start
    Future.delayed(Duration(milliseconds: widget.index * 150), () {
      if (mounted) _ctrl.forward();
    });
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
      builder: (_, __) => Container(
        width: 7,
        height: 7,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: widget.color.withOpacity(0.3 + _anim.value * 0.7),
          shape: BoxShape.circle,
        ),
        transform: Matrix4.translationValues(0, -4 * _anim.value, 0),
      ),
    );
  }
}