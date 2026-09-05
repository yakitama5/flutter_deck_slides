# Issue #28 review snapshot

2026-09-02時点のサブスク内蔵ImageGenによる確認用スナップショットです。
page02〜page11について、各3候補（合計30枚）を生成しています。

各コンタクトシートを開いて候補を比較し、必要なら個別候補のリンクから原寸画像を
確認してください。元候補と過去の試行を分けるため、`attempts/` はGitHubへは公開
していません。

| ページ | 比較用コンタクトシート | 個別候補 |
| --- | --- | --- |
| page02 | [contact sheet](../output/page02/contact_sheet.png) | [a](../output/page02/variant_a.png) · [b](../output/page02/variant_b.png) · [c](../output/page02/variant_c.png) |
| page03 | [contact sheet](../output/page03/contact_sheet.png) | [a](../output/page03/variant_a.png) · [b](../output/page03/variant_b.png) · [c](../output/page03/variant_c.png) |
| page04 | [contact sheet](../output/page04/contact_sheet.png) | [a](../output/page04/variant_a.png) · [b](../output/page04/variant_b.png) · [c](../output/page04/variant_c.png) |
| page05 | [contact sheet](../output/page05/contact_sheet.png) | [a](../output/page05/variant_a.png) · [b](../output/page05/variant_b.png) · [c](../output/page05/variant_c.png) |
| page06 | [contact sheet](../output/page06/contact_sheet.png) | [a](../output/page06/variant_a.png) · [b](../output/page06/variant_b.png) · [c](../output/page06/variant_c.png) |
| page07 | [contact sheet](../output/page07/contact_sheet.png) | [a](../output/page07/variant_a.png) · [b](../output/page07/variant_b.png) · [c](../output/page07/variant_c.png) |
| page08 | [contact sheet](../output/page08/contact_sheet.png) | [a](../output/page08/variant_a.png) · [b](../output/page08/variant_b.png) · [c](../output/page08/variant_c.png) |
| page09 | [contact sheet](../output/page09/contact_sheet.png) | [a](../output/page09/variant_a.png) · [b](../output/page09/variant_b.png) · [c](../output/page09/variant_c.png) |
| page10 | [contact sheet](../output/page10/contact_sheet.png) | [a](../output/page10/variant_a.png) · [b](../output/page10/variant_b.png) · [c](../output/page10/variant_c.png) |
| page11 | [contact sheet](../output/page11/contact_sheet.png) | [a](../output/page11/variant_a.png) · [b](../output/page11/variant_b.png) · [c](../output/page11/variant_c.png) |

採用した候補を最終アセットへ反映する場合は、ローカルでレビュー後に
`imagegen_queue.py adopt --page <page> --variant <a|b|c>` を実行します。
