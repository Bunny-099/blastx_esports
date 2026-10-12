import 'team_model.dart';

/// Model representing a user's pending or past tournament registration approval request.
class RegistrationApproval {
  final String id;
  final ApprovalStatus status;
  final int rosterVersion;
  final DateTime? createdAt;
  final String tournamentId;
  final String tournamentTitle;
  final String tournamentBannerUrl;
  final DateTime? tournamentStartsAt;
  final String teamId;
  final String teamName;
  final String teamTag;
  final String teamLogoUrl;
  final ResponsiblePerson? responsiblePerson;
  final List<RegistrationPlayer> playingPlayers;

  const RegistrationApproval({
    required this.id,
    this.status = ApprovalStatus.pending,
    this.rosterVersion = 1,
    this.createdAt,
    this.tournamentId = '',
    this.tournamentTitle = '',
    this.tournamentBannerUrl = '',
    this.tournamentStartsAt,
    this.teamId = '',
    this.teamName = '',
    this.teamTag = '',
    this.teamLogoUrl = '',
    this.responsiblePerson,
    this.playingPlayers = const [],
  });

  bool get isPending => status == ApprovalStatus.pending;
  bool get isApproved => status == ApprovalStatus.approved;
  bool get isDeclined => status == ApprovalStatus.declined;

  factory RegistrationApproval.fromJson(Map<String, dynamic> json) {
    final tournObj = json['tournament'] is Map<String, dynamic>
        ? json['tournament'] as Map<String, dynamic>
        : null;
    final teamObj = json['team'] is Map<String, dynamic>
        ? json['team'] as Map<String, dynamic>
        : null;
    final respObj = json['responsible_person'] is Map<String, dynamic>
        ? json['responsible_person'] as Map<String, dynamic>
        : (json['responsiblePerson'] is Map<String, dynamic>
            ? json['responsiblePerson'] as Map<String, dynamic>
            : null);

    DateTime? parsedCreatedAt;
    final rawCreated = json['created_at'] ?? json['createdAt'];
    if (rawCreated != null) {
      parsedCreatedAt = DateTime.tryParse(rawCreated.toString());
    }

    DateTime? parsedStartsAt;
    final rawStarts = tournObj?['starts_at'] ?? tournObj?['startsAt'];
    if (rawStarts != null) {
      parsedStartsAt = DateTime.tryParse(rawStarts.toString());
    }

    final parsedPlayers = (json['playing_players'] as List<dynamic>?)
            ?.map((e) => RegistrationPlayer.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return RegistrationApproval(
      id: (json['id'] ?? '').toString(),
      status: ApprovalStatus.fromString(
        (json['status'] ?? 'PENDING').toString(),
      ),
      rosterVersion:
          (json['roster_version'] ?? json['rosterVersion'] as num?)?.toInt() ?? 1,
      createdAt: parsedCreatedAt,
      tournamentId: (tournObj?['id'] ?? json['tournament_id'] ?? json['tournamentId'] ?? '').toString(),
      tournamentTitle: (tournObj?['title'] ?? tournObj?['name'] ?? json['tournament_title'] ?? '').toString(),
      tournamentBannerUrl: (tournObj?['banner_url'] ?? tournObj?['bannerUrl'] ?? '').toString(),
      tournamentStartsAt: parsedStartsAt,
      teamId: (teamObj?['id'] ?? json['team_id'] ?? json['teamId'] ?? '').toString(),
      teamName: (teamObj?['name'] ?? json['team_name'] ?? '').toString(),
      teamTag: (teamObj?['tag'] ?? json['team_tag'] ?? '').toString(),
      teamLogoUrl: (teamObj?['logo_url'] ?? teamObj?['logoUrl'] ?? '').toString(),
      responsiblePerson:
          respObj != null ? ResponsiblePerson.fromJson(respObj) : null,
      playingPlayers: parsedPlayers,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'status': status.toUppercaseString(),
        'roster_version': rosterVersion,
        'created_at': createdAt?.toIso8601String(),
        'tournament': {
          'id': tournamentId,
          'title': tournamentTitle,
          'banner_url': tournamentBannerUrl,
          'starts_at': tournamentStartsAt?.toIso8601String(),
        },
        'team': {
          'id': teamId,
          'name': teamName,
          'tag': teamTag,
          'logo_url': teamLogoUrl,
        },
        'responsible_person': responsiblePerson?.toJson(),
        'playing_players': playingPlayers.map((e) => e.toJson()).toList(),
      };
}
