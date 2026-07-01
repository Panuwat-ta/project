import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:scam_image_mobile/core/widgets/consent_checkbox_tile.dart';
import 'package:scam_image_mobile/core/widgets/primary_button.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  // StatefulWidget wrapper to allow toggling checkbox state in tests
  Widget buildTile({
    bool initialValue = false,
    required String label,
    String? description,
    void Function(bool?)? onChanged,
  }) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
        body: _CheckboxWrapper(
          initialValue: initialValue,
          label: label,
          description: description,
          externalOnChanged: onChanged,
        ),
      ),
    );
  }

  group('ConsentCheckboxTile', () {
    testWidgets('renders label text correctly', (tester) async {
      await tester.pumpWidget(buildTile(label: 'ฉันยอมรับเงื่อนไข'));
      await tester.pump();

      expect(find.text('ฉันยอมรับเงื่อนไข'), findsOneWidget);
    });

    testWidgets('shows description when provided', (tester) async {
      await tester.pumpWidget(buildTile(
        label: 'ฉันยอมรับเงื่อนไข',
        description: 'รายละเอียดเงื่อนไขการใช้งาน',
      ));
      await tester.pump();

      expect(find.text('รายละเอียดเงื่อนไขการใช้งาน'), findsOneWidget);
    });

    testWidgets('hides description when not provided', (tester) async {
      await tester.pumpWidget(buildTile(label: 'ฉันยอมรับเงื่อนไข'));
      await tester.pump();

      expect(find.text('รายละเอียดเงื่อนไขการใช้งาน'), findsNothing);
    });

    testWidgets('checkbox reflects initial value=false', (tester) async {
      await tester.pumpWidget(buildTile(label: 'ยอมรับ', initialValue: false));
      await tester.pump();

      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, isFalse);
    });

    testWidgets('checkbox reflects initial value=true', (tester) async {
      await tester.pumpWidget(buildTile(label: 'ยอมรับ', initialValue: true));
      await tester.pump();

      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, isTrue);
    });

    testWidgets('tapping tile calls onChanged with toggled value',
        (tester) async {
      bool? received;
      await tester.pumpWidget(buildTile(
        label: 'ยอมรับ',
        initialValue: false,
        onChanged: (v) => received = v,
      ));
      await tester.pump();

      // Tap the InkWell (the whole tile)
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      expect(received, isTrue); // toggled from false → true
    });

    testWidgets('tapping tile from true state calls onChanged with false',
        (tester) async {
      bool? received;
      await tester.pumpWidget(buildTile(
        label: 'ยอมรับ',
        initialValue: true,
        onChanged: (v) => received = v,
      ));
      await tester.pump();

      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      expect(received, isFalse); // toggled from true → false
    });
  });

  group('ConsentCheckboxTile + PrimaryButton integration', () {
    testWidgets('PrimaryButton is disabled when consent is unchecked',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(body: _ConsentButtonWrapper(initialValue: false)),
      ));
      await tester.pump();

      // ElevatedButton onPressed should be null when disabled
      final button =
          tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('PrimaryButton is enabled after checking consent',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(body: _ConsentButtonWrapper(initialValue: false)),
      ));
      await tester.pump();

      // Tap the ConsentCheckboxTile's InkWell (the first one in the tree)
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      final button =
          tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('PrimaryButton starts enabled when consent is pre-checked',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(body: _ConsentButtonWrapper(initialValue: true)),
      ));
      await tester.pump();

      final button =
          tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNotNull);
    });
  });
}

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Stateful wrapper that owns the checkbox state and calls an optional external
/// callback so tests can observe the value passed to [onChanged].
class _CheckboxWrapper extends StatefulWidget {
  const _CheckboxWrapper({
    required this.initialValue,
    required this.label,
    this.description,
    this.externalOnChanged,
  });

  final bool initialValue;
  final String label;
  final String? description;
  final void Function(bool?)? externalOnChanged;

  @override
  State<_CheckboxWrapper> createState() => _CheckboxWrapperState();
}

class _CheckboxWrapperState extends State<_CheckboxWrapper> {
  late bool _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return ConsentCheckboxTile(
      value: _value,
      label: widget.label,
      description: widget.description,
      onChanged: (v) {
        setState(() => _value = v ?? false);
        widget.externalOnChanged?.call(v);
      },
    );
  }
}

/// Stateful wrapper that pairs a [ConsentCheckboxTile] with a [PrimaryButton].
/// The button is only enabled when the checkbox is checked.
class _ConsentButtonWrapper extends StatefulWidget {
  const _ConsentButtonWrapper({required this.initialValue});

  final bool initialValue;

  @override
  State<_ConsentButtonWrapper> createState() => _ConsentButtonWrapperState();
}

class _ConsentButtonWrapperState extends State<_ConsentButtonWrapper> {
  late bool _checked;

  @override
  void initState() {
    super.initState();
    _checked = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConsentCheckboxTile(
          value: _checked,
          label: 'ยอมรับนโยบายความเป็นส่วนตัว',
          onChanged: (v) => setState(() => _checked = v ?? false),
        ),
        PrimaryButton(
          label: 'ดำเนินการต่อ',
          enabled: _checked,
          onPressed: _checked ? () {} : null,
        ),
      ],
    );
  }
}
