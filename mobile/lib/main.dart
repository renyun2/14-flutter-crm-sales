import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/crm_app.dart';
import 'core/storage/visit_draft_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await VisitDraftStorage().init();
  runApp(const ProviderScope(child: CrmApp()));
}
