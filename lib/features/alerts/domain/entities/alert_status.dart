enum AlertStatus { pending, assigned, collected, rejected }

extension AlertStatusX on AlertStatus {
  String get label {
    switch (this) {
      case AlertStatus.pending:
        return 'Pending';
      case AlertStatus.assigned:
        return 'Assigned';
      case AlertStatus.collected:
        return 'Collected';
      case AlertStatus.rejected:
        return 'Rejected';
    }
  }
}
