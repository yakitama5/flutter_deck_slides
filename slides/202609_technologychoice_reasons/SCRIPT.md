# 読み上げ原稿と時間配分

『技術選定に 自分の理由を』／コーディング試験の選定理由と振り返り

全22枚。本編20枚は11分（660秒）の目安で、場面転換とデモ操作を含みます。
21・22枚目は時間外の参照資料・質疑用です。出典や補足は原稿確認用で、読み上げません。
本文は本人の記録をもとにした発表用の草案です。

| 枚 | 時刻 | 秒 | スライド |
| --- | --- | --- | --- |
| 01 | 00:00–00:15 | 15 | 技術選定に 自分の理由を |
| 02 | 00:15–00:30 | 15 | 選んだ順より、 理由のまとまりで |
| 03 | 00:30–01:05 | 35 | 何をアピールしたかったか |
| 04 | 01:05–01:15 | 10 | 設計を選ぶ |
| 05 | 01:15–02:10 | 55 | 生成が速くても、 置き場所は迷わせない |
| 06 | 02:10–02:45 | 35 | 標準で足りるなら、 そこで始める |
| 07 | 02:45–02:55 | 10 | 開発環境を選ぶ |
| 08 | 02:55–03:35 | 40 | 並列に進めやすい 道具をそろえる |
| 09 | 03:35–04:10 | 35 | やってみたかった、 も理由になる |
| 10 | 04:10–04:20 | 10 | 品質の守り方を選ぶ |
| 11 | 04:20–05:05 | 45 | 進め方を、 固定しすぎない |
| 12 | 05:05–05:50 | 45 | 納得できるルールを、 仕組みで確かめる |
| 13 | 05:50–06:00 | 10 | UIを選ぶ |
| 14 | 06:00–07:05 | 65 | 好きなデザインに、 判断の拠り所がある |
| 15 | 07:05–08:00 | 55 | 端末名より、 いま使える幅を見る |
| 16 | 08:00–08:50 | 50 | 言葉を、 画面の外で管理する |
| 17 | 08:50–09:00 | 10 | 判断を振り返る |
| 18 | 09:00–09:40 | 40 | 要件には過剰でも、 残したい判断だった |
| 19 | 09:40–10:20 | 40 | 迷いも、 選定理由の一部にする |
| 20 | 10:20–11:00 | 40 | 今回は、 こういう理由で選んだ |
| 21 | 時間外 | 0 | 理由の原文へ |
| 22 | 時間外 | 0 | ほかにも、 こんな理由を残した |

## 01 技術選定に 自分の理由を

00:00–00:15（15秒）／`/cover`

やくらんです。今日は、GitHubのリポジトリを検索するFlutterアプリのコーディング試験で、私が何を選び、なぜそうしたかを話します。UIで確かめられる部分は、横の小さなサンプルを動かして紹介します。

出典：README.md 冒頭、docs/technical-decisions.md、docs/retrospective.md。
実演はこの発表向けのミニサンプル。試験アプリ全体を埋め込んだものではありません。

## 02 選んだ順より、 理由のまとまりで

00:15–00:30（15秒）／`/agenda`

設計、開発環境、品質、UI、そして振り返りの五つです。各章で、選んだものと理由を並べます。採らなかったものや、まだ迷っているところも、そのまま紹介します。

本編は20枚・約11分。21枚目は参照資料、22枚目は質疑用の補足です。

## 03 何をアピールしたかったか

00:30–01:05（35秒）／`/intention`

最初にアピールしたかったのは、この四つでした。AIが生成するコードをどこまで人が細かく確認するかは、悩ましいと感じています。そこで今回は、生成の速度に耐える構造と、品質を守る仕組みを強く意識しました。デザインにもアピールしたい部分はありましたが、優先順位をつけて後回しにしています。

出典：docs/retrospective.md「最初に何をアピールしようと考えたか」10–21行。ここは本人の記録の要約です。成果の速度や不具合率を測った数値としては提示しません。

