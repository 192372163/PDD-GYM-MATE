import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:file_picker/file_picker.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/groq_api_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<String>? attachedFileNames;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.attachedFileNames,
  });
}

class AIChatScreen extends StatefulWidget {
  final UserModel? userProfile;
  const AIChatScreen({super.key, this.userProfile});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  final _groqApiService = GroqApiService();
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  UserModel? _userProfile;
  bool _isTyping = false;
  bool _loadingProfile = true;

  // Voice features
  late stt.SpeechToText _speech;
  bool _isListening = false;
  late FlutterTts _flutterTts;
  bool _voiceOutputEnabled = true;

  final List<ChatMessage> _messages = [];
  final List<PlatformFile> _attachedFiles = [];

  final List<Map<String, dynamic>> _quickPrompts = [
    {'label': "Today's Workout Tips", 'icon': Icons.fitness_center, 'color': const Color(0xFF10B981)},
    {'label': 'Create Diet Plan', 'icon': Icons.restaurant, 'color': const Color(0xFF06B6D4)},
    {'label': 'Recovery Exercises', 'icon': Icons.self_improvement, 'color': Colors.purpleAccent},
    {'label': 'Weekly Progress Report', 'icon': Icons.bar_chart, 'color': Colors.orangeAccent},
    {'label': 'Water & Nutrition Tips', 'icon': Icons.local_drink, 'color': Colors.lightBlueAccent},
    {'label': 'Motivate Me!', 'icon': Icons.bolt_rounded, 'color': const Color(0xFFFBBF24)},
  ];

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _speech.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    UserModel? profile = widget.userProfile;
    if (profile == null) {
      final uid = _authService.currentUser?.uid;
      if (uid != null) {
        profile = await _firestoreService.getUserProfile(uid);
      }
    }
    if (mounted) {
      setState(() {
        _userProfile = profile;
        _loadingProfile = false;
        _messages.add(ChatMessage(
          text: _buildGreeting(profile),
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
    }
  }

  String _buildGreeting(UserModel? user) {
    final name = user?.name ?? 'Athlete';
    final goal = user?.fitnessGoal ?? 'Fitness';
    final level = user?.experienceLevel ?? 'Intermediate';
    return "Hello $name! 👋 I'm your GymMate AI Coach — your personal certified Dietitian, Nutritionist & Fitness Trainer.\n\nI know your goal is **$goal** and you're at **$level** level. Ask me anything about workouts, nutrition, recovery, or your progress — I'm here to help you crush your goals! 💪";
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        allowMultiple: true,
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _attachedFiles.addAll(result.files);
        });
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
    }
  }

