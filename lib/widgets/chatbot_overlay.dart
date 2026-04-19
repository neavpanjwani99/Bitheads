import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import '../app/theme.dart';
import '../mock/mock_data.dart';

class ChatbotOverlay extends StatelessWidget {
  const ChatbotOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 24,
      right: 24,
      child: GestureDetector(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (ctx) => const _ChatbotSheet(),
          );
        },
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryDark]),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: AppTheme.primaryDark.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))]
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 30),
        ).animate(onPlay: (c)=>c.repeat(reverse: true)).scale(begin: const Offset(1,1), end: const Offset(1.05, 1.05), duration: 2.seconds),
      ),
    );
  }
}

class _ChatbotSheet extends ConsumerStatefulWidget {
  const _ChatbotSheet();

  @override
  ConsumerState<_ChatbotSheet> createState() => _ChatbotSheetState();
}

class _ChatbotSheetState extends ConsumerState<_ChatbotSheet> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;

  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    
    setState(() {
      _messages.insert(0, {'isUser': true, 'text': text});
      _isTyping = true;
    });
    _controller.clear();

    await Future.delayed(const Duration(milliseconds: 1500));
    
    if (!mounted) return;
    
    String response = _generateResponse(text.toLowerCase());
    
    setState(() {
      _isTyping = false;
      _messages.insert(0, {'isUser': false, 'text': response});
    });
  }

  String _generateResponse(String text) {
    if (text.contains('bed') || text.contains('beds')) {
      final beds = ref.read(bedsProvider);
      final freeIcu = beds.where((b)=>b.type=='ICU' && b.status=='Available').length;
      final freeGen = beds.where((b)=>b.type=='General' && b.status=='Available').length;
      final freeEmr = beds.where((b)=>b.type=='Emergency' && b.status=='Available').length;
      return "Currently ${freeIcu+freeGen+freeEmr} beds available.\nICU: $freeIcu free | General: $freeGen free | Emergency: $freeEmr free";
    }
    
    if (text.contains('doctor') || text.contains('staff') || text.contains('nurse')) {
      final staff = ref.read(staffProvider);
      final online = staff.where((s)=>s.available).toList();
      final docs = online.where((s)=>s.role=='Doctor').length;
      final nurses = online.where((s)=>s.role=='Nurse').length;
      final docNames = online.where((s)=>s.role=='Doctor').map((s)=>s.name).join(', ');
      return "Online staff: ${online.length} total.\nDoctors: $docs available | Nurses: $nurses available\nAvailable Docs: $docNames";
    }
    
    if (text.contains('alert')) {
      final alerts = ref.read(alertsProvider).where((a)=>a.status=='Active').toList();
      final cri = alerts.where((a)=>a.severity=='CRITICAL').length;
      final urg = alerts.where((a)=>a.severity=='URGENT').length;
      return "Active alerts: ${alerts.length}.\nCritical: $cri | Urgent: $urg";
    }

    if (text.contains('queue') || text.contains('patient') || text.contains('triage')) {
      final queue = ref.read(incomingPatientProvider);
      if (queue.isEmpty) return "Patients in queue: 0. All clear.";
      return "Patients in queue: ${queue.length}.\nNext priority: ${queue.first.name} — ${queue.first.vitalsSummary}";
    }
    
    if (text.contains('critical')) {
      final cri = ref.read(alertsProvider).where((a)=>a.severity=='CRITICAL' && a.status=='Active').length;
      return "⚠️ $cri CRITICAL alerts active.\nImmediate attention required.";
    }

    return "I can help with:\n• Bed availability\n• Staff status\n• Active alerts\n• Patient queue\nWhat do you need?";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _messages.isEmpty ? _buildSuggestions() : _buildChatList(),
          ),
          if (_isTyping) const Padding(padding: EdgeInsets.all(8), child: Text('Thinking...', style: TextStyle(color: AppTheme.textSecondary, fontStyle: FontStyle.italic))),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.divider)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.add, color: Colors.white, size: 20),
          ),
          const Gap(12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('RapidCare AI', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('Powered by Gemini', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            ],
          ),
          const Spacer(),
          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    return Center(
      child: Wrap(
        spacing: 8, runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          'Bed availability', 'Staff online', 'Active alerts', 'Patient queue', 'Triage help'
        ].map((t) => ActionChip(
          label: Text(t),
          onPressed: () => _sendMessage(t),
        )).toList(),
      ),
    );
  }

  Widget _buildChatList() {
    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        bool isUser = msg['isUser'];
        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isUser ? AppTheme.primaryDark : const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(16).copyWith(
                bottomRight: isUser ? const Radius.circular(0) : null,
                bottomLeft: !isUser ? const Radius.circular(0) : null,
              )
            ),
            child: Text(msg['text'], style: TextStyle(color: isUser ? Colors.white : AppTheme.textPrimary)),
          ).animate().slideY(begin: 0.2, duration: 300.ms),
        );
      },
    );
  }

  Widget _buildInput() {
    return Container(
      padding: EdgeInsets.only(left: 16, right: 16, top: 12, bottom: MediaQuery.of(context).viewInsets.bottom + 12),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppTheme.divider))),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Ask RapidCare AI...',
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
              ),
              onSubmitted: _sendMessage,
            ),
          ),
          const Gap(8),
          CircleAvatar(
            backgroundColor: AppTheme.primary,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 18),
              onPressed: () => _sendMessage(_controller.text),
            ),
          )
        ],
      ),
    );
  }
}
