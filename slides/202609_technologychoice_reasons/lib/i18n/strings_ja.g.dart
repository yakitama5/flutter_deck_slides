///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:slang/generated.dart';
import 'strings.g.dart';

// Path: <root>
class TranslationsJa with BaseTranslations<AppLocale, Translations> implements Translations {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsJa({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  _meta = meta ?? TranslationMetadata(
		    locale: AppLocale.ja,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		_meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <ja>.
	final TranslationMetadata<AppLocale, Translations> _meta;
	@override TranslationMetadata<AppLocale, Translations> get $meta => _meta;

	/// Access flat map
	@override dynamic operator[](String key) => _meta.getTranslation(key);

	late final TranslationsJa _root = this; // ignore: unused_field

	@override
	TranslationsJa $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsJa(meta: meta ?? this.$meta);

	// Translations
	@override String get search => 'リポジトリを検索';
	@override String get query => 'Flutter UI';
	@override String result({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ja'))(count,
		other: '${count} 件のリポジトリが見つかりました',
	);
	@override String get saved => '保存済み';
	@override String get open => 'リポジトリを見る';
	@override String get language => '日本語';
	@override String get empty => '別のキーワードで試してみましょう。';
}

/// The flat map containing all translations for locale <ja>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsJa {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'search' => 'リポジトリを検索',
			'query' => 'Flutter UI',
			'result' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ja'))(count, other: '${count} 件のリポジトリが見つかりました', ),
			'saved' => '保存済み',
			'open' => 'リポジトリを見る',
			'language' => '日本語',
			'empty' => '別のキーワードで試してみましょう。',
			_ => null,
		};
	}
}
