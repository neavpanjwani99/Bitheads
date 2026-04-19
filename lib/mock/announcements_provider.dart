import 'package:flutter_riverpod/flutter_riverpod.dart';

class AnnouncementModel {
  final String id;
  final String title;
  final String message;
  final bool isPriority;
  final DateTime expiresAt;

  AnnouncementModel({
    required this.id,
    required this.title,
    required this.message,
    required this.isPriority,
    required this.expiresAt,
  });
  
  bool get isActive => DateTime.now().isBefore(expiresAt);
}

class AnnouncementsNotifier extends Notifier<List<AnnouncementModel>> {
  @override
  List<AnnouncementModel> build() => [];

  void addAnnouncement(AnnouncementModel a) {
    state = [a, ...state];
  }

  void removeAnnouncement(String id) {
    state = state.where((a) => a.id != id).toList();
  }
}

final announcementsProvider = NotifierProvider<AnnouncementsNotifier, List<AnnouncementModel>>(AnnouncementsNotifier.new);
