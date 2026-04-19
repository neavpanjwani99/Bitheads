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
      onPressed: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (ctx) => const _ChatbotSheet(),
        );
      },
      backgroundColor: AppTheme.primary,
      elevation: 4,
      child: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 24),
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

    // Build context string from providers
    final beds = ref.read(bedsProvider);
    final staff = ref.read(staffProvider);
    final alerts = ref.read(alertsProvider);
    final patients = ref.read(patientsProvider);
    
    int totBeds = beds.length;
    int avBeds = beds.where((b)=>b.status=='Available').length;
    int avIcu = beds.where((b)=>b.status=='Available' && b.type=='ICU').length;
    int avGen = beds.where((b)=>b.status=='Available' && b.type=='General').length;
    int avEmr = beds.where((b)=>b.status=='Available' && b.type=='Emergency').length;
    
    int onS = staff.where((s)=>s.available).length;
    int onD = staff.where((s)=>s.role=='Doctor' && s.available).length;
    int onN = staff.where((s)=>s.role=='Nurse' && s.available).length;
    
    int actA = alerts.where((a)=>a.status=='Active').length;
    int criA = alerts.where((a)=>a.status=='Active' && a.severity=='CRITICAL').length;
    int urgA = alerts.where((a)=>a.status=='Active' && a.severity=='URGENT').length;
    
    int pTot = patients.length;
    int pCri = patients.where((p)=>p.triageLevel=='CRITICAL').length;

    String prompt = '''
Hospital data: 
Beds: $totBeds total, $avBeds available (ICU:$avIcu General:$avGen Emergency:$avEmr)
Staff: $onS online, $onD doctors available, $onN nurses available  
Alerts: $actA active ($criA critical, $urgA urgent)
Patients: $pTot total, $pCri critical
User question: $text
Answer briefly, concisely and professionally as a hospital AI assistant.
''';
    
    String response = await GeminiService.generateResponse(prompt);
    
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
          Expanded(
            child: _messages.isEmpty ? _buildSuggestions() : _buildChatList(),
          ),
          if (_isTyping) const Padding(padding: EdgeInsets.all(8), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [SizedBox(height: 16, width:16, child: CircularProgressIndicator(strokeWidth: 2)), Gap(12), Text('AI processing...', style: TextStyle(color: AppTheme.textSecondary))])),
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
              Text('RapidCare AI', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
              Text('Powered by Gemini-1.5-Flash', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
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
          'Bed availability', 'Staff online', 'Active alerts', 'Patient triage status'
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
              color: isUser ? AppTheme.primary : AppTheme.surface,
              border: isUser ? null : Border.all(color: AppTheme.divider),
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
