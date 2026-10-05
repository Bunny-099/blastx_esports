import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/custom_button.dart';
import '../data/models/squad_invitation_model.dart';
import '../data/models/squad_model.dart';
import '../providers/squad_provider.dart';

/// ============================================================
/// MY SQUAD SCREEN (Home -> E-Sports Hub -> My Squad)
/// ============================================================
/// Displays user's persistent squad (4 main + 2 substitutes).
/// Leader & Manager permissions: Remove member, Transfer leadership/ownership, Swap main/sub.
/// Member permissions: View-only mode.
/// Empty state handling for users without a squad.
/// ============================================================

class MySquadScreen extends ConsumerWidget {
  const MySquadScreen({super.key});

  Future<bool> _confirmDialog({
    required BuildContext context,
    required String title,
    required String message,
    required String confirmText,
    Color confirmColor = AppColors.primaryNeon,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.borderSubtle),
        ),
        title: Text(title, style: AppTextStyles.headingLg),
        content: Text(message, style: AppTextStyles.bodyMd),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: AppColors.bgNavy,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmText, style: AppTextStyles.button.copyWith(color: AppColors.bgNavy)),
          ),
        ],
      ),
    );
    return result == true;
  }

  void _showTransferLeadershipModal(
    BuildContext context,
    WidgetRef ref,
    SquadModel squad,
  ) async {
    final isManager = squad.isManagerOwned;
    final otherMembers = squad.members.where((m) => !(m.isLeader || m.isManager)).toList();

    if (otherMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No other squad members available to transfer ownership.')),
      );
      return;
    }

    final selectedMember = await showModalBottomSheet<SquadMemberModel>(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isManager ? 'TRANSFER MANAGEMENT' : 'TRANSFER LEADERSHIP',
                style: AppTextStyles.headingXl,
              ),
              const SizedBox(height: 4),
              Text(
                'Select a member to become the new squad ${isManager ? "manager" : "leader"}:',
                style: AppTextStyles.bodySm,
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: otherMembers.length,
                  itemBuilder: (ctx, index) {
                    final member = otherMembers[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: AppColors.surfaceNavy,
                        child: Text(
                          member.name.isNotEmpty ? member.name[0].toUpperCase() : 'P',
                          style: AppTextStyles.headingMd.copyWith(color: AppColors.primaryNeon),
                        ),
                      ),
                      title: Text(member.name, style: AppTextStyles.bodyLg),
                      subtitle: Text('IGN: ${member.ign} • UID: ${member.uid}', style: AppTextStyles.caption),
                      trailing: const Icon(Icons.shield_outlined, color: AppColors.primaryNeon),
                      onTap: () => Navigator.pop(ctx, member),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (selectedMember != null && context.mounted) {
      final confirmed = await _confirmDialog(
        context: context,
        title: isManager ? 'Transfer Management?' : 'Transfer Leadership?',
        message: 'Are you sure you want to transfer ${isManager ? "management" : "leadership"} to ${selectedMember.name}?',
        confirmText: 'Transfer',
      );

      if (confirmed) {
        ref.read(squadProvider.notifier).transferLeadership(selectedMember.userId);
      }
    }
  }

  void _showSwapPlayersModal(
    BuildContext context,
    WidgetRef ref,
    SquadModel squad,
  ) async {
    final mainPlayers = squad.mainPlayers;
    final substitutes = squad.substitutes;

    if (mainPlayers.isEmpty || substitutes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Swap requires at least 1 main player and 1 substitute.')),
      );
      return;
    }

    SquadMemberModel? selectedMain = mainPlayers.first;
    SquadMemberModel? selectedSub = substitutes.first;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateModal) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textMuted.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('SWAP ROSTER PLAYERS', style: AppTextStyles.headingXl),
                  const SizedBox(height: 4),
                  Text('Swap a Main player with a Substitute player:', style: AppTextStyles.bodySm),
                  const SizedBox(height: 16),

                  // Select Main Player Dropdown
                  Text('Select Main Player:', style: AppTextStyles.headingMd),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceNavy,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderCyan),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<SquadMemberModel>(
                        value: selectedMain,
                        dropdownColor: AppColors.surfaceNavy,
                        isExpanded: true,
                        items: mainPlayers.map((m) {
                          return DropdownMenuItem(
                            value: m,
                            child: Text('${m.name} (${m.ign})', style: AppTextStyles.bodyLg),
                          );
                        }).toList(),
                        onChanged: (val) => setStateModal(() => selectedMain = val),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Select Substitute Dropdown
                  Text('Select Substitute Player:', style: AppTextStyles.headingMd),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceNavy,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderCyan),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<SquadMemberModel>(
                        value: selectedSub,
                        dropdownColor: AppColors.surfaceNavy,
                        isExpanded: true,
                        items: substitutes.map((m) {
                          return DropdownMenuItem(
                            value: m,
                            child: Text('${m.name} (${m.ign})', style: AppTextStyles.bodyLg),
                          );
                        }).toList(),
                        onChanged: (val) => setStateModal(() => selectedSub = val),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  CustomButton(
                    text: 'CONFIRM SWAP',
                    onPressed: (selectedMain != null && selectedSub != null)
                        ? () {
                            Navigator.pop(ctx);
                            ref.read(squadProvider.notifier).swapPlayers(
                                  selectedMain!.userId,
                                  selectedSub!.userId,
                                );
                          }
                        : null,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<SquadState>(squadProvider, (prev, next) {
      if (next.errorMessage != null && next.errorMessage != prev?.errorMessage) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(next.errorMessage!),
              backgroundColor: AppColors.error,
            ),
          );
      } else if (next.successMessage != null && next.successMessage != prev?.successMessage) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(next.successMessage!),
              backgroundColor: AppColors.primaryNeon,
            ),
          );
      }
    });

    final squadState = ref.watch(squadProvider);
    final squad = squadState.squad;
    final isOwner = squadState.isOwner;
    final pendingInvitations = squadState.pendingInvitations;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        title: Text('MY SQUAD', style: AppTextStyles.headingXl),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: AppColors.primaryNeon),
            color: AppColors.surfaceElevated,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onSelected: (value) {
              final mockRepo = ref.read(mockSquadRepositoryProvider);
              if (value == 'toggle_mock') {
                final current = ref.read(useMockSquadRepositoryProvider);
                ref.read(useMockSquadRepositoryProvider.notifier).state = !current;
                ref.read(squadProvider.notifier).loadSquad();
              } else if (value == 'mock_leader') {
                mockRepo.resetToDefaultSquad();
                ref.read(squadProvider.notifier).loadSquad();
              } else if (value == 'mock_manager') {
                mockRepo.resetToManagerSquad();
                ref.read(squadProvider.notifier).loadSquad();
              } else if (value == 'mock_empty') {
                mockRepo.resetToEmpty();
                ref.read(squadProvider.notifier).loadSquad();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'mock_leader',
                child: Row(
                  children: [
                    const Icon(Icons.supervisor_account_rounded, size: 18, color: AppColors.primaryNeon),
                    const SizedBox(width: 10),
                    Text('Load Leader Squad (Default)', style: AppTextStyles.bodyMd),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'mock_manager',
                child: Row(
                  children: [
                    const Icon(Icons.admin_panel_settings_rounded, size: 18, color: AppColors.primaryNeon),
                    const SizedBox(width: 10),
                    Text('Load Manager Squad', style: AppTextStyles.bodyMd),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'mock_empty',
                child: Row(
                  children: [
                    const Icon(Icons.group_off_rounded, size: 18, color: AppColors.accentOrange),
                    const SizedBox(width: 10),
                    Text('Load Empty Squad State', style: AppTextStyles.bodyMd),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'toggle_mock',
                child: Row(
                  children: [
                    Icon(
                      ref.watch(useMockSquadRepositoryProvider) ? Icons.toggle_on_rounded : Icons.toggle_off_rounded,
                      size: 22,
                      color: AppColors.primaryNeon,
                    ),
                    const SizedBox(width: 8),
                    Text('Use Mock Repository', style: AppTextStyles.bodyMd),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primaryNeon,
        onRefresh: () => ref.read(squadProvider.notifier).loadSquad(),
        child: squadState.isLoading && squad == null
            ? const Center(child: CircularProgressIndicator(color: AppColors.primaryNeon))
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  // 1. Pending Tournament Invitations Banner (if any)
                  if (pendingInvitations.isNotEmpty) ...[
                    Text('TOURNAMENT INVITATIONS', style: AppTextStyles.headingMd),
                    const SizedBox(height: 8),
                    for (final inv in pendingInvitations)
                      _InvitationCard(
                        invitation: inv,
                        onAccept: () => ref.read(squadProvider.notifier).respondToInvitation(inv.id, true),
                        onReject: () async {
                          final ok = await _confirmDialog(
                            context: context,
                            title: 'Reject Tournament Invite?',
                            message: 'Rejecting this tournament invite will permanently remove you from the persistent squad.',
                            confirmText: 'Reject Invite',
                            confirmColor: AppColors.error,
                          );
                          if (ok) {
                            ref.read(squadProvider.notifier).respondToInvitation(inv.id, false);
                          }
                        },
                      ),
                    const SizedBox(height: 16),
                  ],

                  // 2. Empty State OR Squad Content
                  if (squad == null)
                    _buildEmptySquadState(context)
                  else ...[
                    // Squad Header Banner Card
                    _buildSquadHeaderCard(squad, isOwner),

                    const SizedBox(height: 20),

                    // Manager Section (If Manager Squad)
                    if (squad.isManagerOwned && squad.manager != null) ...[
                      Row(
                        children: [
                          const Icon(Icons.admin_panel_settings_rounded,
                              color: AppColors.primaryNeon, size: 18),
                          const SizedBox(width: 8),
                          Text('SQUAD MANAGER', style: AppTextStyles.headingMd),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildMemberCard(
                        context: context,
                        ref: ref,
                        slotLabel: 'MGR',
                        member: squad.manager,
                        squad: squad,
                        isOwner: isOwner,
                        isMain: false,
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Main Players Section Header
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 18,
                          decoration: BoxDecoration(
                            gradient: AppColors.fireGradient,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('MAIN PLAYERS', style: AppTextStyles.headingMd),
                        const Spacer(),
                        Text(
                          '${squad.mainCount}/${squad.maxMainPlayers}',
                          style: AppTextStyles.headingMd.copyWith(color: AppColors.primaryNeon),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Main Players Cards List
                    for (int i = 0; i < squad.maxMainPlayers; i++)
                      _buildMemberCard(
                        context: context,
                        ref: ref,
                        slotLabel: 'MAIN ${i + 1}',
                        member: i < squad.mainPlayers.length ? squad.mainPlayers[i] : null,
                        squad: squad,
                        isOwner: isOwner,
                        isMain: true,
                      ),

                    const SizedBox(height: 20),

                    // Substitutes Section Header
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 18,
                          decoration: BoxDecoration(
                            gradient: AppColors.fireGradient,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('SUBSTITUTES', style: AppTextStyles.headingMd),
                        const Spacer(),
                        Text(
                          '${squad.substituteCount}/${squad.maxSubstitutes}',
                          style: AppTextStyles.headingMd.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Optional • Max 2 substitutes per squad',
                      style: AppTextStyles.bodySm,
                    ),
                    const SizedBox(height: 8),

                    // Substitutes Cards List
                    for (int i = 0; i < squad.maxSubstitutes; i++)
                      _buildMemberCard(
                        context: context,
                        ref: ref,
                        slotLabel: 'SUB ${i + 1}',
                        member: i < squad.substitutes.length ? squad.substitutes[i] : null,
                        squad: squad,
                        isOwner: isOwner,
                        isMain: false,
                      ),

                    const SizedBox(height: 24),

                    // Management Actions Panel (ONLY for Leader / Manager Owner)
                    if (isOwner) ...[
                      Text('SQUAD MANAGEMENT', style: AppTextStyles.headingMd),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: CustomButton(
                              text: 'SWAP PLAYERS',
                              isOutlined: true,
                              icon: const Icon(Icons.swap_horiz_rounded, size: 18, color: AppColors.primaryNeon),
                              onPressed: () => _showSwapPlayersModal(context, ref, squad),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomButton(
                              text: squad.isManagerOwned ? 'TRANSFER MANAGER' : 'TRANSFER LEADER',
                              isOutlined: true,
                              icon: const Icon(Icons.shield_outlined, size: 18, color: AppColors.primaryNeon),
                              onPressed: () => _showTransferLeadershipModal(context, ref, squad),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ],
              ),
      ),
    );
  }

  /// Empty Squad Banner State
  Widget _buildEmptySquadState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      margin: const EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderCyan),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryNeon.withValues(alpha: 0.05),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primaryNeon.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.groups_outlined,
              color: AppColors.primaryNeon,
              size: 48,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'YOU DON\'T HAVE A SQUAD YET',
            textAlign: TextAlign.center,
            style: AppTextStyles.headingXl,
          ),
          const SizedBox(height: 8),
          Text(
            'Register for a tournament as a Leader or Manager, or join an existing team. Your squad will be saved persistently for all future tournaments!',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  /// Squad Header Card with name, tag, role badge
  Widget _buildSquadHeaderCard(SquadModel squad, bool isOwner) {
    final ownerName = squad.owner?.name ?? "Leader";
    final isManager = squad.isManagerOwned;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryNeon.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryNeon.withValues(alpha: 0.1),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: AppColors.blastixCoreGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryNeon.withValues(alpha: 0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    squad.tag.isNotEmpty ? squad.tag : squad.name[0].toUpperCase(),
                    style: GoogleFonts.rajdhani(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.bgNavy,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          squad.tag.isNotEmpty ? '[${squad.tag}] ${squad.name}' : squad.name,
                          style: AppTextStyles.headingXl.copyWith(fontSize: 21),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isManager ? 'Manager: $ownerName' : 'Leader: $ownerName',
                      style: AppTextStyles.bodyMd.copyWith(color: AppColors.primaryNeon),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isOwner ? AppColors.primaryNeon.withValues(alpha: 0.15) : AppColors.surfaceNavy,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isOwner ? AppColors.primaryNeon.withValues(alpha: 0.4) : AppColors.borderSubtle,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isOwner ? Icons.admin_panel_settings_rounded : Icons.visibility_rounded,
                  size: 16,
                  color: isOwner ? AppColors.primaryNeon : AppColors.textMuted,
                ),
                const SizedBox(width: 8),
                Text(
                  isOwner
                      ? (isManager
                          ? 'MANAGER PRIVILEGES • Full squad management access'
                          : 'LEADER PRIVILEGES • Full squad management access')
                      : 'MEMBER VIEW • View only (Owner manages roster)',
                  style: AppTextStyles.caption.copyWith(
                    color: isOwner ? AppColors.primaryNeon : AppColors.textMuted,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Individual Member Card
  Widget _buildMemberCard({
    required BuildContext context,
    required WidgetRef ref,
    required String slotLabel,
    required SquadMemberModel? member,
    required SquadModel squad,
    required bool isOwner,
    required bool isMain,
  }) {
    if (member == null) {
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceNavy.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderSubtle, style: BorderStyle.solid),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(slotLabel, style: AppTextStyles.caption),
            ),
            const SizedBox(width: 14),
            Text('Empty Slot', style: AppTextStyles.bodyMd.copyWith(fontStyle: FontStyle.italic)),
          ],
        ),
      );
    }

    final isLeaderMember = member.isLeader;
    final isManagerMember = member.isManager;
    final isOwnerMember = isLeaderMember || isManagerMember;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceNavy,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOwnerMember ? AppColors.primaryNeon.withValues(alpha: 0.5) : AppColors.borderCyan,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isMain ? AppColors.primaryNeon.withValues(alpha: 0.2) : AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              slotLabel,
              style: AppTextStyles.caption.copyWith(
                color: isMain ? AppColors.primaryNeon : AppColors.textMuted,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.surfaceElevated,
            child: Text(
              member.name.isNotEmpty ? member.name[0].toUpperCase() : 'P',
              style: AppTextStyles.headingMd.copyWith(fontSize: 14, color: AppColors.primaryNeon),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        member.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyLg.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (isLeaderMember || isManagerMember) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: isManagerMember ? AppColors.primaryNeon : AppColors.primaryNeon,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isManagerMember ? 'MANAGER' : 'LEADER',
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 8.5,
                            color: AppColors.bgNavy,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  'IGN: ${member.ign} • UID: ${member.uid}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),

          // Controls on Member Card for Squad Owner
          if (isOwner && !isOwnerMember) ...[
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary, size: 20),
              color: AppColors.surfaceElevated,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (action) async {
                if (action == 'remove') {
                  final ok = await _confirmDialog(
                    context: context,
                    title: 'Remove Member?',
                    message: 'Are you sure you want to remove ${member.name} from the squad?',
                    confirmText: 'Remove',
                    confirmColor: AppColors.error,
                  );
                  if (ok) {
                    ref.read(squadProvider.notifier).removeMember(member.userId);
                  }
                } else if (action == 'promote') {
                  ref.read(squadProvider.notifier).updateMemberRole(member.userId, SquadRosterType.main);
                } else if (action == 'demote') {
                  ref.read(squadProvider.notifier).updateMemberRole(member.userId, SquadRosterType.substitute);
                }
              },
              itemBuilder: (context) => [
                if (member.isSubstitute)
                  PopupMenuItem(
                    value: 'promote',
                    child: Row(
                      children: [
                        const Icon(Icons.arrow_upward_rounded, size: 16, color: AppColors.primaryNeon),
                        const SizedBox(width: 8),
                        Text('Promote to Main', style: AppTextStyles.bodyMd),
                      ],
                    ),
                  )
                else
                  PopupMenuItem(
                    value: 'demote',
                    child: Row(
                      children: [
                        const Icon(Icons.arrow_downward_rounded, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Text('Move to Substitute', style: AppTextStyles.bodyMd),
                      ],
                    ),
                  ),
                PopupMenuItem(
                  value: 'remove',
                  child: Row(
                    children: [
                      const Icon(Icons.person_remove_rounded, size: 16, color: AppColors.error),
                      const SizedBox(width: 8),
                      Text('Remove from Squad', style: AppTextStyles.bodyMd.copyWith(color: AppColors.error)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Tournament Invitation Card Component
class _InvitationCard extends StatelessWidget {
  const _InvitationCard({
    required this.invitation,
    required this.onAccept,
    required this.onReject,
  });

  final SquadInvitationModel invitation;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryNeon.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryNeon.withValues(alpha: 0.1),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.campaign_rounded, color: AppColors.primaryNeon, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  invitation.tournamentName,
                  style: AppTextStyles.headingMd.copyWith(fontSize: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Your squad leader ${invitation.leaderName} has invited you to join this tournament with ${invitation.squadName}.',
            style: AppTextStyles.bodyMd,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryNeon,
                    foregroundColor: AppColors.bgNavy,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: onAccept,
                  child: Text('ACCEPT', style: AppTextStyles.button.copyWith(color: AppColors.bgNavy, fontSize: 13)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: onReject,
                  child: Text('REJECT', style: AppTextStyles.button.copyWith(color: AppColors.error, fontSize: 13)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
