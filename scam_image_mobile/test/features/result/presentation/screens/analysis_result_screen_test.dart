import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';

import 'package:scam_image_mobile/features/result/domain/entities/analysis_result.dart';
import 'package:scam_image_mobile/features/result/domain/entities/risk_factor.dart';
import 'package:scam_image_mobile/features/result/domain/repositories/result_repository.dart';
import 'package:scam_image_mobile/features/result/presentation/bloc/result_bloc.dart';
import 'package:scam_image_mobile/features/result/presentation/screens/analysis_result_screen.dart';

class _MockResultRepository extends Mock implements ResultRepository {}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('result image preview has no faux non-interactive slider', (
    tester,
  ) async {
    final repository = _MockResultRepository();
    final result = AnalysisResult(
      scanId: 'scan-1',
      taskId: 'task-1',
      status: 'completed',
      riskScore: 85,
      riskLevel: RiskLevel.high,
      summary: 'พบความเสี่ยง',
      createdAt: DateTime(2026, 9, 20),
      factors: const [
        RiskFactor(type: 'visual', score: 85, title: 'visual', details: []),
      ],
    );
    when(
      () => repository.getAnalysisResult(any()),
    ).thenAnswer((_) async => result);
    final bloc = ResultBloc(repository: repository);
    final router = GoRouter(
      initialLocation: '/result/task-1',
      routes: [
        GoRoute(
          path: '/result/:id',
          builder: (_, state) => BlocProvider<ResultBloc>.value(
            value: bloc,
            child: AnalysisResultScreen(taskId: state.pathParameters['id']!),
          ),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.byType(FractionallySizedBox), findsNothing);
    expect(find.text('Safe'), findsNothing);
    expect(find.text('ไม่มีรายละเอียดภาพเพิ่มเติมจากระบบ'), findsOneWidget);
    expect(find.byType(Slider), findsNothing);
    expect(find.text('85/100'), findsWidgets);
    expect(find.text('High'), findsOneWidget);
    expect(find.text('หลักฐานจากการวิเคราะห์'), findsOneWidget);
    expect(find.text('ร่องรอยในภาพ'), findsOneWidget);
    expect(find.text('ข้อความในภาพ'), findsOneWidget);
    expect(find.text('ข้อมูลแหล่งที่มา'), findsOneWidget);
    expect(find.text('ไม่มีข้อมูลจากการวิเคราะห์ชั้นนี้'), findsNWidgets(2));

    bloc.close();
  });
}
