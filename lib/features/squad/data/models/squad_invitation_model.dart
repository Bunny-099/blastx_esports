// ============================================================
// SQUAD INVITATION MODEL (Tournament Specific Invites)
// ============================================================

enum InvitationStatus { pending, accepted, rejected, expired }

class SquadInvitationModel {
  final String id;
  final String squadId;
  final String squadName;
  final String leaderId;
  final String leaderName;
  final String tournamentId;
  final String tournamentName;
  final String inviteeUserId;
  final String inviteeName;
  final InvitationStatus status;
  final DateTime? createdAt;

  const SquadInvitationModel({
    required this.id,
    required this.squadId,
    required this.squadName,
    required this.leaderId,
    required this.leaderName,
    required this.tournamentId,
    required this.tournamentName,
    required this.inviteeUserId,
    required this.inviteeName,
    this.status = InvitationStatus.pending,
    this.createdAt,
  });

  bool get isPending => status == InvitationStatus.pending;
  bool get isAccepted => status == InvitationStatus.accepted;
  bool get isRejected => status == InvitationStatus.rejected;

  SquadInvitationModel copyWith({
    String? id,
    String? squadId,
    String? squadName,
    String? leaderId,
    String? leaderName,
    String? tournamentId,
    String? tournamentName,
    String? inviteeUserId,
    String? inviteeName,
    InvitationStatus? status,
    DateTime? createdAt,
  }) {
    return SquadInvitationModel(
      id: id ?? this.id,
      squadId: squadId ?? this.squadId,
      squadName: squadName ?? this.squadName,
      leaderId: leaderId ?? this.leaderId,
      leaderName: leaderName ?? this.leaderName,
      tournamentId: tournamentId ?? this.tournamentId,
      tournamentName: tournamentName ?? this.tournamentName,
      inviteeUserId: inviteeUserId ?? this.inviteeUserId,
      inviteeName: inviteeName ?? this.inviteeName,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory SquadInvitationModel.fromJson(Map<String, dynamic> json) {
    final statusRaw = (json['status'] as String? ?? 'pending').toLowerCase();
    InvitationStatus parsedStatus;
    if (statusRaw == 'accepted') {
      parsedStatus = InvitationStatus.accepted;
    } else if (statusRaw == 'rejected') {
      parsedStatus = InvitationStatus.rejected;
    } else if (statusRaw == 'expired') {
      parsedStatus = InvitationStatus.expired;
    } else {
      parsedStatus = InvitationStatus.pending;
    }

    DateTime? parsedCreated;
    if (json['created_at'] != null || json['createdAt'] != null) {
      parsedCreated = DateTime.tryParse((json['created_at'] ?? json['createdAt']).toString());
    }

    return SquadInvitationModel(
      id: (json['id'] ?? '') as String,
      squadId: (json['squad_id'] ?? json['squadId'] ?? '') as String,
      squadName: (json['squad_name'] ?? json['squadName'] ?? '') as String,
      leaderId: (json['leader_id'] ?? json['leaderId'] ?? '') as String,
      leaderName: (json['leader_name'] ?? json['leaderName'] ?? '') as String,
      tournamentId: (json['tournament_id'] ?? json['tournamentId'] ?? '') as String,
      tournamentName: (json['tournament_name'] ?? json['tournamentName'] ?? '') as String,
      inviteeUserId: (json['invitee_user_id'] ?? json['inviteeUserId'] ?? '') as String,
      inviteeName: (json['invitee_name'] ?? json['inviteeName'] ?? '') as String,
      status: parsedStatus,
      createdAt: parsedCreated,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'squadId': squadId,
        'squadName': squadName,
        'leaderId': leaderId,
        'leaderName': leaderName,
        'tournamentId': tournamentId,
        'tournamentName': tournamentName,
        'inviteeUserId': inviteeUserId,
        'inviteeName': inviteeName,
        'status': status.name.toUpperCase(),
        'createdAt': createdAt?.toIso8601String(),
      };
}
