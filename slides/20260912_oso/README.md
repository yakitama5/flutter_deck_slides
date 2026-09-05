# リスくんと ひとつのどんぐり

Issue #28で作成した絵本候補から、ひとまず選定した画像を並べたFlutterDeckです。
スピーカーノートは未設定です。

## ページ構成

- 外側の表紙: Flutterロゴ + タイトル
- 01: 旧表紙絵 `cover_master.png`（カバーをめくった後のタイトルページ）
- 02: ロック済み `page01_master.png`
- 03: `page02` の `variant_c`
- 04: `page03` の `variant_b`
- 05: `page04` の `variant_c`
- 06: `page05` の `variant_a`
- 07: `page06` の `variant_a`
- 08: `page07` の `variant_b`
- 09: `page08` の `variant_a`
- 10: `page09` の `variant_b`
- 11: `page10` の `variant_a`
- 12: `page11` の `variant_c` + 「おしまい」リボン

採用画像は `assets/risukun_hitotsu_no_donguri/` にコピーしています。リボン付きの最終ページは
`11_page11_ending.png` として元画像を残したまま追加しています。
候補画像・コンタクトシートの原本は、
`slides/2026_oso_risukun_hitotsu_no_donguri/generation/output/` に残しています。

## 起動

```sh
dart run melos run dev
```

起動後、対象パッケージとして `slides/20260912_oso` を選択します。
