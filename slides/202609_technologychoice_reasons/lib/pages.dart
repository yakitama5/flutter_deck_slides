/// Source-grounded slide copy and speaker notes, independent of Flutter.
enum ReasonKind {
  cover,
  agenda,
  intention,
  chapter,
  architecture,
  workspace,
  environment,
  spm,
  harness,
  quality,
  theme,
  responsive,
  localization,
  investment,
  reconsider,
  takeaway,
  references,
  appendix,
}

class ReasonPage {
  const ReasonPage({
    required this.route,
    required this.title,
    required this.kind,
    required this.chapter,
    required this.seconds,
    required this.notes,
    this.kicker = '',
    this.lead = '',
    this.decision = '',
    this.reason = '',
    this.tradeoff = '',
    this.sourceLabel = '',
    this.sourceUrl = '',
    this.items = const <String>[],
  });

  final String route;
  final String title;
  final ReasonKind kind;
  final int chapter;
  final int seconds;
  final String notes;
  final String kicker;
  final String lead;
  final String decision;
  final String reason;
  final String tradeoff;
  final String sourceLabel;
  final String sourceUrl;
  final List<String> items;
}

const _source =
    'https://github.com/yakitama5/material_github_searcher/blob/'
    '57d9662dcdbfe1a93e6bb0b4706bfa778db8ba05';

