class Issue {
  final int? id;
  final int? sno;
  final String name;
  final String empNo;
  final String problem;
  final bool isIssueSorted;
  final String? materialsReplaced;
  final String attendedBy;
  final DateTime date;
  final int createdByUserId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? updatedByUserId;
  final DateTime? deletedAt;

  Issue({
    this.id,
    this.sno,
    required this.name,
    required this.empNo,
    required this.problem,
    required this.isIssueSorted,
    this.materialsReplaced,
    required this.attendedBy,
    required this.date,
    required this.createdByUserId,
    this.createdAt,
    this.updatedAt,
    this.updatedByUserId,
    this.deletedAt,
  });

  Issue copyWith({
    int? id,
    int? sno,
    String? name,
    String? empNo,
    String? problem,
    bool? isIssueSorted,
    String? materialsReplaced,
    String? attendedBy,
    DateTime? date,
    int? createdByUserId,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? updatedByUserId,
    DateTime? deletedAt,
  }) {
    return Issue(
      id: id ?? this.id,
      sno: sno ?? this.sno,
      name: name ?? this.name,
      empNo: empNo ?? this.empNo,
      problem: problem ?? this.problem,
      isIssueSorted: isIssueSorted ?? this.isIssueSorted,
      materialsReplaced: materialsReplaced ?? this.materialsReplaced,
      attendedBy: attendedBy ?? this.attendedBy,
      date: date ?? this.date,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedByUserId: updatedByUserId ?? this.updatedByUserId,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sno': sno,
      'name': name,
      'empNo': empNo,
      'problem': problem,
      'isIssueSorted': isIssueSorted ? 1 : 0,
      'materialsReplaced': materialsReplaced,
      'attendedBy': attendedBy,
      'date': date.toIso8601String(),
      'createdByUserId': createdByUserId,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'updatedByUserId': updatedByUserId,
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  factory Issue.fromMap(Map<String, dynamic> map) {
    return Issue(
      id: map['id'],
      sno: map['sno'],
      name: map['name'],
      empNo: map['empNo'],
      problem: map['problem'],
      isIssueSorted: map['isIssueSorted'] == 1,
      materialsReplaced: map['materialsReplaced'],
      attendedBy: map['attendedBy'],
      date: DateTime.parse(map['date']),
      createdByUserId: map['createdByUserId'],
      createdAt:
          map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
      updatedAt:
          map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
      updatedByUserId: map['updatedByUserId'],
      deletedAt:
          map['deletedAt'] != null ? DateTime.parse(map['deletedAt']) : null,
    );
  }
}
