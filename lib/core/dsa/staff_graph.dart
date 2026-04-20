/// Adjacency List representing the relationships between staff (doctors) and patients.
/// This allows for efficient workload tracking and assignment validation.
class StaffGraph {
  /// Map of doctorId -> list of patientIds
  final Map<String, List<String>> _adjacency = {};

  /// Ensures a staff member exists in the graph.
  void addStaff(String staffId) {
    _adjacency.putIfAbsent(staffId, () => []);
  }

  /// Assigns a patient to a doctor.
  /// Prevents double-assignment by checking if the patient already exists in any doctor's list.
  /// Time Complexity: O(Total Patients)
  bool assignPatient(String doctorId, String patientId) {
    // Check if patient already assigned to ANY doctor
    for (var patients in _adjacency.values) {
      if (patients.contains(patientId)) {
        return false; // Already assigned
      }
    }
    _adjacency.putIfAbsent(doctorId, () => []);
    _adjacency[doctorId]!.add(patientId);
    return true;
  }

  /// Removes a patient assignment from a doctor.
  void removePatient(String doctorId, String patientId) {
    _adjacency[doctorId]?.remove(patientId);
  }

  /// Returns read-only list of patients for a doctor.
  List<String> getPatientsOf(String doctorId) =>
      List.unmodifiable(_adjacency[doctorId] ?? []);

  /// Returns the current workload (count of patients) for a doctor.
  int getWorkload(String doctorId) => _adjacency[doctorId]?.length ?? 0;

  /// Suggests the doctor with the least workload from a list of available doctors.
  String? getLeastLoadedDoctor(List<String> availableDoctorIds) {
    if (availableDoctorIds.isEmpty) return null;
    return availableDoctorIds.reduce((a, b) =>
        getWorkload(a) <= getWorkload(b) ? a : b);
  }
}
