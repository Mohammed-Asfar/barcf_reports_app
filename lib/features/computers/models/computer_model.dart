class Computer {
  final int? id;
  final int? sno;
  final String name;
  final String? empNo;
  final String? designation;
  final String? section;
  final String? roomNo;
  final String? processor;
  final String? ram;
  final String? storage; // HDD/SSD
  final String? graphicsCard;
  final String? monitorSize;
  final String? monitorBrand;
  final String? amcCode;
  final String? purpose;
  final String? ipAddress;
  final String? macAddress;
  final String? printer;
  final String? connectionType; // INTRA/INTERNET
  final String? adminUser; // Admin/User
  final String? printerCartridge;
  final String? k7;
  final String? pcSerialNo;
  final String? monitorSerialNo;
  final String? pcBrand;
  final String status;
  final String? notes;
  final int createdByUserId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  Computer({
    this.id,
    this.sno,
    required this.name,
    this.empNo,
    this.designation,
    this.section,
    this.roomNo,
    this.processor,
    this.ram,
    this.storage,
    this.graphicsCard,
    this.monitorSize,
    this.monitorBrand,
    this.amcCode,
    this.purpose,
    this.ipAddress,
    this.macAddress,
    this.printer,
    this.connectionType,
    this.adminUser,
    this.printerCartridge,
    this.k7,
    this.pcSerialNo,
    this.monitorSerialNo,
    this.pcBrand,
    this.status = 'Active',
    this.notes,
    required this.createdByUserId,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sno': sno,
      'name': name,
      'empNo': empNo,
      'designation': designation,
      'section': section,
      'roomNo': roomNo,
      'processor': processor,
      'ram': ram,
      'storage': storage,
      'graphicsCard': graphicsCard,
      'monitorSize': monitorSize,
      'monitorBrand': monitorBrand,
      'amcCode': amcCode,
      'purpose': purpose,
      'ipAddress': ipAddress,
      'macAddress': macAddress,
      'printer': printer,
      'connectionType': connectionType,
      'adminUser': adminUser,
      'printerCartridge': printerCartridge,
      'k7': k7,
      'pcSerialNo': pcSerialNo,
      'monitorSerialNo': monitorSerialNo,
      'pcBrand': pcBrand,
      'status': status,
      'notes': notes,
      'createdByUserId': createdByUserId,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  factory Computer.fromMap(Map<String, dynamic> map) {
    return Computer(
      id: map['id'],
      sno: map['sno'],
      name: map['name'] ?? '',
      empNo: map['empNo'],
      designation: map['designation'],
      section: map['section'],
      roomNo: map['roomNo'],
      processor: map['processor'],
      ram: map['ram'],
      storage: map['storage'],
      graphicsCard: map['graphicsCard'],
      monitorSize: map['monitorSize'],
      monitorBrand: map['monitorBrand'],
      amcCode: map['amcCode'],
      purpose: map['purpose'],
      ipAddress: map['ipAddress'],
      macAddress: map['macAddress'],
      printer: map['printer'],
      connectionType: map['connectionType'],
      adminUser: map['adminUser'],
      printerCartridge: map['printerCartridge'],
      k7: map['k7'],
      pcSerialNo: map['pcSerialNo'],
      monitorSerialNo: map['monitorSerialNo'],
      pcBrand: map['pcBrand'],
      status: map['status'] ?? 'Active',
      notes: map['notes'],
      createdByUserId: map['createdByUserId'],
      createdAt:
          map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
      updatedAt:
          map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
      deletedAt:
          map['deletedAt'] != null ? DateTime.parse(map['deletedAt']) : null,
    );
  }

  Computer copyWith({
    int? id,
    int? sno,
    String? name,
    String? empNo,
    String? designation,
    String? section,
    String? roomNo,
    String? processor,
    String? ram,
    String? storage,
    String? graphicsCard,
    String? monitorSize,
    String? monitorBrand,
    String? amcCode,
    String? purpose,
    String? ipAddress,
    String? macAddress,
    String? printer,
    String? connectionType,
    String? adminUser,
    String? printerCartridge,
    String? k7,
    String? pcSerialNo,
    String? monitorSerialNo,
    String? pcBrand,
    String? status,
    String? notes,
    int? createdByUserId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Computer(
      id: id ?? this.id,
      sno: sno ?? this.sno,
      name: name ?? this.name,
      empNo: empNo ?? this.empNo,
      designation: designation ?? this.designation,
      section: section ?? this.section,
      roomNo: roomNo ?? this.roomNo,
      processor: processor ?? this.processor,
      ram: ram ?? this.ram,
      storage: storage ?? this.storage,
      graphicsCard: graphicsCard ?? this.graphicsCard,
      monitorSize: monitorSize ?? this.monitorSize,
      monitorBrand: monitorBrand ?? this.monitorBrand,
      amcCode: amcCode ?? this.amcCode,
      purpose: purpose ?? this.purpose,
      ipAddress: ipAddress ?? this.ipAddress,
      macAddress: macAddress ?? this.macAddress,
      printer: printer ?? this.printer,
      connectionType: connectionType ?? this.connectionType,
      adminUser: adminUser ?? this.adminUser,
      printerCartridge: printerCartridge ?? this.printerCartridge,
      k7: k7 ?? this.k7,
      pcSerialNo: pcSerialNo ?? this.pcSerialNo,
      monitorSerialNo: monitorSerialNo ?? this.monitorSerialNo,
      pcBrand: pcBrand ?? this.pcBrand,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
