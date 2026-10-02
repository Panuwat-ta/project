import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';

import 'package:scam_image_mobile/features/scan/domain/entities/analysis_task.dart';
import 'package:scam_image_mobile/features/scan/presentation/bloc/scan_bloc.dart';
import 'package:scam_image_mobile/features/scan/presentation/screens/analysis_loading_screen.dart';

class _MockScanBloc extends MockBloc<ScanEvent, ScanState>
    implements ScanBloc {}

class _FakeScanEvent extends Fake implements ScanEvent {}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    registerFallbackValue(_FakeScanEvent());
  });

  testWidgets('scan error exposes retry and edit-image actions', (
    tester,
  ) async {
    final bloc = _MockScanBloc();
    when(() => bloc.state).thenReturn(ScanError('network unavailable'));
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());

    final router = GoRouter(
      initialLocation: '/loading',
      routes: [
        GoRoute(
          path: '/loading',
          builder: (_, _) => BlocProvider<ScanBloc>.value(
            value: bloc,
            child: const AnalysisLoadingScreen(filePath: '/tmp/example.jpg'),
          ),
        ),
        GoRoute(path: '/main/home', builder: (_, _) => const Text('home')),
        GoRoute(
          path: '/main/history',
          builder: (_, _) => const Text('history'),
        ),
        GoRoute(
          path: '/crop',
          builder: (_, state) => Text('crop ${state.extra}'),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('ยังวิเคราะห์ไม่สำเร็จ'), findsOneWidget);
    expect(find.text('ลองใหม่'), findsOneWidget);
    expect(find.text('กลับไปแก้ไขรูป'), findsOneWidget);
    expect(find.text('ไปประวัติ'), findsOneWidget);
    expect(find.text('home'), findsNothing);

    await tester.tap(find.text('กลับไปแก้ไขรูป'));
    await tester.pumpAndSettle();
    expect(find.text('crop {filePath: /tmp/example.jpg}'), findsOneWidget);
  });

  testWidgets('scan error can open history without retrying', (tester) async {
    final bloc = _MockScanBloc();
    when(() => bloc.state).thenReturn(ScanError('network unavailable'));
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());
    final router = _buildLoadingRouter(bloc);
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.tap(find.text('ไปประวัติ'));
    await tester.pumpAndSettle();

    expect(find.text('history'), findsOneWidget);
  });

  testWidgets('timeout exposes retry and retry resubmits the source image', (
    tester,
  ) async {
    final bloc = _MockScanBloc();
    when(() => bloc.state).thenReturn(ScanTimeout());
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());

    final router = GoRouter(
      initialLocation: '/loading',
      routes: [
        GoRoute(
          path: '/loading',
          builder: (_, _) => BlocProvider<ScanBloc>.value(
            value: bloc,
            child: const AnalysisLoadingScreen(
              filePath: '/fixture/timeout.jpg',
              scanName: 'timeout fixture',
            ),
          ),
        ),
        GoRoute(path: '/main/home', builder: (_, _) => const Text('home')),
        GoRoute(
          path: '/main/history',
          builder: (_, _) => const Text('history'),
        ),
        GoRoute(path: '/crop', builder: (_, _) => const Text('crop')),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();

    expect(find.text('หมดเวลารอผลจากระบบ กรุณาลองใหม่'), findsOneWidget);
    await tester.tap(find.text('ลองใหม่'));
    verify(
      () => bloc.add(
        any(
          that: isA<CropConfirmed>().having(
            (event) => event.filePath,
            'filePath',
            '/fixture/timeout.jpg',
          ),
        ),
      ),
    ).called(2); // Initial submission and explicit retry.
  });

  testWidgets('polling displays backend progress and active analysis step', (
    tester,
  ) async {
    final bloc = _MockScanBloc();
    when(() => bloc.state).thenReturn(
      ScanPolling(
        taskId: 'task-progress',
        progress: 42,
        step: AnalysisTaskStatus.processingText,
      ),
    );
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());

    final router = GoRouter(
      initialLocation: '/loading',
      routes: [
        GoRoute(
          path: '/loading',
          builder: (_, _) => BlocProvider<ScanBloc>.value(
            value: bloc,
            child: const AnalysisLoadingScreen(filePath: '/fixture/poll.jpg'),
          ),
        ),
        GoRoute(path: '/main/home', builder: (_, _) => const Text('home')),
        GoRoute(
          path: '/main/history',
          builder: (_, _) => const Text('history'),
        ),
        GoRoute(path: '/crop', builder: (_, _) => const Text('crop')),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();

    expect(find.text('42%'), findsOneWidget);
    expect(
      find.text('กำลังอ่านข้อความและสร้างคำอธิบายผลด้วย AI...'),
      findsOneWidget,
    );
    expect(find.text('เสร็จสิ้น'), findsNWidgets(2));
  });

  testWidgets('backend statuses activate the matching analysis step', (
    tester,
  ) async {
    final scenarios = <(AnalysisTaskStatus, String?, int)>[
      (
        AnalysisTaskStatus.processingSource,
        'กำลังตรวจสอบข้อมูลภาพและแหล่งที่มา...',
        0,
      ),
      (AnalysisTaskStatus.processingVisual, 'กำลังวิเคราะห์ภาพด้วย AI...', 1),
      (AnalysisTaskStatus.completed, null, 3),
    ];

    for (final (step, activeDescription, completedCount) in scenarios) {
      final bloc = _MockScanBloc();
      when(() => bloc.state).thenReturn(
        ScanPolling(taskId: 'task-status', progress: 70, step: step),
      );
      when(() => bloc.stream).thenAnswer((_) => const Stream.empty());
      final router = _buildLoadingRouter(bloc);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump(const Duration(milliseconds: 300));

      if (activeDescription != null) {
        expect(find.text(activeDescription), findsOneWidget);
      }
      expect(find.text('เสร็จสิ้น'), findsNWidgets(completedCount));

      router.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('completed scan navigates to its result route', (tester) async {
    final bloc = _MockScanBloc();
    final states = StreamController<ScanState>.broadcast();
    when(() => bloc.state).thenReturn(ScanPolling(taskId: 'task-next'));
    when(() => bloc.stream).thenAnswer((_) => states.stream);
    final router = GoRouter(
      initialLocation: '/loading',
      routes: [
        GoRoute(
          path: '/loading',
          builder: (_, _) => BlocProvider<ScanBloc>.value(
            value: bloc,
            child: const AnalysisLoadingScreen(
              filePath: '/fixture/complete.jpg',
              scanName: 'Completed scan',
            ),
          ),
        ),
        GoRoute(
          path: '/result/:id',
          builder: (_, state) =>
              Text('Result ${state.pathParameters['id']} ${state.extra}'),
        ),
      ],
    );
    addTearDown(router.dispose);
    addTearDown(states.close);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump(const Duration(milliseconds: 300));
    states.add(ScanCompleted('task-finished'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.text("Result task-finished {scanName: Completed scan}"),
      findsOneWidget,
    );
  });

  testWidgets('notification action opens notifications while scan is loading', (
    tester,
  ) async {
    final bloc = _MockScanBloc();
    when(
      () => bloc.state,
    ).thenReturn(ScanPolling(taskId: 'task-notifications'));
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());
    final router = _buildLoadingRouter(bloc);
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byIcon(Icons.notifications_outlined));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Notifications route'), findsOneWidget);
  });

  testWidgets('cancel dialog can resume scanning or return to home', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final bloc = _MockScanBloc();
    when(() => bloc.state).thenReturn(ScanInitial());
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());
    final router = _buildLoadingRouter(bloc);
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.ensureVisible(find.text('ยกเลิก'));
    await tester.tap(find.text('ยกเลิก'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('หยุดรอผล?'), findsOneWidget);

    await tester.tap(find.text('รอผลต่อ'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('home'), findsNothing);
    expect(find.text('กำลังวิเคราะห์ความปลอดภัย'), findsOneWidget);

    await tester.ensureVisible(find.text('ยกเลิก'));
    await tester.tap(find.text('ยกเลิก'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('หยุดรอและกลับ'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('home'), findsOneWidget);
    verify(() => bloc.add(any(that: isA<AnalysisCancelled>()))).called(1);
  });

  testWidgets('background confirmation opens history without cancelling scan', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final bloc = _MockScanBloc();
    when(() => bloc.state).thenReturn(ScanInitial());
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());
    final router = _buildLoadingRouter(bloc);
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.ensureVisible(find.text('ทำงานเบื้องหลัง'));
    await tester.tap(find.text('ทำงานเบื้องหลัง'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('ทำงานเบื้องหลัง'), findsWidgets);
    await tester.tap(find.text('ตกลง'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('history'), findsOneWidget);
    verifyNever(() => bloc.add(any(that: isA<AnalysisCancelled>())));
  });
}

GoRouter _buildLoadingRouter(_MockScanBloc bloc) => GoRouter(
  initialLocation: '/loading',
  routes: [
    GoRoute(
      path: '/loading',
      builder: (_, _) => BlocProvider<ScanBloc>.value(
        value: bloc,
        child: const AnalysisLoadingScreen(filePath: '/fixture/action.jpg'),
      ),
    ),
    GoRoute(path: '/main/home', builder: (_, _) => const Text('home')),
    GoRoute(path: '/main/history', builder: (_, _) => const Text('history')),
    GoRoute(path: '/crop', builder: (_, _) => const Text('crop')),
    GoRoute(
      path: '/notifications',
      builder: (_, _) => const Text('Notifications route'),
    ),
  ],
);
