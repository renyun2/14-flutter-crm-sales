import 'package:flutter_test/flutter_test.dart';

import 'package:crm_sales/data/models/models.dart';

void main() {
  test('Lead parses overdue flag', () {
    final lead = Lead.fromJson({
      'id': '1',
      'title': '测试线索',
      'company': '公司A',
      'source': '官网',
      'status': 'new',
      'owner_id': 'u1',
      'overdue': true,
    });
    expect(lead.overdue, isTrue);
  });

  test('Opportunity stage labels exist', () {
    expect(opportunityStages.length, 6);
    expect(opportunityStages.first.$2, '初步接触');
  });
}
