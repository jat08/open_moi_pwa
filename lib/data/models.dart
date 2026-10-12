class Measurement {
  final int? id;
  final int? groupId;
  final String type; // OBJECT_A, OBJECT_B, PADDLE, TARE_PB, TARE_TW
  final double period;
  final double moi;
  final String tareMode;
  final String rawData;
  final String cyclePeriods;
  final double totalDuration;
  final double fitResidual;
  final int timestamp;

  Measurement({
    this.id,
    this.groupId,
    required this.type,
    required this.period,
    required this.moi,
    this.tareMode = 'None',
    this.rawData = '',
    this.cyclePeriods = '',
    this.totalDuration = 0.0,
    this.fitResidual = 0.0,
    int? timestamp,
  }) : timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'groupId': groupId,
      'type': type,
      'period': period,
      'moi': moi,
      'tareMode': tareMode,
      'rawData': rawData,
      'cyclePeriods': cyclePeriods,
      'totalDuration': totalDuration,
      'fitResidual': fitResidual,
      'timestamp': timestamp,
    };
  }

  factory Measurement.fromMap(Map<String, dynamic> map) {
    return Measurement(
      id: map['id'] as int?,
      groupId: map['groupId'] as int?,
      type: map['type'] as String,
      period: (map['period'] as num).toDouble(),
      moi: (map['moi'] as num).toDouble(),
      tareMode: map['tareMode'] as String? ?? 'None',
      rawData: map['rawData'] as String? ?? '',
      cyclePeriods: map['cyclePeriods'] as String? ?? '',
      totalDuration: (map['totalDuration'] as num?)?.toDouble() ?? 0.0,
      fitResidual: (map['fitResidual'] as num?)?.toDouble() ?? 0.0,
      timestamp: map['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  Measurement copyWith({
    int? id,
    int? groupId,
    String? type,
    double? period,
    double? moi,
    String? tareMode,
    String? rawData,
    String? cyclePeriods,
    double? totalDuration,
    double? fitResidual,
    int? timestamp,
  }) {
    return Measurement(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      type: type ?? this.type,
      period: period ?? this.period,
      moi: moi ?? this.moi,
      tareMode: tareMode ?? this.tareMode,
      rawData: rawData ?? this.rawData,
      cyclePeriods: cyclePeriods ?? this.cyclePeriods,
      totalDuration: totalDuration ?? this.totalDuration,
      fitResidual: fitResidual ?? this.fitResidual,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

class MeasurementGroup {
  final int? id;
  final String name;
  final int timestamp;
  final double mass;
  final String massUnit;
  final double length;
  final String lengthUnit;
  final double width;
  final String widthUnit;
  final String groupType;

  MeasurementGroup({
    this.id,
    required this.name,
    int? timestamp,
    this.mass = 0.0,
    this.massUnit = 'oz',
    this.length = 0.0,
    this.lengthUnit = 'in',
    this.width = 0.0,
    this.widthUnit = 'in',
    this.groupType = 'Pickleball Paddle',
  }) : timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'timestamp': timestamp,
      'mass': mass,
      'massUnit': massUnit,
      'length': length,
      'lengthUnit': lengthUnit,
      'width': width,
      'widthUnit': widthUnit,
      'groupType': groupType,
    };
  }

  factory MeasurementGroup.fromMap(Map<String, dynamic> map) {
    return MeasurementGroup(
      id: map['id'] as int?,
      name: map['name'] as String,
      timestamp: map['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      mass: (map['mass'] as num?)?.toDouble() ?? 0.0,
      massUnit: map['massUnit'] as String? ?? 'oz',
      length: (map['length'] as num?)?.toDouble() ?? 0.0,
      lengthUnit: map['lengthUnit'] as String? ?? 'in',
      width: (map['width'] as num?)?.toDouble() ?? 0.0,
      widthUnit: map['widthUnit'] as String? ?? 'in',
      groupType: map['groupType'] as String? ?? 'Pickleball Paddle',
    );
  }

  MeasurementGroup copyWith({
    int? id,
    String? name,
    int? timestamp,
    double? mass,
    String? massUnit,
    double? length,
    String? lengthUnit,
    double? width,
    String? widthUnit,
    String? groupType,
  }) {
    return MeasurementGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      timestamp: timestamp ?? this.timestamp,
      mass: mass ?? this.mass,
      massUnit: massUnit ?? this.massUnit,
      length: length ?? this.length,
      lengthUnit: lengthUnit ?? this.lengthUnit,
      width: width ?? this.width,
      widthUnit: widthUnit ?? this.widthUnit,
      groupType: groupType ?? this.groupType,
    );
  }
}

class EstimationGroup {
  final int? id;
  final String name;
  final double mass;
  final String massUnit;
  final double length;
  final String lengthUnit;
  final double width;
  final String widthUnit;
  final double balancePoint;
  final String bpUnit;
  final double radius;
  final String radiusUnit;
  final String type;
  final double resultSW;
  final double resultTW;
  final int timestamp;

  EstimationGroup({
    this.id,
    required this.name,
    this.mass = 0.0,
    this.massUnit = 'oz',
    this.length = 0.0,
    this.lengthUnit = 'in',
    this.width = 0.0,
    this.widthUnit = 'in',
    this.balancePoint = 0.0,
    this.bpUnit = 'in',
    this.radius = 0.0,
    this.radiusUnit = 'cm',
    this.type = 'Pickleball Paddle',
    this.resultSW = 0.0,
    this.resultTW = 0.0,
    int? timestamp,
  }) : timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'mass': mass,
      'massUnit': massUnit,
      'length': length,
      'lengthUnit': lengthUnit,
      'width': width,
      'widthUnit': widthUnit,
      'balancePoint': balancePoint,
      'bpUnit': bpUnit,
      'radius': radius,
      'radiusUnit': radiusUnit,
      'type': type,
      'resultSW': resultSW,
      'resultTW': resultTW,
      'timestamp': timestamp,
    };
  }

  factory EstimationGroup.fromMap(Map<String, dynamic> map) {
    return EstimationGroup(
      id: map['id'] as int?,
      name: map['name'] as String,
      mass: (map['mass'] as num?)?.toDouble() ?? 0.0,
      massUnit: map['massUnit'] as String? ?? 'oz',
      length: (map['length'] as num?)?.toDouble() ?? 0.0,
      lengthUnit: map['lengthUnit'] as String? ?? 'in',
      width: (map['width'] as num?)?.toDouble() ?? 0.0,
      widthUnit: map['widthUnit'] as String? ?? 'in',
      balancePoint: (map['balancePoint'] as num?)?.toDouble() ?? 0.0,
      bpUnit: map['bpUnit'] as String? ?? 'in',
      radius: (map['radius'] as num?)?.toDouble() ?? 0.0,
      radiusUnit: map['radiusUnit'] as String? ?? 'cm',
      type: map['type'] as String? ?? 'Pickleball Paddle',
      resultSW: (map['resultSW'] as num?)?.toDouble() ?? 0.0,
      resultTW: (map['resultTW'] as num?)?.toDouble() ?? 0.0,
      timestamp: map['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  EstimationGroup copyWith({
    int? id,
    String? name,
    double? mass,
    String? massUnit,
    double? length,
    String? lengthUnit,
    double? width,
    String? widthUnit,
    double? balancePoint,
    String? bpUnit,
    double? radius,
    String? radiusUnit,
    String? type,
    double? resultSW,
    double? resultTW,
    int? timestamp,
  }) {
    return EstimationGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      mass: mass ?? this.mass,
      massUnit: massUnit ?? this.massUnit,
      length: length ?? this.length,
      lengthUnit: lengthUnit ?? this.lengthUnit,
      width: width ?? this.width,
      widthUnit: widthUnit ?? this.widthUnit,
      balancePoint: balancePoint ?? this.balancePoint,
      bpUnit: bpUnit ?? this.bpUnit,
      radius: radius ?? this.radius,
      radiusUnit: radiusUnit ?? this.radiusUnit,
      type: type ?? this.type,
      resultSW: resultSW ?? this.resultSW,
      resultTW: resultTW ?? this.resultTW,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

class GroupSummary {
  final MeasurementGroup group;
  final int count;
  final double avgSW;
  final double stdDevSW;
  final double avgTW;
  final double stdDevTW;

  GroupSummary({
    required this.group,
    required this.count,
    required this.avgSW,
    required this.stdDevSW,
    required this.avgTW,
    required this.stdDevTW,
  });
}