[参照原文：本人の振り返り / retrospective.md](https://github.com/yakitama5/material_github_searcher/blob/57d9662dcdbfe1a93e6bb0b4706bfa778db8ba05/docs/retrospective.md#L10-L21)

## 04 設計を選ぶ

01:05–01:15（10秒）／`/chapter/design`

まず設計です。AIが速くコードを書いても、どこに何があり、どこまで変更するかを判断できる構造にしたいと考えました。

## 05 生成が速くても、 置き場所は迷わせない

01:15–02:10（55秒）／`/reasons/architecture`

オニオンアーキテクチャと、レイヤーを先に分ける構成を選びました。個人的には必要十分で、レイヤーをまたがなければ大きなリファクタリングを避けやすいと考えています。人にもAIにも、どこに何があるかが伝わることを重視しました。業務では機能を横断する処理や責務の変化も多いため、layer firstにしています。ただし、この試験の要件ならfeature firstでも問題ないと記録しました。

右の図では、業務ルールと抽象を内側に置き、外部サービスの実装を分ける関係を示します。実際のリポジトリでは、Providerのoverrideによる結線と、パッケージ依存のCI検査を用意しています。

出典：docs/technical-decisions.md「オニオンアーキテクチャ」「パッケージ構成」46–67行。実装の裏付け：docs/ARCHITECTURE.md「依存関係の機械的な保証」57–67行、「依存性逆転と実装の結線」120–143行。図は説明のために簡略化しています。

[参照原文：本人の選定メモ / technical-decisions.md](https://github.com/yakitama5/material_github_searcher/blob/57d9662dcdbfe1a93e6bb0b4706bfa778db8ba05/docs/technical-decisions.md#L36-L67)

## 06 標準で足りるなら、 そこで始める

02:10–02:45（35秒）／`/reasons/workspace`

パッケージ管理にはPub Workspaceを使い、試験ではMelosを採りませんでした。依存が増えること自体より、固有の知識を新しい人へ伝えるコストが気になっています。ただ、Melosをいつでも使わないわけではありません。パッケージ間のバージョン管理や並列実行とのバランスによっては採用する、と同じメモに残しました。道具への好みと、今回の条件での判断は分けておきたいです。

出典：docs/technical-decisions.md「パッケージ構成 / 採らなかった選択肢」69–74行。採用状況：docs/ARCHITECTURE.md「Pub Workspaceを利用する方針」69–83行。スライド集自体はMelosを利用していますが、ここは試験アプリの選定を説明しています。

[参照原文：本人の選定メモ / technical-decisions.md](https://github.com/yakitama5/material_github_searcher/blob/57d9662dcdbfe1a93e6bb0b4706bfa778db8ba05/docs/technical-decisions.md#L69-L74)

## 07 開発環境を選ぶ

02:45–02:55（10秒）／`/chapter/environment`

次は開発環境です。並列に作業を進めやすいことと、まだ使ったことがないものを試すこと。その両方が理由になりました。

## 08 並列に進めやすい 道具をそろえる

02:55–03:35（40秒）／`/reasons/environment`

SDK管理は、もともとFVMを使っていましたが、Tasksなどの利便性もあってmiseへ移っています。並列開発ではGit worktreeやgtrが便利です。並列でなくても、作業のディレクトリを分けると進めやすいと感じています。エディタやターミナルも軽量な構成を好み、Zedは配置を見たり気になる部分を直したりするときに使うことが多いです。一方で、worktreeはディスクを使います。作ることと片付けることを一緒に考えています。

出典：docs/technical-decisions.md「mise」84–87行、「開発環境」108–113行、「Git Worktree」119–122行。これらの道具の一般的な性能比較を主張するスライドではなく、本人の使い方と選定理由です。

[参照原文：本人の選定メモ / technical-decisions.md](https://github.com/yakitama5/material_github_searcher/blob/57d9662dcdbfe1a93e6bb0b4706bfa778db8ba05/docs/technical-decisions.md#L76-L122)

## 09 やってみたかった、 も理由になる

03:35–04:10（35秒）／`/reasons/spm`

SPMを選んだ理由には、まだ対応していなかったのでやってみたかった、と書きました。個人開発でも業務でも未経験だったので、この機会に試したかったんです。過去のCocoaPods周りの苦労から解放されたいという思いもありました。同時に、未対応のパッケージがまだ多そうだという懸念も記録しています。これは選定した時点での見立てです。学ぶことも目的に入っているなら、試したい気持ちも理由になると思います。

出典：docs/technical-decisions.md「SPM」89–98行。現在のエコシステム全体の対応率や、導入による作業時間削減の実測は示しません。Webスライド内でSPMそのものは実行しません。

[参照原文：本人の選定メモ / technical-decisions.md](https://github.com/yakitama5/material_github_searcher/blob/57d9662dcdbfe1a93e6bb0b4706bfa778db8ba05/docs/technical-decisions.md#L89-L98)

## 10 品質の守り方を選ぶ

04:10–04:20（10秒）／`/chapter/quality`

品質の守り方にも選択があります。モデルや進め方が変わっても、プロジェクトとして何を守りたいかを考えました。

## 11 進め方を、 固定しすぎない

04:20–05:05（45秒）／`/reasons/harness`

実装中に一番悩んだのは、ハーネス設計でした。個人的には、モデルが進化するたびにハーネスを再生成するのが最適ではないかと考えています。そのため、Flutter公式のAIルールは入れていません。ただ、何も書かなくてよいとも思っていません。このプロジェクトに必要だと判断した基盤とルールは残しました。進め方は推奨として記載していますが、細かく強制する設計にはしていません。ドキュメントをどう保守するか、Serenaなどへまとめる方がよいかは、最後まで迷った部分です。

出典：docs/retrospective.md「実装中に一番難しかったこと」23–37行、docs/technical-decisions.md「Claude Code / Codex」28–34行、docs/agent-driven-development.md 冒頭。Serenaへの移行や全ドキュメント削除は実施済みではなく、検討中の考えです。

[参照原文：本人の振り返り / retrospective.md](https://github.com/yakitama5/material_github_searcher/blob/57d9662dcdbfe1a93e6bb0b4706bfa778db8ba05/docs/retrospective.md#L23-L37)

## 12 納得できるルールを、 仕組みで確かめる

05:05–05:50（45秒）／`/reasons/quality`

Lintにはaltive_lintsを選びました。過剰すぎず納得できるルールであることと、早くAnalyzer Pluginsへ移行していたことに信頼を感じています。仕組みとしては、変更した振る舞いのテストと、パッケージ依存の検査を重ねました。外部サービスは決定的なFakeへ差し替えます。一方、全部をCIに入れているわけではありません。GoldenはOS間の描画差があり、Patrolは実機やSimulatorが必要なので、ローカル実行です。CIには高速で安定して確かめられるものを置いています。

出典：本人の理由はdocs/technical-decisions.md「altive_lints」176–184行、「PR Check」213–217行。テスト方針はdocs/testing.md「基本方針」8–21行、「実行方法とローカル/CIの境界」113–119行。実際のチェック対象はREADME.md:166。CIでGoldenやPatrolを実行した、あるいは不具合率が下がったという主張はしません。

[参照原文：選定・方針 / technical-decisions.md・testing.md](https://github.com/yakitama5/material_github_searcher/blob/57d9662dcdbfe1a93e6bb0b4706bfa778db8ba05/docs/technical-decisions.md#L168-L217)

## 13 UIを選ぶ

05:50–06:00（10秒）／`/chapter/ui`

ここからはUIです。自分の好みも大切にしながら、配色、画面幅、言語をどう扱ったかを、Flutterのサンプルで見ていきます。

## 14 好きなデザインに、 判断の拠り所がある

06:00–07:05（65秒）／`/reasons/theme`

Material 3は、Androidユーザーということもあって、かなり好みです。選定メモには、少数派への考慮がしっかりしていて、配色ルールも分かりやすいと書きました。好きだから選ぶことと、説明できるルールがあることが、つながっています。

【実演】青と紫のSeedを切り替えます。次にLightとDarkを切り替えます。同じ画面でも、色の役割をColorSchemeから受け取れば、まとめて追従します。このサンプルはFlutterのColorScheme.fromSeedを実際に使っています。試験アプリはOSのDynamic Colorにも対応していますが、ここではブラウザで再現できるSeedと明暗を見せています。

出典：本人の理由はdocs/technical-decisions.md「Material 3」249–251行。実装方針はdocs/design.md「Theme」17–38行。デザインを優先し切れなかった振り返りはdocs/retrospective.md:53–54。サンプルでOS Dynamic Colorそのものやアクセシビリティ適合性を検証したとは扱いません。

[参照原文：本人の選定メモ / technical-decisions.md](https://github.com/yakitama5/material_github_searcher/blob/57d9662dcdbfe1a93e6bb0b4706bfa778db8ba05/docs/technical-decisions.md#L243-L256)

## 15 端末名より、 いま使える幅を見る

07:05–08:00（55秒）／`/reasons/responsive`

ここは本人の選定メモではなく、プロジェクトに記載したデザイン方針です。端末名ではなく利用可能幅で判断し、画面全体はMediaQuery、Widget内部の折り返しはLayoutBuilderを使う方針にしています。今回の範囲は標準APIで収まるため、responsive_frameworkは入れていません。

【実演】サンプルの幅を390、720、1024 dpへ切り替えます。コンパクトでは下のNavigationBar、広がるとNavigationRail、さらに広い場合はラベル付きのRailへ変わります。サンプルの見た目は発表用に再構成しています。試験アプリでも同じ三段階でナビゲーションを切り替えます。

出典：docs/design.md「レスポンシブ対応」72–120行。動作の裏付け：apps/app/lib/src/navigation/adaptive_app_shell.dart:49–71。Webは試験アプリの正式配布対象ではなく、確認用途です。サンプルは各幅をローカルに再現します。

[参照原文：プロジェクトのデザイン方針 / design.md](https://github.com/yakitama5/material_github_searcher/blob/57d9662dcdbfe1a93e6bb0b4706bfa778db8ba05/docs/design.md#L72-L120)

## 16 言葉を、 画面の外で管理する

08:00–08:50（50秒）／`/reasons/localization`

多言語化にはSlangを選びました。理由の一つはYAMLの管理しやすさです。もう一つは、単純な文字列以外にも、Enumや数に応じた設定へ広げられる柔軟さでした。

【実演】日本語と英語を切り替えます。検索案内や操作の文言が、同じ画面構成のまま変わります。次に件数を0、1、2へ切り替え、英語の1 repository foundと2 repositories foundを確かめます。これは説明用に加えたサンプル専用の複数形です。実際のSlangパッケージとYAMLからの生成コードを使っています。試験アプリも日本語・英語に対応していますが、この複数形の件数UIを本番に実装していたとは扱いません。

出典：docs/technical-decisions.md「Slang」238–241行。採用状況：README.md:80。文言の参照：apps/app/assets/i18n/repositorySearch_ja.i18n.yaml、repositorySearch_en.i18n.yaml。資料専用の操作ラベルはサンプル用に追加した文言です。

[参照原文：本人の選定メモ / technical-decisions.md](https://github.com/yakitama5/material_github_searcher/blob/57d9662dcdbfe1a93e6bb0b4706bfa778db8ba05/docs/technical-decisions.md#L230-L241)

## 17 判断を振り返る

08:50–09:00（10秒）／`/chapter/retrospective`

最後に振り返りです。よかったと思う選択だけでなく、過剰だったところや迷いも、次の自分へ残しました。

## 18 要件には過剰でも、 残したい判断だった

09:00–09:40（40秒）／`/retrospective/investment`

振り返りには、要件からするとだいぶ過剰な設計になったと書いています。基盤やCI/CD、デザインに関する設定機能も、作り込みすぎたと思いました。それでも、今後の業務で採用するであろう設計を、自分のセーブポイントとして形にしたかったんです。一方、見積もりの甘さは反省点です。デザインももう少しこだわりたかった。全部を成功談にせず、何に投資して、何が残ったかを記録しました。

出典：docs/retrospective.md「過剰だったと感じる部分」39–46行、「もう一度作るなら何を簡略化・変更するか」48–54行。作業時間やコストの比較数値は記録にないため提示しません。

[参照原文：本人の振り返り / retrospective.md](https://github.com/yakitama5/material_github_searcher/blob/57d9662dcdbfe1a93e6bb0b4706bfa778db8ba05/docs/retrospective.md#L39-L54)

## 19 迷いも、 選定理由の一部にする

09:40–10:20（40秒）／`/retrospective/reconsider`

選定メモの冒頭には、将来の自分が判断基準をたどれるように、なぜ選ばなかったかも残すと書きました。実際、Lintはaltive_lintsを採用していますが、エージェント時代にはvery_good_analysisの方がよいかもしれない、と迷い始めた記録があります。ハーネスやドキュメントの保守にも迷いが残っています。迷いがあることと、採用を変更したことは別です。条件が変わったときに読み直せるよう、今の判断と候補を区別して残したいです。

出典：docs/technical-decisions.md 冒頭1–18行、「altive_lints」176–184行、docs/retrospective.md:29–37。条件が変わったときに理由を読み直す、という締め方は記録をもとにした発表用の提案です。very_good_analysisやSerenaへの移行は実施済みとして扱いません。

[参照原文：本人の選定メモ / technical-decisions.md](https://github.com/yakitama5/material_github_searcher/blob/57d9662dcdbfe1a93e6bb0b4706bfa778db8ba05/docs/technical-decisions.md#L1-L18)

## 20 今回は、 こういう理由で選んだ

10:20–11:00（40秒）／`/takeaway`

今日持ち帰っていただきたいのは、選んだ技術の名前だけでなく、自分の理由を残すことです。何をしたかったのか。今回の条件にどう合っていたのか。見送ったものは何か。次に一つ選んだときに、今回はこういう理由で選んだ、と一文だけでも書いてみてください。私にとって、頭の中を整理する取り組みは疲れるけれど楽しいものでした。少し先の未来でも、また振り返ってみたいです。ありがとうございました。

出典：docs/technical-decisions.md 冒頭、docs/retrospective.md「さいごに」56–62行。一文を残すという行動は、この発表からの提案です。ここで本編は終了。参照資料と補足は時間外の質疑用です。

[参照原文：発表用の提案 / retrospective.mdを参照](https://github.com/yakitama5/material_github_searcher/blob/57d9662dcdbfe1a93e6bb0b4706bfa778db8ba05/docs/retrospective.md#L56-L62)

## 21 理由の原文へ

時間外・質疑用／`/references`

本編では読み上げません。技術選定と振り返りは、本人が判断して記録した資料です。デザイン方針、アーキテクチャ、テスト方針は、プロジェクトの実装を説明する資料として区別して参照しました。このスライド資料の文章は、原文をもとにした発表用の再構成です。本人の記録自体は編集していません。

固定リビジョン：57d9662dcdbfe1a93e6bb0b4706bfa778db8ba05
技術選定：https://github.com/yakitama5/material_github_searcher/blob/57d9662dcdbfe1a93e6bb0b4706bfa778db8ba05/docs/technical-decisions.md
振り返り：https://github.com/yakitama5/material_github_searcher/blob/57d9662dcdbfe1a93e6bb0b4706bfa778db8ba05/docs/retrospective.md
UI方針：https://github.com/yakitama5/material_github_searcher/blob/57d9662dcdbfe1a93e6bb0b4706bfa778db8ba05/docs/design.md
構造：https://github.com/yakitama5/material_github_searcher/blob/57d9662dcdbfe1a93e6bb0b4706bfa778db8ba05/docs/ARCHITECTURE.md
テスト：https://github.com/yakitama5/material_github_searcher/blob/57d9662dcdbfe1a93e6bb0b4706bfa778db8ba05/docs/testing.md
実装一覧：https://github.com/yakitama5/material_github_searcher/blob/57d9662dcdbfe1a93e6bb0b4706bfa778db8ba05/README.md

Flutterの実演は説明用に再構成した小さなサンプルです。元アプリのAPIや永続化には接続しません。Slangは実際のパッケージと生成コードを使用します。

[参照原文：material_github_searcher / 57d9662](https://github.com/yakitama5/material_github_searcher/blob/57d9662dcdbfe1a93e6bb0b4706bfa778db8ba05/docs/technical-decisions.md)

## 22 ほかにも、 こんな理由を残した

時間外・質疑用／`/appendix`

質疑用です。本編では読み上げません。

Flavor：以前好んでいた方式を改めて調べ、自前ビルドスクリプトより各ライブラリの公式仕様に沿う方を選びました。productFlavorsとdart-define-from-fileの齟齬はAppBuildConfigの初期化で検査しています。iOSはアプリ名やIDの二重管理を避けるため、デコード方式を維持しました。出典：docs/technical-decisions.md:124–135。

GitHub Flow：完全な個人プロジェクトなのでmainと作業ブランチで運用し、developは設けていません。出典：同139–146行。

CSpell：人が書いた指示をモデルがそのまま受け取り、誤字を増やし続けることを検知するために必要と考えました。出典：同186–195行。

CodeRabbit：個人開発のOSSで活用。基盤や複雑な機能ではDraft PRから人力レビューを経て依頼したいので、Draftはスキップする設定です。出典：同197–207行。レビューによる削減率や品質の数値は記録にないため示しません。

[参照原文：本人の選定メモ / technical-decisions.md](https://github.com/yakitama5/material_github_searcher/blob/57d9662dcdbfe1a93e6bb0b4706bfa778db8ba05/docs/technical-decisions.md#L124-L207)
