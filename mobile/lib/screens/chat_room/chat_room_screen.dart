import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../models/task.dart';
import '../../services/api_service.dart';

class ChatMessage {
  final String id;
  final String role; // 'user' | 'assistant'
  final String text;
  final DateTime timestamp;
  final String? toneUsed;
  final String? moodDetected;
  final List<Task> extractedTasks;
  final bool isError;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.timestamp,
    this.toneUsed,
    this.moodDetected,
    this.extractedTasks = const [],
    this.isError = false,
  });
}

class ChatRoomScreen extends StatefulWidget {
  final bool isDarkMode;
  final String? initialPrompt;
  final ApiService? apiService;
  final VoidCallback? onTasksCreated;

  const ChatRoomScreen({
    super.key,
    required this.isDarkMode,
    this.initialPrompt,
    this.apiService,
    this.onTasksCreated,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isAiTyping = false;
  String _activeTone = 'HONEST';

  late final List<ChatMessage> _messages;

  final List<String> _quickPrompts = [
    '🧠 Brain-dump tugas baru',
    '⚡ Cek sisa kapasitas hari ini',
    '💭 Aku merasa overwhelmed',
    '📅 Apa prioritas hari ini?',
  ];

  @override
  void initState() {
    super.initState();
    _messages = [
      ChatMessage(
        id: 'msg-0',
        role: 'assistant',
        text: 'Halo. Ini ruang refleksi dan brain-dump kapasitas harianmu.\n\n'
            'Tuliskan tugas yang ingin kamu selesaikan, ceritakan hal yang membebanimu, '
            'atau tanyakan "Masih bisa ngerjain apa hari ini?"',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        toneUsed: 'HONEST',
      ),
    ];

    if (widget.initialPrompt != null && widget.initialPrompt!.trim().isNotEmpty) {
      _messageController.text = widget.initialPrompt!;
    }

    _loadRemoteHistory();
  }

  Future<void> _loadRemoteHistory() async {
    if (widget.apiService == null) return;
    try {
      final history = await widget.apiService!.fetchChatHistory();
      if (history.isNotEmpty && mounted) {
        setState(() {
          _messages.clear();
          for (final h in history) {
            _messages.add(
              ChatMessage(
                id: h.id,
                role: h.role == 'ai' ? 'assistant' : 'user',
                text: h.content,
                timestamp: h.createdAt,
                toneUsed: h.toneUsed,
                moodDetected: h.moodDetected,
              ),
            );
          }
          if (history.last.toneUsed != null) {
            _activeTone = history.last.toneUsed!;
          }
        });
        _scrollToBottom();
      }
    } catch (_) {
      // Keep default welcome message if fetching history fails
    }
  }

  @override
  void didUpdateWidget(covariant ChatRoomScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialPrompt != null &&
        widget.initialPrompt != oldWidget.initialPrompt &&
        widget.initialPrompt!.trim().isNotEmpty) {
      _messageController.text = widget.initialPrompt!;
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
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

  Future<void> _handleSendMessage([String? overrideText]) async {
    final text = (overrideText ?? _messageController.text).trim();
    if (text.isEmpty) return;

    final userMsg = ChatMessage(
      id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
      role: 'user',
      text: text,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMsg);
      _messageController.clear();
      _isAiTyping = true;
    });
    _scrollToBottom();

    // 1. Live API call if ApiService is provided
    if (widget.apiService != null) {
      try {
        final response = await widget.apiService!.sendChatMessage(text);
        if (!mounted) return;

        setState(() {
          _isAiTyping = false;
          _activeTone = response.toneUsed;
          _messages.add(
            ChatMessage(
              id: 'msg-ai-${DateTime.now().millisecondsSinceEpoch}',
              role: 'assistant',
              text: response.reply,
              timestamp: DateTime.now(),
              toneUsed: response.toneUsed,
              moodDetected: response.moodDetected,
              extractedTasks: response.extractedTasks,
            ),
          );
        });

        if (response.extractedTasks.isNotEmpty) {
          widget.onTasksCreated?.call();
        }

        _scrollToBottom();
        return;
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isAiTyping = false;
          _messages.add(
            ChatMessage(
              id: 'msg-err-${DateTime.now().millisecondsSinceEpoch}',
              role: 'assistant',
              text: 'Koneksi ke AI Companion mengalami gangguan atau batas waktu Vercel (10s) terlampaui. Silakan coba kembali.',
              timestamp: DateTime.now(),
              isError: true,
            ),
          );
        });
        _scrollToBottom();
        return;
      }
    }