  void _sendMessage(String text) async {
    if (text.trim().isEmpty && _attachedFiles.isEmpty) return;

    final attachedNames = _attachedFiles.map((f) => f.name).toList();
    final String userText = text.trim().isEmpty
        ? 'Attached file(s): ${attachedNames.join(", ")}'
        : text.trim();

    setState(() {
      _messages.add(ChatMessage(
        text: userText,
        isUser: true,
        timestamp: DateTime.now(),
        attachedFileNames: attachedNames.isNotEmpty ? attachedNames : null,
      ));
      _isTyping = true;
      _attachedFiles.clear();
    });
    _controller.clear();
    _scrollToBottom();

    String promptWithContext = userText;
    if (attachedNames.isNotEmpty) {
      promptWithContext = '[Attached Document/File(s): ${attachedNames.join(", ")}]\n\n$userText';
    }

    final userContext = _userProfile ?? UserModel(uid: '', name: 'Athlete', email: '');
    final response = await _groqApiService.getDietRecommendation(userContext, promptWithContext);

    if (!mounted) return;
    setState(() {
      _isTyping = false;
      _messages.add(ChatMessage(text: response, isUser: false, timestamp: DateTime.now()));
    });
    _scrollToBottom();
    
    if (_voiceOutputEnabled) {
      await _flutterTts.speak(response);
    }
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            setState(() => _isListening = false);
          }
        },
        onError: (val) => setState(() => _isListening = false),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _controller.text = val.recognizedWords;
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF06B6D4)]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('GymMate AI Coach', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                Text(
                  _userProfile != null ? 'Personalized for ${_userProfile!.name}' : 'Your Fitness Assistant',
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
            ),
            child: const Row(
              children: [
                Icon(Icons.circle, color: Color(0xFF10B981), size: 8),
                SizedBox(width: 5),
                Text('Online', style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              _voiceOutputEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
              color: _voiceOutputEnabled ? const Color(0xFF10B981) : const Color(0xFF64748B),
            ),
            onPressed: () {
              setState(() => _voiceOutputEnabled = !_voiceOutputEnabled);
              if (!_voiceOutputEnabled) _flutterTts.stop();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // User goal context banner
          if (_userProfile != null)
            Container(
              margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_outline, color: Color(0xFF64748B), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Goal: ${_userProfile!.fitnessGoal ?? "General Fitness"} · ${_userProfile!.experienceLevel ?? "Intermediate"} · ${_userProfile!.foodPreference ?? "Any"}',
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

          // Quick prompts horizontal scroll
          const SizedBox(height: 8),
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _quickPrompts.length,
              itemBuilder: (context, i) {
                final prompt = _quickPrompts[i];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => _sendMessage(prompt['label'] as String),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: (prompt['color'] as Color).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: (prompt['color'] as Color).withValues(alpha: 0.35)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(prompt['icon'] as IconData, color: prompt['color'] as Color, size: 14),
                          const SizedBox(width: 6),
                          Text(prompt['label'] as String,
                              style: TextStyle(color: prompt['color'] as Color, fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 4),
          const Divider(color: Color(0xFF1E293B), height: 1),

          // Chat messages
          Expanded(
            child: _loadingProfile
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (_isTyping && i == _messages.length) {
                        return _buildTypingIndicator();
                      }
                      return _buildChatBubble(_messages[i]);
                    },
                  ),
          ),

          // Attachment Preview Bar
          if (_attachedFiles.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                border: Border(top: BorderSide(color: Color(0xFF334155), width: 0.5)),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _attachedFiles.map((file) {
                    final ext = file.extension?.toLowerCase() ?? '';
                    final isImg = ['png', 'jpg', 'jpeg', 'gif', 'webp'].contains(ext);
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isImg ? Icons.image_rounded : Icons.insert_drive_file_rounded,
                            color: const Color(0xFF10B981),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            file.name,
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _attachedFiles.remove(file);
                              });
                            },
                            child: const Icon(Icons.cancel, color: Color(0xFF94A3B8), size: 16),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

          // Input area
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
            decoration: const BoxDecoration(
              color: Color(0xFF1E293B),
              border: Border(top: BorderSide(color: Color(0xFF334155), width: 0.5)),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _pickFile,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: const Icon(Icons.add, color: Color(0xFF94A3B8), size: 20),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: Color(0xFFF8FAFC), fontSize: 14),
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: null,
                      decoration: const InputDecoration(
                        hintText: 'Ask your AI Coach anything...',
                        hintStyle: TextStyle(color: Color(0xFF475569), fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onSubmitted: _sendMessage,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _listen,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isListening ? Colors.redAccent : const Color(0xFF1E293B),
                      shape: BoxShape.circle,
                      border: Border.all(color: _isListening ? Colors.redAccent : const Color(0xFF334155)),
                    ),
                    child: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: _isListening ? Colors.white : const Color(0xFF94A3B8),
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _sendMessage(_controller.text),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [Color(0xFF10B981), Color(0xFF06B6D4)]),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage msg) {
    final isUser = msg.isUser;
    final timeStr = '${msg.timestamp.hour}:${msg.timestamp.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isUser)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 24, height: 24,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [Color(0xFF10B981), Color(0xFF06B6D4)]),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 14),
                  ),
                  const SizedBox(width: 6),
                  const Text('GymMate AI', style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) const SizedBox(width: 4),
              Flexible(
                child: Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: isUser
                        ? const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)])
                        : null,
                    color: isUser ? null : const Color(0xFF1E293B),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 18),
                    ),
                    border: isUser ? null : Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Column(
                    crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      if (msg.attachedFileNames != null && msg.attachedFileNames!.isNotEmpty) ...[
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          alignment: isUser ? WrapAlignment.end : WrapAlignment.start,
                          children: msg.attachedFileNames!.map((fileName) {
                            final ext = fileName.split('.').last.toLowerCase();
                            final isImg = ['png', 'jpg', 'jpeg', 'gif', 'webp'].contains(ext);
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black26,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(isImg ? Icons.image_rounded : Icons.description_rounded, color: const Color(0xFF10B981), size: 14),
                                  const SizedBox(width: 6),
                                  Text(
                                    fileName,
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 8),
                      ],
                      Text(
                        msg.text,
                        style: TextStyle(
                          color: isUser ? Colors.white : const Color(0xFFE2E8F0),
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Padding(
            padding: EdgeInsets.only(left: isUser ? 0 : 8, right: isUser ? 4 : 0),
            child: Text(timeStr, style: const TextStyle(color: Color(0xFF475569), fontSize: 10)),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, color: Color(0xFF10B981), size: 14),
            SizedBox(width: 8),
            Text('AI Coach is thinking...', style: TextStyle(color: Color(0xFF94A3B8), fontStyle: FontStyle.italic, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
