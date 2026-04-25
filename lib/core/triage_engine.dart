class TriageResult {
  final String level;
  final String reason;
  TriageResult(this.level, this.reason);
}

class TriageEngine {
  static TriageResult classify({
    required String bp,
    required int heartRate,
    required double temp,
    required String symptoms,
  }) {
    int systolic = 120;
    
    // BP Parsing improvements
    if (bp.contains('/')) {
      final parts = bp.split('/');
      systolic = int.tryParse(parts[0].replaceAll(RegExp(r'[^0-9]'), '')) ?? 120;
    } else {
      // Single value entered - assume it is systolic if it is a number
      systolic = int.tryParse(bp.replaceAll(RegExp(r'[^0-9]'), '')) ?? 120;
    }
    
    final syms = symptoms.toLowerCase();

    // CRITICAL
    if (systolic < 90 && systolic > 0) return TriageResult('CRITICAL', 'Dangerously low blood pressure (${systolic}mmHg). Risk of shock.');
    if (systolic > 180) return TriageResult('CRITICAL', 'Hypertensive crisis detected (${systolic}mmHg).');
    if (heartRate > 130) return TriageResult('CRITICAL', 'Severe tachycardia (${heartRate}bpm). Cardiac risk.');
    if (heartRate < 40 && heartRate > 0) return TriageResult('CRITICAL', 'Severe bradycardia (${heartRate}bpm). Immediate attention needed.');
    if (temp > 40.0) return TriageResult('CRITICAL', 'Hyperpyrexia (${temp}°C). Risk of organ damage.');
    if (temp < 35.0 && temp > 0) return TriageResult('CRITICAL', 'Hypothermia detected (${temp}°C). Life-threatening.');
    if (syms.contains('unconscious')) return TriageResult('CRITICAL', 'Patient unconscious. Immediate intervention required.');
    if (syms.contains('chest pain') || syms.contains('chest')) return TriageResult('CRITICAL', 'Chest pain reported. Possible cardiac event.');
    if (syms.contains('bleeding')) return TriageResult('CRITICAL', 'Active bleeding reported. Hemorrhage risk.');
    if (syms.contains('stroke')) return TriageResult('CRITICAL', 'Stroke symptoms present. Time-critical intervention needed.');
    if (syms.contains('seizure')) return TriageResult('CRITICAL', 'Seizure activity reported. Immediate care needed.');

    // URGENT
    if (systolic < 100 && systolic > 0) return TriageResult('URGENT', 'Low blood pressure (${systolic}mmHg). Monitoring required.');
    if (systolic > 160) return TriageResult('URGENT', 'High blood pressure (${systolic}mmHg). Risk of complications.');
    if (heartRate > 110) return TriageResult('URGENT', 'Elevated heart rate (${heartRate}bpm). Needs assessment.');
    if (heartRate < 55 && heartRate > 0) return TriageResult('URGENT', 'Low heart rate (${heartRate}bpm). Cardiac monitoring needed.');
    if (temp > 38.5) return TriageResult('URGENT', 'High fever (${temp}°C). Infection likely.');
    if (temp < 36.0 && temp > 0) return TriageResult('URGENT', 'Low body temperature (${temp}°C). Possible hypothermia onset.');
    if (syms.contains('dizzy') || syms.contains('faint')) return TriageResult('URGENT', 'Dizziness or fainting reported. Circulatory assessment required.');
    if (syms.contains('vomiting') || syms.contains('nausea')) return TriageResult('URGENT', 'Nausea/Vomiting. Dehydration and electrolyte risk.');
    if (syms.contains('breathing') || syms.contains('sob')) return TriageResult('URGENT', 'Breathing difficulty reported. Respiratory assessment needed.');
    if (syms.contains('pain')) return TriageResult('URGENT', 'Pain symptoms with borderline vitals. Evaluation required.');

    // STABLE
    return TriageResult('STABLE', 'Vitals within acceptable range. Continue monitoring.');
  }

  static String getVitalStatus(String type, String value) {
    if (type == 'bp') {
      final parts = value.split('/');
      final sys = int.tryParse(parts[0].replaceAll(RegExp(r'[^0-9]'), '')) ?? 120;
      if (sys < 90 || sys > 160) return 'critical';
      if (sys > 120 || sys < 100) return 'warning';
      return 'normal';
    } else if (type == 'hr') {
      final hr = int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 80;
      if (hr < 55 || hr > 110) return 'critical';
      if (hr < 60 || hr > 100) return 'warning';
      return 'normal';
    } else if (type == 'temp') {
      final t = double.tryParse(value.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 37.0;
      if (t < 36.0 || t > 39.0) return 'critical';
      if (t < 36.1 || t > 37.2) return 'warning';
      return 'normal';
    }
    return 'normal';
  }

  static int calculateRiskScore({
    required String triageLevel,
    required int age,
    required int heartRate,
    required double temperature,
    required int systolicBp,
    required DateTime lastVitalsTime,
  }) {
    int score = 0;

    // Triage base score
    if (triageLevel == 'CRITICAL') score += 40;
    else if (triageLevel == 'URGENT') score += 25;
    else score += 5;

    // Age risk
    if (age > 70) score += 20;
    else if (age > 55) score += 10;
    else if (age < 5) score += 15;

    // Vitals deviation
    if (systolicBp < 90 || systolicBp > 180) 
      score += 15;
    else if (systolicBp < 100 || systolicBp > 160) 
      score += 8;

    if (heartRate > 130 || heartRate < 40) 
      score += 15;
    else if (heartRate > 110 || heartRate < 55) 
      score += 8;

    if (temperature > 40 || temperature < 35) 
      score += 10;
    else if (temperature > 39 || temperature < 36) 
      score += 5;

    // Time since last vitals check
    int mins = DateTime.now().difference(lastVitalsTime).inMinutes;
    if (mins > 60) score += 10;
    else if (mins > 30) score += 5;

    return score.clamp(0, 100);
  }
}
