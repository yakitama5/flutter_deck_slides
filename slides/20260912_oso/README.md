# リスくんと ひとつのどんぐり

Issue #28で作成した絵本候補から、ひとまず選定した画像を並べたFlutterDeckです。
スピーカーノートは未設定です。

## ページ構成

- 表紙: `../2026_oso_risukun_hitotsu_no_donguri/generation/refs/cover_master.png`
- page01: ロック済み `../2026_oso_risukun_hitotsu_no_donguri/generation/refs/page01_master.png`
- page02: `variant_c`
- page03: `variant_b`
- page04: `variant_c`
- page05: `variant_a`
- page06: `variant_a`
- page07: `variant_b`
- page08: `variant_a`
- page09: `variant_b`
- page10: `variant_a`
- page11: `variant_c`

採用画像は `assets/risukun_hitotsu_no_donguri/` にコピーしています。
候補画像・コンタクトシートの原本は、
`slides/2026_oso_risukun_hitotsu_no_donguri/generation/output/` に残しています。

## 起動

```sh
dart run melos run dev
```

起動後、対象パッケージとして `slides/20260912_oso` を選択します。
