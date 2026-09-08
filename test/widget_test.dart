import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dark_wuxia/ui/app.dart';

void main() {
  testWidgets('App 启动测试', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: DarkWuxiaApp()));
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