const reasonPages = <ReasonPage>[
  ReasonPage(
    route: '/cover',
    title: '技術選定に\n自分の理由を',
    kind: ReasonKind.cover,
    chapter: 0,
    seconds: 15,
    kicker: 'FLUTTER / CODING EXAM / RETROSPECTIVE',
    lead: 'コーディング試験で選んだこと、\nその理由を動かして話す。',
    items: ['やくらん', '選定理由と振り返り'],
    notes: '''やくらんです。今日は、GitHubのリポジトリを検索するFlutterアプリのコーディング試験で、私が何を選び、なぜそうしたかを話します。UIで確かめられる部分は、横の小さなサンプルを動かして紹介します。

出典：README.md 冒頭、docs/technical-decisions.md、docs/retrospective.md。
実演はこの発表向けのミニサンプル。試験アプリ全体を埋め込んだものではありません。''',
  ),
  ReasonPage(
    route: '/agenda',
    title: '選んだ順より、\n理由のまとまりで',
    kind: ReasonKind.agenda,
    chapter: 0,
    seconds: 15,
    kicker: 'CONTENTS',
    lead: '五つの章から、判断の軸をたどる。',
    items: ['01 設計を選ぶ', '02 開発環境を選ぶ', '03 品質の守り方を選ぶ', '04 UIを選ぶ', '05 判断を振り返る'],
    notes: '''設計、開発環境、品質、UI、そして振り返りの五つです。各章で、選んだものと理由を並べます。採らなかったものや、まだ迷っているところも、そのまま紹介します。

本編は20枚・約11分。21枚目は参照資料、22枚目は質疑用の補足です。''',
  ),
  ReasonPage(
    route: '/intention',
    title: '何をアピールしたかったか',
    kind: ReasonKind.intention,
    chapter: 0,
    seconds: 35,
    kicker: 'STARTING POINT',
    lead: 'AIの速度に耐える基盤を、形にしたかった。',
    decision: '基盤設計と、品質を守る仕組みを優先',
    reason: 'AIがコードを速く生成しても、構造を把握して制御したい。\n\nAI同士で品質を高め、人の介入を少なくする仕組みを意識した。',
    tradeoff: 'デザインへの作り込みは、優先度の都合で後回しにした。',
    sourceLabel: '本人の振り返り / retrospective.md',
    sourceUrl: '$_source/docs/retrospective.md#L10-L21',
    items: ['生成の速度に耐える基盤', 'AIのためのハーネス設定', 'AI同士が品質を高める流れ', '人間の介入を最小限に'],
    notes: '''最初にアピールしたかったのは、この四つでした。AIが生成するコードをどこまで人が細かく確認するかは、悩ましいと感じています。そこで今回は、生成の速度に耐える構造と、品質を守る仕組みを強く意識しました。デザインにもアピールしたい部分はありましたが、優先順位をつけて後回しにしています。

出典：docs/retrospective.md「最初に何をアピールしようと考えたか」10–21行。ここは本人の記録の要約です。成果の速度や不具合率を測った数値としては提示しません。''',
  ),
  ReasonPage(
    route: '/chapter/design',
    title: '設計を選ぶ',
    kind: ReasonKind.chapter,
    chapter: 1,
    seconds: 10,
    kicker: 'CHAPTER 01',
    lead: 'AIが速く書いても、どこを変えるか分かるか？',
    notes: '''まず設計です。AIが速くコードを書いても、どこに何があり、どこまで変更するかを判断できる構造にしたいと考えました。''',
  ),
  ReasonPage(
    route: '/reasons/architecture',
    title: '生成が速くても、\n置き場所は迷わせない',
    kind: ReasonKind.architecture,
    chapter: 1,
    seconds: 55,
    kicker: 'ONION ARCHITECTURE',
    decision: 'オニオンアーキテクチャ + layer first',
    reason: '人が追えない速度でAIが生成しても、構造を制御しやすくしたい。\n\nどこに何を書くかが、人にもAIにも伝わる構成を選んだ。',
    tradeoff: '今回の検索要件なら、feature firstでも問題ないと考えていた。',
    sourceLabel: '本人の選定メモ / technical-decisions.md',
    sourceUrl: '$_source/docs/technical-decisions.md#L36-L67',
    items: [
      'domain：業務ルールと抽象',
      'application：ユースケースと状態',
      'infrastructure：外部サービスの実装',
      '依存方向はCIで機械的に検査',
    ],
    notes: '''オニオンアーキテクチャと、レイヤーを先に分ける構成を選びました。個人的には必要十分で、レイヤーをまたがなければ大きなリファクタリングを避けやすいと考えています。人にもAIにも、どこに何があるかが伝わることを重視しました。業務では機能を横断する処理や責務の変化も多いため、layer firstにしています。ただし、この試験の要件ならfeature firstでも問題ないと記録しました。

右の図では、業務ルールと抽象を内側に置き、外部サービスの実装を分ける関係を示します。実際のリポジトリでは、Providerのoverrideによる結線と、パッケージ依存のCI検査を用意しています。

出典：docs/technical-decisions.md「オニオンアーキテクチャ」「パッケージ構成」46–67行。実装の裏付け：docs/ARCHITECTURE.md「依存関係の機械的な保証」57–67行、「依存性逆転と実装の結線」120–143行。図は説明のために簡略化しています。''',
  ),
  ReasonPage(
    route: '/reasons/workspace',
    title: '標準で足りるなら、\nそこで始める',
    kind: ReasonKind.workspace,
    chapter: 1,
    seconds: 35,
    kicker: 'PUB WORKSPACE',
    decision: 'Pub Workspaceを採用 / Melosは見送り',
    reason: '新しく入る人に、Melos固有の知識を伝える負担が気になった。\n\nパッケージ管理は、まずDart標準の仕組みで構成した。',
    tradeoff: 'バージョン管理や並列実行とのバランス次第では、Melosを採用する。',
    sourceLabel: '本人の選定メモ / technical-decisions.md',
    sourceUrl: '$_source/docs/technical-decisions.md#L69-L74',
    items: [
      '採用：Pub Workspace',
      '見送り：Melos',
      '理由：固有知識を伝える負担',
      '見直す条件：バージョン管理・並列実行',
    ],
    notes: '''パッケージ管理にはPub Workspaceを使い、試験ではMelosを採りませんでした。依存が増えること自体より、固有の知識を新しい人へ伝えるコストが気になっています。ただ、Melosをいつでも使わないわけではありません。パッケージ間のバージョン管理や並列実行とのバランスによっては採用する、と同じメモに残しました。道具への好みと、今回の条件での判断は分けておきたいです。

出典：docs/technical-decisions.md「パッケージ構成 / 採らなかった選択肢」69–74行。採用状況：docs/ARCHITECTURE.md「Pub Workspaceを利用する方針」69–83行。スライド集自体はMelosを利用していますが、ここは試験アプリの選定を説明しています。''',
  ),
  ReasonPage(
    route: '/chapter/environment',
    title: '開発環境を選ぶ',
    kind: ReasonKind.chapter,
    chapter: 2,
    seconds: 10,
    kicker: 'CHAPTER 02',
    lead: '並列に進める自分に、どんな環境が合うか？',
    notes: '''次は開発環境です。並列に作業を進めやすいことと、まだ使ったことがないものを試すこと。その両方が理由になりました。''',
  ),
  ReasonPage(
    route: '/reasons/environment',
    title: '並列に進めやすい\n道具をそろえる',
    kind: ReasonKind.environment,
    chapter: 2,
    seconds: 40,
    kicker: 'MISE / GIT WORKTREE',
    decision: 'mise + Git worktree / 軽量なエディタ',
    reason:
        'Tasksの利便性もあり、FVMからmiseへ移った。\n\n並列開発ではworktreeで作業場所を分け、軽量な環境を好んで使う。',
    tradeoff: 'worktreeはディスクを使うため、削除する運用も必要になる。',
    sourceLabel: '本人の選定メモ / technical-decisions.md',
    sourceUrl: '$_source/docs/technical-decisions.md#L76-L122',
    items: [
      'mise：SDKとTasksを扱う',
      'worktree：作業ごとに場所を分ける',
      'Zed / terminal：軽量な環境',
      '使い終えたworktreeを片付ける',
    ],
    notes: '''SDK管理は、もともとFVMを使っていましたが、Tasksなどの利便性もあってmiseへ移っています。並列開発ではGit worktreeやgtrが便利です。並列でなくても、作業のディレクトリを分けると進めやすいと感じています。エディタやターミナルも軽量な構成を好み、Zedは配置を見たり気になる部分を直したりするときに使うことが多いです。一方で、worktreeはディスクを使います。作ることと片付けることを一緒に考えています。

出典：docs/technical-decisions.md「mise」84–87行、「開発環境」108–113行、「Git Worktree」119–122行。これらの道具の一般的な性能比較を主張するスライドではなく、本人の使い方と選定理由です。''',
  ),
  ReasonPage(
    route: '/reasons/spm',
    title: 'やってみたかった、\nも理由になる',
    kind: ReasonKind.spm,
    chapter: 2,
    seconds: 35,
    kicker: 'SWIFT PACKAGE MANAGER',
    decision: 'iOSの依存管理にSPMを採用',
    reason:
        '個人開発でも業務でも、まだ対応していなかったので試したかった。\n\n過去のCocoaPods周りの苦労を減らしたい、という思いもあった。',
    tradeoff: '選定した時点では、未対応パッケージが多そうだという懸念もあった。',
    sourceLabel: '本人の選定メモ / technical-decisions.md',
    sourceUrl: '$_source/docs/technical-decisions.md#L89-L98',
    items: [
      '動機：未経験の方式を試したい',
      '期待：CocoaPods周りの負担を減らしたい',
      '懸念：パッケージの対応状況',
      '学びも、今回の目的に含める',
    ],
    notes: '''SPMを選んだ理由には、まだ対応していなかったのでやってみたかった、と書きました。個人開発でも業務でも未経験だったので、この機会に試したかったんです。過去のCocoaPods周りの苦労から解放されたいという思いもありました。同時に、未対応のパッケージがまだ多そうだという懸念も記録しています。これは選定した時点での見立てです。学ぶことも目的に入っているなら、試したい気持ちも理由になると思います。

出典：docs/technical-decisions.md「SPM」89–98行。現在のエコシステム全体の対応率や、導入による作業時間削減の実測は示しません。Webスライド内でSPMそのものは実行しません。''',
  ),
  ReasonPage(
    route: '/chapter/quality',
    title: '品質の守り方を選ぶ',
    kind: ReasonKind.chapter,
    chapter: 3,
    seconds: 10,
    kicker: 'CHAPTER 03',
    lead: 'モデルが変わっても、何を守り続けたいか？',
    notes: '''品質の守り方にも選択があります。モデルや進め方が変わっても、プロジェクトとして何を守りたいかを考えました。''',
  ),
  ReasonPage(
    route: '/reasons/harness',
    title: '進め方を、\n固定しすぎない',
    kind: ReasonKind.harness,
    chapter: 3,
    seconds: 45,
    kicker: 'HARNESS DESIGN',
    decision: 'PJ固有の基盤・ルールと、推奨フローを記録',
    reason: 'AIの進め方は、モデルの進化ですぐに変わると思っている。\n\n細かな手順で縛りすぎず、このPJに必要な基盤とルールを残した。',
    tradeoff: 'ドキュメントの持ち方は、最後まで迷いが残った。',
    sourceLabel: '本人の振り返り / retrospective.md',
    sourceUrl: '$_source/docs/retrospective.md#L23-L37',
    items: [
      'Claude Code / Codexを利用',
      '推奨フローは残すが、強制しない',
      'Flutter公式AIルールは未導入',
      'ドキュメントの保守方法は検討中',
    ],
    notes: '''実装中に一番悩んだのは、ハーネス設計でした。個人的には、モデルが進化するたびにハーネスを再生成するのが最適ではないかと考えています。そのため、Flutter公式のAIルールは入れていません。ただ、何も書かなくてよいとも思っていません。このプロジェクトに必要だと判断した基盤とルールは残しました。進め方は推奨として記載していますが、細かく強制する設計にはしていません。ドキュメントをどう保守するか、Serenaなどへまとめる方がよいかは、最後まで迷った部分です。

出典：docs/retrospective.md「実装中に一番難しかったこと」23–37行、docs/technical-decisions.md「Claude Code / Codex」28–34行、docs/agent-driven-development.md 冒頭。Serenaへの移行や全ドキュメント削除は実施済みではなく、検討中の考えです。''',
  ),
  ReasonPage(
    route: '/reasons/quality',
    title: '納得できるルールを、\n仕組みで確かめる',
    kind: ReasonKind.quality,
    chapter: 3,
    seconds: 45,
    kicker: 'LINT / TEST / CI',
    decision: 'altive_lints + 振る舞いのテスト + CI',
    reason: '過剰すぎず、納得できるLintルールを使いたかった。\n\nテストと依存方向の検査を重ね、変更を継続して確かめる構成にした。',
    tradeoff: 'GoldenとPatrolはCIへ入れず、ローカルで確認する。',
    sourceLabel: '選定・方針 / technical-decisions.md・testing.md',
    sourceUrl: '$_source/docs/technical-decisions.md#L168-L217',
    items: [
      'altive_lints：納得できるルール',
      'Unit / Widget：変更した振る舞い',
      '依存検査：レイヤーの境界',
      'Golden / Patrol：ローカルで確認',
    ],
    notes: '''Lintにはaltive_lintsを選びました。過剰すぎず納得できるルールであることと、早くAnalyzer Pluginsへ移行していたことに信頼を感じています。仕組みとしては、変更した振る舞いのテストと、パッケージ依存の検査を重ねました。外部サービスは決定的なFakeへ差し替えます。一方、全部をCIに入れているわけではありません。GoldenはOS間の描画差があり、Patrolは実機やSimulatorが必要なので、ローカル実行です。CIには高速で安定して確かめられるものを置いています。

出典：本人の理由はdocs/technical-decisions.md「altive_lints」176–184行、「PR Check」213–217行。テスト方針はdocs/testing.md「基本方針」8–21行、「実行方法とローカル/CIの境界」113–119行。実際のチェック対象はREADME.md:166。CIでGoldenやPatrolを実行した、あるいは不具合率が下がったという主張はしません。''',
  ),
  ReasonPage(
    route: '/chapter/ui',
    title: 'UIを選ぶ',
    kind: ReasonKind.chapter,
    chapter: 4,
    seconds: 10,
    kicker: 'CHAPTER 04',
    lead: '好みと、使う人への配慮をどう両立するか？',
    notes: '''ここからはUIです。自分の好みも大切にしながら、配色、画面幅、言語をどう扱ったかを、Flutterのサンプルで見ていきます。''',
  ),
  ReasonPage(
    route: '/reasons/theme',
    title: '好きなデザインに、\n判断の拠り所がある',
    kind: ReasonKind.theme,
    chapter: 4,
    seconds: 65,
    kicker: 'MATERIAL DESIGN 3',
    decision: 'Material 3 + ColorSchemeを採用',
    reason:
        'Androidユーザーとして、Material 3のデザインが好きだ。\n\n少数派への配慮や配色のルールが明確で、判断の拠り所にできる。',
    tradeoff: '今回は基盤を優先し、デザインの作り込みには心残りもある。',
    sourceLabel: '本人の選定メモ / technical-decisions.md',
    sourceUrl: '$_source/docs/technical-decisions.md#L243-L256',
    items: ['SeedからColorSchemeを生成', 'Light / Darkで配色を切り替える', '同じ役割の色をUI全体で使う'],
    notes: '''Material 3は、Androidユーザーということもあって、かなり好みです。選定メモには、少数派への考慮がしっかりしていて、配色ルールも分かりやすいと書きました。好きだから選ぶことと、説明できるルールがあることが、つながっています。

【実演】青と紫のSeedを切り替えます。次にLightとDarkを切り替えます。同じ画面でも、色の役割をColorSchemeから受け取れば、まとめて追従します。このサンプルはFlutterのColorScheme.fromSeedを実際に使っています。試験アプリはOSのDynamic Colorにも対応していますが、ここではブラウザで再現できるSeedと明暗を見せています。

出典：本人の理由はdocs/technical-decisions.md「Material 3」249–251行。実装方針はdocs/design.md「Theme」17–38行。デザインを優先し切れなかった振り返りはdocs/retrospective.md:53–54。サンプルでOS Dynamic Colorそのものやアクセシビリティ適合性を検証したとは扱いません。''',
  ),
  ReasonPage(
    route: '/reasons/responsive',
    title: '端末名より、\nいま使える幅を見る',
    kind: ReasonKind.responsive,
    chapter: 4,
    seconds: 55,
    kicker: 'ADAPTIVE LAYOUT',
    decision: '利用可能幅 + Flutter標準APIで判断',
    reason: '端末の種類で決めず、いま使える幅に合わせる方針にした。\n\n今回必要な範囲は標準APIで収まるため、追加の仕組みは入れなかった。',
    tradeoff: '連続的なスケーリングが必要になれば、追加ライブラリを再評価する。',
    sourceLabel: 'プロジェクトのデザイン方針 / design.md',
    sourceUrl: '$_source/docs/design.md#L72-L120',
    items: [
      'compact：0–599 dp',
      'medium：600–839 dp',
      'expanded：840 dp以上',
      'MediaQuery / LayoutBuilderで判断',
    ],
    notes: '''ここは本人の選定メモではなく、プロジェクトに記載したデザイン方針です。端末名ではなく利用可能幅で判断し、画面全体はMediaQuery、Widget内部の折り返しはLayoutBuilderを使う方針にしています。今回の範囲は標準APIで収まるため、responsive_frameworkは入れていません。

【実演】サンプルの幅を390、720、1024 dpへ切り替えます。コンパクトでは下のNavigationBar、広がるとNavigationRail、さらに広い場合はラベル付きのRailへ変わります。サンプルの見た目は発表用に再構成しています。試験アプリでも同じ三段階でナビゲーションを切り替えます。

出典：docs/design.md「レスポンシブ対応」72–120行。動作の裏付け：apps/app/lib/src/navigation/adaptive_app_shell.dart:49–71。Webは試験アプリの正式配布対象ではなく、確認用途です。サンプルは各幅をローカルに再現します。''',
  ),
  ReasonPage(
    route: '/reasons/localization',
    title: '言葉を、\n画面の外で管理する',
    kind: ReasonKind.localization,
    chapter: 4,
    seconds: 50,
    kicker: 'SLANG',
    decision: 'YAML + Slangの生成コードで多言語化',
    reason:
        'YAMLで管理しやすいことが、Slangを選んだ理由だった。\n\n文字列だけでなく、Enumや数に応じた表現にも広げられる点を評価した。',
    sourceLabel: '本人の選定メモ / technical-decisions.md',
    sourceUrl: '$_source/docs/technical-decisions.md#L230-L241',
    items: ['日本語 / 英語を切り替える', '0 / 1 / 2件で複数形を確かめる', 'YAMLとSlang生成コードを使う'],
    notes: '''多言語化にはSlangを選びました。理由の一つはYAMLの管理しやすさです。もう一つは、単純な文字列以外にも、Enumや数に応じた設定へ広げられる柔軟さでした。

【実演】日本語と英語を切り替えます。検索案内や操作の文言が、同じ画面構成のまま変わります。次に件数を0、1、2へ切り替え、英語の1 repository foundと2 repositories foundを確かめます。これは説明用に加えたサンプル専用の複数形です。実際のSlangパッケージとYAMLからの生成コードを使っています。試験アプリも日本語・英語に対応していますが、この複数形の件数UIを本番に実装していたとは扱いません。

出典：docs/technical-decisions.md「Slang」238–241行。採用状況：README.md:80。文言の参照：apps/app/assets/i18n/repositorySearch_ja.i18n.yaml、repositorySearch_en.i18n.yaml。資料専用の操作ラベルはサンプル用に追加した文言です。''',
  ),
  ReasonPage(
    route: '/chapter/retrospective',
    title: '判断を振り返る',
    kind: ReasonKind.chapter,
    chapter: 5,
    seconds: 10,
    kicker: 'CHAPTER 05',
    lead: '選んだ理由を、次の自分にどう残すか？',
    notes: '''最後に振り返りです。よかったと思う選択だけでなく、過剰だったところや迷いも、次の自分へ残しました。''',
  ),
  ReasonPage(
    route: '/retrospective/investment',
    title: '要件には過剰でも、\n残したい判断だった',
    kind: ReasonKind.investment,
    chapter: 5,
    seconds: 40,
    kicker: 'A SAVE POINT',
    decision: '今後の業務で採用すると思う設計を試す',
    reason:
        '要件に対して、基盤やCI/CD、設定機能は過剰だったと思う。\n\nそれでも、自分を振り返るセーブポイントとして、形にしておきたかった。',
    tradeoff: '見積もりの甘さは反省点。デザインには、さらに試したいことが残った。',
    sourceLabel: '本人の振り返り / retrospective.md',
    sourceUrl: '$_source/docs/retrospective.md#L39-L54',
    items: ['業務で選ぶ設計を形にできた', '要件に対して過剰。見積もりにも甘さ', 'デザインを、もう少し作り込みたい'],
    notes: '''振り返りには、要件からするとだいぶ過剰な設計になったと書いています。基盤やCI/CD、デザインに関する設定機能も、作り込みすぎたと思いました。それでも、今後の業務で採用するであろう設計を、自分のセーブポイントとして形にしたかったんです。一方、見積もりの甘さは反省点です。デザインももう少しこだわりたかった。全部を成功談にせず、何に投資して、何が残ったかを記録しました。

出典：docs/retrospective.md「過剰だったと感じる部分」39–46行、「もう一度作るなら何を簡略化・変更するか」48–54行。作業時間やコストの比較数値は記録にないため提示しません。''',
  ),
  ReasonPage(
    route: '/retrospective/reconsider',
    title: '迷いも、\n選定理由の一部にする',
    kind: ReasonKind.reconsider,
    chapter: 5,
    seconds: 40,
    kicker: 'REVISIT THE REASONS',
    decision: '採用・見送り・検討中を分けて残す',
    reason: '選んだものだけでなく、なぜ見送ったかも残しておきたい。\n\n条件や自分の理解が変わったら、当時の理由を読み直す材料になる。',
    tradeoff: '迷いを記録したことと、採用を変更したことは分けて伝える。',
    sourceLabel: '本人の選定メモ / technical-decisions.md',
    sourceUrl: '$_source/docs/technical-decisions.md#L1-L18',
    items: [
      '採用：altive_lints',
      '検討中：very_good_analysis',
      '見送り：Flutter公式AIルール',
      '検討中：ドキュメントの保守方法',
    ],
    notes: '''選定メモの冒頭には、将来の自分が判断基準をたどれるように、なぜ選ばなかったかも残すと書きました。実際、Lintはaltive_lintsを採用していますが、エージェント時代にはvery_good_analysisの方がよいかもしれない、と迷い始めた記録があります。ハーネスやドキュメントの保守にも迷いが残っています。迷いがあることと、採用を変更したことは別です。条件が変わったときに読み直せるよう、今の判断と候補を区別して残したいです。

出典：docs/technical-decisions.md 冒頭1–18行、「altive_lints」176–184行、docs/retrospective.md:29–37。条件が変わったときに理由を読み直す、という締め方は記録をもとにした発表用の提案です。very_good_analysisやSerenaへの移行は実施済みとして扱いません。''',
  ),
  ReasonPage(
    route: '/takeaway',
    title: '今回は、\nこういう理由で選んだ',
    kind: ReasonKind.takeaway,
    chapter: 5,
    seconds: 40,
    kicker: 'TAKEAWAY',
    lead: '次の選択で、一文だけでも残してみる。',
    reason: '何をしたくて、その道具を選んだのか。\n\n自分の言葉で残しておくと、次の自分が判断を振り返れる。',
    sourceLabel: '発表用の提案 / retrospective.mdを参照',
    sourceUrl: '$_source/docs/retrospective.md#L56-L62',
    items: ['選んだもの', '自分の理由', '見送ったもの', '見直したい条件'],
    notes: '''今日持ち帰っていただきたいのは、選んだ技術の名前だけでなく、自分の理由を残すことです。何をしたかったのか。今回の条件にどう合っていたのか。見送ったものは何か。次に一つ選んだときに、今回はこういう理由で選んだ、と一文だけでも書いてみてください。私にとって、頭の中を整理する取り組みは疲れるけれど楽しいものでした。少し先の未来でも、また振り返ってみたいです。ありがとうございました。

出典：docs/technical-decisions.md 冒頭、docs/retrospective.md「さいごに」56–62行。一文を残すという行動は、この発表からの提案です。ここで本編は終了。参照資料と補足は時間外の質疑用です。''',
  ),
  ReasonPage(
    route: '/references',
    title: '理由の原文へ',
    kind: ReasonKind.references,
    chapter: 0,
    seconds: 0,
    kicker: 'REFERENCES',
    lead: '本人の記録と、実装の方針を分けて参照する。',
    sourceLabel: 'material_github_searcher / 57d9662',
    sourceUrl: '$_source/docs/technical-decisions.md',
    items: [
      '本人の記録：technical-decisions.md',
      '本人の記録：retrospective.md',
      '実装方針：ARCHITECTURE.md / testing.md',
      'UI方針：design.md / 実装一覧：README.md',
    ],
    notes:
        '''本編では読み上げません。技術選定と振り返りは、本人が判断して記録した資料です。デザイン方針、アーキテクチャ、テスト方針は、プロジェクトの実装を説明する資料として区別して参照しました。このスライド資料の文章は、原文をもとにした発表用の再構成です。本人の記録自体は編集していません。

固定リビジョン：57d9662dcdbfe1a93e6bb0b4706bfa778db8ba05
技術選定：$_source/docs/technical-decisions.md
振り返り：$_source/docs/retrospective.md
UI方針：$_source/docs/design.md
構造：$_source/docs/ARCHITECTURE.md
テスト：$_source/docs/testing.md
実装一覧：$_source/README.md

Flutterの実演は説明用に再構成した小さなサンプルです。元アプリのAPIや永続化には接続しません。Slangは実際のパッケージと生成コードを使用します。''',
  ),
  ReasonPage(
    route: '/appendix',
    title: 'ほかにも、\nこんな理由を残した',
    kind: ReasonKind.appendix,
    chapter: 0,
    seconds: 0,
    kicker: 'APPENDIX / Q & A',
    lead: '運用の小さな選択にも、自分の理由がある。',
    sourceLabel: '本人の選定メモ / technical-decisions.md',
    sourceUrl: '$_source/docs/technical-decisions.md#L124-L207',
    items: [
      'Flavor：公式仕様に沿い、設定の齟齬は起動時に検査',
      'GitHub Flow：個人開発なのでmainと作業ブランチ',
      'CSpell：指示の誤字を増やし続けないよう検知',
      'CodeRabbit：Draftをスキップし、レビュー依頼を調整',
    ],
    notes: '''質疑用です。本編では読み上げません。

Flavor：以前好んでいた方式を改めて調べ、自前ビルドスクリプトより各ライブラリの公式仕様に沿う方を選びました。productFlavorsとdart-define-from-fileの齟齬はAppBuildConfigの初期化で検査しています。iOSはアプリ名やIDの二重管理を避けるため、デコード方式を維持しました。出典：docs/technical-decisions.md:124–135。

GitHub Flow：完全な個人プロジェクトなのでmainと作業ブランチで運用し、developは設けていません。出典：同139–146行。

CSpell：人が書いた指示をモデルがそのまま受け取り、誤字を増やし続けることを検知するために必要と考えました。出典：同186–195行。

CodeRabbit：個人開発のOSSで活用。基盤や複雑な機能ではDraft PRから人力レビューを経て依頼したいので、Draftはスキップする設定です。出典：同197–207行。レビューによる削減率や品質の数値は記録にないため示しません。''',
  ),
];
