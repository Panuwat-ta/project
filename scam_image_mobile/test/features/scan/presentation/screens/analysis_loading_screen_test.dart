import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';

import 'package:scam_image_mobile/features/scan/presentation/bloc/scan_bloc.dart';
import 'package:scam_image_mobile/features/scan/presentation/screens/analysis_loading_screen.dart';

class _MockScanBloc extends MockBloc<ScanEvent, ScanState>
    implements ScanBloc {}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('scan error remains in place and exposes retry actions', (
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
        GoRoute(path: '/crop', builder: (_, _) => const Text('crop')),
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
  });
}
