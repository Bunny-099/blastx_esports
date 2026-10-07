import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';

/// ============================================================
/// FAQ SCREEN — BLASTIX ARENA HELP & SUPPORT HUB
/// ============================================================

class FaqItem {
  final String id;
  final String question;
  final String answer;

  const FaqItem({
    required this.id,
    required this.question,
    required this.answer,
  });
}

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int? _expandedIndex;

  static const List<FaqItem> _faqs = [
    FaqItem(
      id: '01',
      question: 'What is Blastix Arena?',
      answer:
          'Blastix Arena is an esports platform built for gamers. You can discover and participate in tournaments, follow live esports events, watch matches, and manage your gaming profile — all in one place.',
    ),
    FaqItem(
      id: '02',
      question: 'Is Blastix Arena free to use?',
      answer:
          'Yes. Blastix Arena is free to download and use. Some tournaments or specific features may have registration fees or additional charges, which will be clearly mentioned before you participate.',
    ),
    FaqItem(
      id: '03',
      question: 'How can I join a tournament?',
      answer:
          'Open the Tournaments section and select the tournament you want to join. Check the tournament details, eligibility, rules and registration fee, then complete the registration process. Once your registration is confirmed, you can participate according to the tournament schedule.',
    ),
    FaqItem(
      id: '04',
      question: 'Can I register my team?',
      answer:
          'Yes. If a tournament supports team participation, you can create or register your team by adding the required team and player details. Make sure all information is accurate before submitting the registration.',
    ),
    FaqItem(
      id: '05',
      question: 'How will I know if my registration is successful?',
      answer:
          'After completing your registration, you will receive a confirmation on the app. Your registered tournament will also appear in your account/tournament section. If the payment is successful but your registration is not updated, please use Report an Issue or contact our Support Team.',
    ),
    FaqItem(
      id: '06',
      question: 'How is prize money distributed?',
      answer:
          'Prize distribution depends on the specific tournament and its announced prize structure. The prize pool, winning positions, eligibility requirements and distribution details will be mentioned on the respective tournament page. Winners will receive their prizes according to the tournament\'s official rules and verification process.',
    ),
    FaqItem(
      id: '07',
      question: 'Can I watch live tournaments on the app?',
      answer:
          'Yes. You can watch supported live esports tournaments through the Live section of Blastix Arena. Availability may vary depending on the event. You can also find upcoming and past events where available.',
    ),
  ];

  List<FaqItem> get _filteredFaqs {
    if (_searchQuery.isEmpty) return _faqs;
    final query = _searchQuery.toLowerCase();
    return _faqs.where((faq) {
      return faq.question.toLowerCase().contains(query) ||
          faq.answer.toLowerCase().contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openReportIssueSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _ReportIssueModal(),
    );
  }

  void _openContactSupportSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _ContactSupportModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredFaqs;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceNavy,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primaryNeon.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppColors.textPrimary,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Row(
                    children: [
                      Image.asset(
                        'assets/logos/app_logo.png',
                        height: 24,
                        width: 24,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.bolt_rounded,
                          color: AppColors.primaryNeon,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 8),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'BLASTIX ',
                              style: GoogleFonts.orbitron(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primaryNeon,
                                letterSpacing: 1.0,
                              ),
                            ),
                            TextSpan(
                              text: 'ARENA',
                              style: GoogleFonts.orbitron(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title Header
                    Text(
                      'FAQ',
                      style: GoogleFonts.orbitron(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primaryNeon,
                        letterSpacing: 1.5,
                        shadows: [
                          BoxShadow(
                            color: AppColors.primaryNeon.withValues(alpha: 0.35),
                            blurRadius: 14,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Find quick answers to common questions about Blastix Arena.',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Search Input Bar
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceNavy,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primaryNeon.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val.trim();
                            _expandedIndex = null;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search your question...',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    color: AppColors.textMuted,
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                      _expandedIndex = null;
                                    });
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // FAQ Accordion List
                    if (filtered.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.search_off_rounded,
                              color: AppColors.textMuted,
                              size: 48,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No matching questions found',
                              style: GoogleFonts.orbitron(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          final isExpanded = _expandedIndex == index;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceNavy,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isExpanded
                                      ? AppColors.primaryNeon
                                      : AppColors.primaryNeon
                                          .withValues(alpha: 0.2),
                                  width: isExpanded ? 1.2 : 1,
                                ),
                                boxShadow: isExpanded
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primaryNeon
                                              .withValues(alpha: 0.12),
                                          blurRadius: 10,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Theme(
                                data: Theme.of(context).copyWith(
                                  dividerColor: Colors.transparent,
                                ),
                                child: ExpansionTile(
                                  key: Key('faq_${item.id}_$isExpanded'),
                                  initiallyExpanded: isExpanded,
                                  onExpansionChanged: (expanded) {
                                    setState(() {
                                      _expandedIndex = expanded ? index : null;
                                    });
                                  },
                                  tilePadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 4,
                                  ),
                                  leading: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceElevated,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppColors.primaryNeon
                                            .withValues(alpha: 0.4),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      item.id,
                                      style: GoogleFonts.orbitron(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primaryNeon,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    item.question,
                                    style: GoogleFonts.rajdhani(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  trailing: Icon(
                                    isExpanded
                                        ? Icons.keyboard_arrow_up_rounded
                                        : Icons.keyboard_arrow_down_rounded,
                                    color: isExpanded
                                        ? AppColors.primaryNeon
                                        : AppColors.textMuted,
                                    size: 22,
                                  ),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          14, 0, 14, 14),
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceElevated
                                              .withValues(alpha: 0.5),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          item.answer,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            height: 1.45,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                    const SizedBox(height: 24),

                    // Bottom Action Cards (Report an Issue & Contact Support)
                    Row(
                      children: [
                        // Left Card: Report an Issue
                        Expanded(
                          child: _ActionCard(
                            accentColor: const Color(0xFFFF4B6E),
                            icon: Icons.error_outline_rounded,
                            title: 'Report an Issue',
                            subtext:
                                'Facing a bug, glitch or technical issue? Let us know.',
                            onTap: () => _openReportIssueSheet(context),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Right Card: Contact Support
                        Expanded(
                          child: _ActionCard(
                            accentColor: AppColors.primaryNeon,
                            icon: Icons.headset_mic_outlined,
                            title: 'Contact Support',
                            subtext:
                                'Need more help? Get in touch with our support team.',
                            onTap: () => _openContactSupportSheet(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.accentColor,
    required this.icon,
    required this.title,
    required this.subtext,
    required this.onTap,
  });

  final Color accentColor;
  final IconData icon;
  final String title;
  final String subtext;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 170,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceNavy,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.45),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.1),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accentColor, size: 24),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.rajdhani(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtext,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                    height: 1.2,
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: accentColor,
                  size: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// REPORT AN ISSUE MODAL SHEET
class _ReportIssueModal extends StatefulWidget {
  const _ReportIssueModal();

  @override
  State<_ReportIssueModal> createState() => _ReportIssueModalState();
}

class _ReportIssueModalState extends State<_ReportIssueModal> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _tournamentController = TextEditingController();
  final _deviceController = TextEditingController(text: 'Android Device');
  final _appVersionController =
      TextEditingController(text: 'v1.0.4 (Build 42)');

  String _selectedIssueType = 'Bug / Glitch';
  bool _isSubmitting = false;

  static const List<String> _issueTypes = [
    'Bug / Glitch',
    'Login / Account Issue',
    'Tournament Issue',
    'Payment Issue',
    'Live Stream Issue',
    'App Performance',
    'Other',
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    _tournamentController.dispose();
    _deviceController.dispose();
    _appVersionController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 900));

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Issue report submitted successfully! Our team will investigate.',
            style: GoogleFonts.rajdhani(
              color: AppColors.bgNavy,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          backgroundColor: AppColors.primaryNeon,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 20,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceNavy,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.bug_report_rounded,
                          color: Color(0xFFFF4B6E), size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'REPORT AN ISSUE',
                        style: GoogleFonts.orbitron(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: AppColors.textMuted, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Text(
                'Facing a bug, glitch or technical problem? Let us know so our team can investigate and fix it.',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Issue Type',
                style: GoogleFonts.rajdhani(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedIssueType,
                dropdownColor: AppColors.surfaceElevated,
                style: GoogleFonts.inter(
                    fontSize: 12.5, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.surfaceElevated,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.borderCyan),
                  ),
                ),
                items: _issueTypes
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedIssueType = val);
                },
              ),
              const SizedBox(height: 12),
              Text(
                'Describe the issue',
                style: GoogleFonts.rajdhani(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                style: GoogleFonts.inter(
                    fontSize: 12.5, color: AppColors.textPrimary),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Please describe the issue'
                    : null,
                decoration: InputDecoration(
                  hintText: 'Explain what happened or how to reproduce it...',
                  hintStyle: GoogleFonts.inter(
                      fontSize: 11.5, color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.surfaceElevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.borderCyan),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tournamentController,
                style: GoogleFonts.inter(
                    fontSize: 12.5, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Tournament Name (if applicable)',
                  labelStyle: GoogleFonts.inter(
                      fontSize: 11.5, color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.surfaceElevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.borderCyan),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _deviceController,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Device / Model',
                        labelStyle: GoogleFonts.inter(
                            fontSize: 11, color: AppColors.textMuted),
                        filled: true,
                        fillColor: AppColors.surfaceElevated,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _appVersionController,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'App Version',
                        labelStyle: GoogleFonts.inter(
                            fontSize: 11, color: AppColors.textMuted),
                        filled: true,
                        fillColor: AppColors.surfaceElevated,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF4B6E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          'Submit Report',
                          style: GoogleFonts.rajdhani(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// CONTACT SUPPORT MODAL SHEET
class _ContactSupportModal extends StatefulWidget {
  const _ContactSupportModal();

  @override
  State<_ContactSupportModal> createState() => _ContactSupportModalState();
}

class _ContactSupportModalState extends State<_ContactSupportModal> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();

  String _selectedCategory = 'General Query';
  bool _isSending = false;

  static const List<String> _categories = [
    'General Query',
    'Account & Verification',
    'Tournament Registration',
    'Prize & Wallet Payouts',
    'Technical Support',
  ];

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSending = true);
    await Future.delayed(const Duration(milliseconds: 900));

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Message sent to Support! We will reply via email shortly.',
            style: GoogleFonts.rajdhani(
              color: AppColors.bgNavy,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          backgroundColor: AppColors.primaryNeon,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 20,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceNavy,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.headset_mic_rounded,
                          color: AppColors.primaryNeon, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'CONTACT SUPPORT',
                        style: GoogleFonts.orbitron(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: AppColors.textMuted, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Text(
                'Need help with your account, tournament, payment or anything else? Our support team is here to help.',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _subjectController,
                style: GoogleFonts.inter(
                    fontSize: 12.5, color: AppColors.textPrimary),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required field' : null,
                decoration: InputDecoration(
                  labelText: 'Subject',
                  labelStyle: GoogleFonts.inter(
                      fontSize: 11.5, color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.surfaceElevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.borderCyan),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Category',
                style: GoogleFonts.rajdhani(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                dropdownColor: AppColors.surfaceElevated,
                style: GoogleFonts.inter(
                    fontSize: 12.5, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.surfaceElevated,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.borderCyan),
                  ),
                ),
                items: _categories
                    .map((cat) => DropdownMenuItem(
                          value: cat,
                          child: Text(cat),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),
              const SizedBox(height: 12),
              Text(
                'Describe your issue',
                style: GoogleFonts.rajdhani(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _messageController,
                maxLines: 4,
                style: GoogleFonts.inter(
                    fontSize: 12.5, color: AppColors.textPrimary),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Please describe your query'
                    : null,
                decoration: InputDecoration(
                  hintText: 'Enter all relevant details...',
                  hintStyle: GoogleFonts.inter(
                      fontSize: 11.5, color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.surfaceElevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.borderCyan),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSending ? null : _sendMessage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryNeon,
                    foregroundColor: AppColors.bgNavy,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSending
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.bgNavy),
                        )
                      : Text(
                          'Send Message',
                          style: GoogleFonts.rajdhani(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: AppColors.bgNavy,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
