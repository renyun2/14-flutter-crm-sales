import 'package:hive_flutter/hive_flutter.dart';

class VisitDraftStorage {
  static const _boxName = 'visit_drafts';

  Future<void> init() async {
    await Hive.initFlutter();
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<String>(_boxName);
    }
  }

  Future<void> saveDraft(String visitId, String summary) async {
    final box = Hive.box<String>(_boxName);
    await box.put(visitId, summary);
  }

  String? getDraft(String visitId) {
    if (!Hive.isBoxOpen(_boxName)) return null;
    return Hive.box<String>(_boxName).get(visitId);
  }

  Future<void> clearDraft(String visitId) async {
    if (!Hive.isBoxOpen(_boxName)) return;
    await Hive.box<String>(_boxName).delete(visitId);
  }
}
