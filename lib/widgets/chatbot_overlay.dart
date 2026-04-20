import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../app/theme.dart';
import '../mock/mock_data.dart';
import '../services/gemini_service.dart';

class ChatbotOverlay extends StatelessWidget {
  const ChatbotOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'chatbot_fab', 
      onPressed: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (ctx) => const ChatbotScreen(),
        );
      },
      backgroundColor: AppTheme.primary,
      elevation: 4,
      child: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 24),
    );
  }
}

class ChatbotScreen extends ConsumerStatefulWidget {
  const ChatbotScreen({super.key});
  @override
  ConsumerState<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends ConsumerState<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;

  String _buildHospitalContext() {
    final beds = ref.read(bedsProvider);
    final staff = ref.read(staffProvider);
    final alerts = ref.read(alertsProvider);
    final patients = ref.read(patientsProvider);
    
    final availableBeds = beds.where((b) => b.status == 'Available').length;
    final onlineStaff = staff.where((s) => s.available).length;
    final activeAlerts = alerts.where((a) => a.status == 'Active').length;
    final criticalAlerts = alerts.where((a) => a.severity == 'CRITICAL' && a.status == 'Active').length;

    return '''
Beds: ${beds.length} total, 
  $availableBeds available,
  ICU: ${beds.where((b) => b.type=='ICU' && b.status=='Available').length} free,
  General: ${beds.where((b) => b.type=='General' && b.status=='Available').length} free,
  Emergency: ${beds.where((b) => b.type=='Emergency' && b.status=='Available').length} free
Staff: ${staff.length} total, 
  $onlineStaff online,
  Docs available: ${staff.where((s) => s.role=='Doctor' && s.available).length},
  Nurses available: ${staff.where((s) => s.role=='Nurse' && s.available).length}
Alerts: $activeAlerts active ($criticalAlerts critical)
Patients: ${patients.length} total,
  Critical: ${patients.where((p) => p.triageLevel=='CRITICAL').length}
    ''';
  }

  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    
    setState(() {
      _messages.insert(0, {'isUser': true, 'text': text});
      _isTyping = true;
    });
    _controller.clear();

    final response = await GeminiService.chat(
      userMessage: text,
      hospitalContext: _buildHospitalContext()
    );
    
    if (!mounted) return;
    setState(() {
      _isTyping = false;
      _messages.insert(0, {'isUser': false, 'text': response});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(child: _messages.isEmpty ? _buildSuggestions() : _buildChatList()),
          if (_isTyping) 
            const Padding(
              padding: EdgeInsets.all(12), 
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center, 
                children: [
                  SizedBox(height: 12, width: 12, child: CircularProgressIndicator(strokeWidth: 2)), 
                  Gap(12), 
                  Text('Analyzing hospital ops...', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13))
                ]
              )
            ),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: const BoxDecoration(color: AppTheme.surface, border: Border(bottom: BorderSide(color: AppTheme.divider))),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.memory_outlined, color: AppTheme.primaryDark, size: 20),
          ),
          const Gap(12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('RapidCare AI Assistant', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
              Text('Powered by Gemini AI', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
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
          label: Text(t, style: const TextStyle(color: AppTheme.textPrimary)),
          backgroundColor: AppTheme.surface,
          side: const BorderSide(color: AppTheme.divider),
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
              color: isUser ? AppTheme.primary : const Color(0xFFEFF6FF),
              border: isUser ? null : Border.all(color: AppTheme.primaryLight),
              borderRadius: BorderRadius.circular(16).copyWith(
                bottomRight: isUser ? const Radius.circular(0) : null,
                bottomLeft: !isUser ? const Radius.circular(0) : null,
              )
            ),
            child: Text(msg['text'], style: TextStyle(color: isUser ? Colors.white : AppTheme.textPrimary)),
          ),
        );
      },
    );
  }

  Widget _buildInput() {
    return Container(
      color: AppTheme.surface,
      padding: EdgeInsets.only(left: 16, right: 16, top: 12, bottom: MediaQuery.of(context).viewInsets.bottom + 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Enter clinical query...',
                filled: true,
                fillColor: AppTheme.background,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: AppTheme.divider)),
              ),
              onSubmitted: _sendMessage,
            ),
          ),
          const Gap(12),
          CircleAvatar(
            backgroundColor: AppTheme.primary,
            child: IconButton(
              icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
              onPressed: () => _sendMessage(_controller.text),
            ),
          )
        ],
      ),
    );
  }
}