    // 2. Fallback simulation (offline / test shell)
    Timer(const Duration(milliseconds: 600), () {
      if (!mounted) return;

      final lowerText = text.toLowerCase();
      String responseText;
      String tone = 'HONEST';
      List<Task> mockTasks = [];

      if (lowerText.contains('overwhelmed') ||
          lowerText.contains('capek') ||
          lowerText.contains('lelah') ||
          lowerText.contains('pusing')) {
        tone = 'GENTLE';
        responseText =
            'Wajar jika merasa overload. Ingat prinsip ALUR: kapasitas harianmu '
            'bukan apa yang kamu harapkan, tapi apa yang realistis untuk tubuh dan pikiranmu. '
            'Mari kita pilah 1 tugas terpenting saja untuk hari ini, sisanya kita geser.';
      } else if (lowerText.contains('kapasitas') || lowerText.contains('sisa')) {
        responseText =
            'Berdasarkan alokasi tugas harianmu hari ini (target 8 jam), '
            'kamu telah menjadwalkan sekitar 3.5 jam. Masih tersisa waktu untuk 1 blok fokus sedang '
            'atau istirahat berkualitas.';
      } else if (lowerText.contains('brain-dump') ||
          lowerText.contains('tugas') ||
          lowerText.contains('besok') ||
          lowerText.contains('meeting') ||
          lowerText.contains('beli') ||
          lowerText.contains('kerjakan')) {
        responseText =
            'Saya menangkap tugas dari brain-dump kamu. Tugas ini telah diekstrak '
            'dan dijadwalkan secara realistis ke dalam To-do mingguanmu.';
        mockTasks = [
          Task(
            id: 'mock-t-${DateTime.now().millisecondsSinceEpoch}',
            userId: '00000000-0000-0000-0000-000000000001',
            title: text,
            assignedDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
            status: 'PENDING',
            source: 'CHAT_ROOM',
            isAmbiguous: false,
            aiGenerated: true,
            missedFollowUp: 'NONE',
          ),
        ];
      } else {
        responseText =
            'Dicatat dalam log refleksi. Tetap jaga fokus pada satu hal dalam satu waktu '
            'agar kapasitas harianmu tidak terkuras.';
      }

      final aiMsg = ChatMessage(
        id: 'msg-ai-${DateTime.now().millisecondsSinceEpoch}',
        role: 'assistant',
        text: responseText,
        timestamp: DateTime.now(),
        toneUsed: tone,
        extractedTasks: mockTasks,
      );

      setState(() {
        _isAiTyping = false;
        _activeTone = tone;
        _messages.add(aiMsg);
      });

      if (mockTasks.isNotEmpty) {
        widget.onTasksCreated?.call();
      }

      _scrollToBottom();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.charcoal;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.warmGray;
    final backgroundColor = isDark ? AppColors.darkBackground : AppColors.warmOffWhite;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.paperGray;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.hairlineGray;

    final toneLabel = _activeTone == 'GENTLE' ? 'Gentle Mode' : 'Honest Mode';

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CHAT ROOM',
              style: GoogleFonts.inter(
                letterSpacing: 2.0,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: primaryTextColor,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _activeTone == 'GENTLE'
                        ? const Color(0xFF6B9080)
                        : (isDark ? AppColors.darkActiveAccent : AppColors.inkBlack),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Capacity Companion • $toneLabel',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: secondaryTextColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Chat message history
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isUser = msg.role == 'user';
                  final timeFormatted = DateFormat('HH:mm').format(msg.timestamp);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Column(
                      crossAxisAlignment:
                          isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        // Bubble container
                        Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.85,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isUser
                                ? surfaceColor
                                : (isDark
                                    ? AppColors.darkSurface.withAlpha(160)
                                    : AppColors.warmOffWhite),
                            borderRadius: BorderRadius.circular(8),
                            border: isUser
                                ? null
                                : Border.all(
                                    color: msg.isError
                                        ? Colors.red.withAlpha(120)
                                        : borderColor,
                                    width: 1,
                                  ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                msg.text,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  height: 1.45,
                                  fontWeight: FontWeight.w400,
                                  color: msg.isError ? Colors.redAccent : primaryTextColor,
                                ),
                              ),
                              if (msg.extractedTasks.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: surfaceColor,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: borderColor, width: 0.8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'TUGAS TERSINKRONKAN:',
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.5,
                                          color: secondaryTextColor,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      ...msg.extractedTasks.map((t) => Padding(
                                            padding: const EdgeInsets.only(bottom: 4),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.check_circle_outline_rounded,
                                                  size: 13,
                                                  color: primaryTextColor,
                                                ),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    '${t.title} (${t.assignedDate})',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w500,
                                                      color: primaryTextColor,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Timestamp / Sender Tag
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isUser
                                    ? 'You • $timeFormatted'
                                    : 'Companion${msg.toneUsed != null ? ' (${msg.toneUsed})' : ''} • $timeFormatted',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: secondaryTextColor,
                                ),
                              ),
                              if (msg.isError) ...[
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () => _handleSendMessage(),
                                  child: Text(
                                    'Coba lagi',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? AppColors.darkActiveAccent : AppColors.inkBlack,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // AI Typing Indicator
            if (_isAiTyping)
              Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.8,
                        color: secondaryTextColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Companion sedang memikirkan respons...',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),

            // Quick Prompt Chips
            Container(
              height: 38,
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _quickPrompts.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final prompt = _quickPrompts[index];
                  return ActionChip(
                    backgroundColor: surfaceColor,
                    side: BorderSide(color: borderColor, width: 0.8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    label: Text(
                      prompt,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: primaryTextColor,
                      ),
                    ),
                    onPressed: () {
                      _handleSendMessage(prompt);
                    },
                  );
                },
              ),
            ),

            // Bottom text input area
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: surfaceColor,
                border: Border(
                  top: BorderSide(color: borderColor, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: primaryTextColor,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Ketik ide, tugas, atau curhat...',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 14,
                          color: secondaryTextColor,
                        ),
                        isDense: true,
                        filled: true,
                        fillColor: backgroundColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: isDark ? AppColors.darkActiveAccent : AppColors.inkBlack,
                            width: 1.2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      onSubmitted: (_) => _handleSendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: isDark ? AppColors.darkActiveAccent : AppColors.inkBlack,
                      foregroundColor: isDark ? Colors.black : Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.all(12),
                    ),
                    icon: const Icon(Icons.arrow_upward_rounded, size: 20),
                    onPressed: () => _handleSendMessage(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
