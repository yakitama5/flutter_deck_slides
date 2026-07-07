import 'package:flutter/material.dart';
import 'package:flutter_deck/flutter_deck.dart';
import 'package:flutter_deck_web_client/flutter_deck_web_client.dart';
import 'package:google_fonts/google_fonts.dart';

import 'slides/s01_title.dart';
import 'slides/s02_problem_chaos.dart';
import 'slides/s03_concept_spoc.dart';
import 'slides/s04_rag_sources.dart';
import 'slides/s05_architecture.dart';
import 'slides/s06_data_flow.dart';
import 'slides/s07_key_safety.dart';
import 'slides/s08_key_freeride.dart';
import 'slides/s09_value.dart';
import 'slides/s10_retrospective.dart';
import 'slides/s11_future_outlook.dart';
import 'slides/s12_summary.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // タイトルスライド初回表示時のフォント未読込フラッシュ(FOUT)を軽減するため、
  // 描画開始前に Noto Sans JP のフェッチを事前に済ませておく。
  GoogleFonts.notoSansJp();
  await GoogleFonts.pendingFonts();
  runApp(const ClaudenotebooklmApp());
}

class ClaudenotebooklmApp extends StatelessWidget {
  const ClaudenotebooklmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FlutterDeckApp(
      client: FlutterDeckWebClient(),
      lightTheme: buildAppFlutterDeckTheme(),
      themeMode: ThemeMode.light,
      configuration: const FlutterDeckConfiguration(
        controls: FlutterDeckControlsConfiguration(
          presenterToolbarVisible: true,
        ),
        footer: FlutterDeckFooterConfiguration(
          showFooter: true,
          showSlideNumbers: true,
        ),
        transition: FlutterDeckTransition.fade(),
      ),
      slides: [
        buildS01TitleSlide(),
        buildS02ProblemChaosSlide(),
        buildS03ConceptSpocSlide(),
        buildS04RagSourcesSlide(),
        buildS05ArchitectureSlide(),
        buildS06DataFlowSlide(),
        buildS07KeySafetySlide(),
        buildS08KeyFreerideSlide(),
        buildS09ValueSlide(),
        buildS10RetrospectiveSlide(),
        buildS11FutureOutlookSlide(),
        buildS12SummarySlide(),
      ],
    );
  }
}
