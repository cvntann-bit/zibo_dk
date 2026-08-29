// Tek seferlik/tekrar-kullanılabilir yardımcı betik: `lib/data/zibo_messages.dart`'taki
// (uygulamanın GERÇEK, tam) TR/EN/ES 279'luk söz havuzlarını okuyup
// `notification-scripts/src/content.js`'in `daily_motivation` bloğunun içine
// yazılacak JS dizi literallerini üretir — bkz. CLAUDE.md "Push Bildirimleri"
// bölümündeki bug raporu: content.js eskiden yalnızca 8/dil'lik küçük bir
// temsili alt küme kullanıyordu, bu da bildirimlerde aynı sözlerin sık sık
// tekrar etmesine yol açıyordu.
//
// `zibo_messages.dart` `package:flutter/material.dart` import ettiği için bu
// betik onu DOĞRUDAN import ETMİYOR (plain `dart run`, Flutter framework'ünü
// çözemiyor/çöküyor) — bunun yerine kaynak dosyayı DÜZ METİN olarak okuyup
// `const ziboMessagesXx = <String>[ ... ];` bloklarını basit bir satır
// ayrıştırıcıyla çıkarıyor (dosyanın biçimi sabit: her söz TEK satırda, tek
// tırnaklı, `',` ile biten bir Dart string literali). Çıktı `jsonEncode` ile
// üretiliyor (JSON string literalleri her zaman geçerli JS string
// literalleridir) — elle 837 satır kopyalamaktan çok daha güvenilir/hatasız.
//
// Kullanım: `dart run tool/generate_content_js_daily_motivation.dart` — çıktıyı
// stdout'a yazar. Havuz ileride tekrar büyürse bu betik aynen tekrar
// çalıştırılabilir.

import 'dart:convert';
import 'dart:io';

final _listStart = RegExp(r'^const (ziboMessages(Tr|En|Es)) = <String>\[\s*$');
final _singleQuotedLine = RegExp(r"^\s*'((?:[^'\\]|\\.)*)',\s*$");
final _doubleQuotedLine = RegExp(r'^\s*"((?:[^"\\]|\\.)*)",\s*$');

Map<String, List<String>> _extractLists(String source) {
  final result = <String, List<String>>{};
  String? currentKey;
  List<String>? currentList;
  for (final rawLine in const LineSplitter().convert(source)) {
    final startMatch = _listStart.firstMatch(rawLine);
    if (startMatch != null) {
      currentKey = startMatch.group(1);
      currentList = <String>[];
      continue;
    }
    if (currentList != null) {
      final trimmed = rawLine.trim();
      if (trimmed == '];') {
        result[currentKey!] = currentList;
        currentKey = null;
        currentList = null;
        continue;
      }
      // Liste içi Türkçe dokümantasyon yorumları (bkz. ör. ziboMessagesEn'in
      // ortasındaki "2026 güncellemesi..." bloğu) — söz DEĞİL, atla.
      if (trimmed.isEmpty || trimmed.startsWith('//')) {
        continue;
      }
      final singleMatch = _singleQuotedLine.firstMatch(rawLine);
      final doubleMatch = _doubleQuotedLine.firstMatch(rawLine);
      if (singleMatch == null && doubleMatch == null) {
        stderr.writeln('Beklenmeyen satır ($currentKey): $rawLine');
        exit(1);
      }
      final raw = (singleMatch ?? doubleMatch)!.group(1)!;
      // Dosyada doğrulanan (grep) kaçış türleri: \' (11 kez, tek-tırnaklı
      // satırlarda iç apostrof) ve \" (2 kez, çift-tırnaklı TEK bir satırda
      // iç tırnak) — genel bir `\X -> X` unescape İKİSİNİ de doğru çözer.
      currentList.add(raw.replaceAllMapped(RegExp(r'\\(.)'), (m) => m.group(1)!));
    }
  }
  return result;
}

String _jsArray(List<String> messages, String indent) {
  final buffer = StringBuffer('[\n');
  for (final message in messages) {
    buffer.writeln('$indent  ${jsonEncode(message)},');
  }
  buffer.write('$indent]');
  return buffer.toString();
}

void main() {
  final source = File('lib/data/zibo_messages.dart').readAsStringSync();
  final lists = _extractLists(source);
  final tr = lists['ziboMessagesTr'];
  final en = lists['ziboMessagesEn'];
  final es = lists['ziboMessagesEs'];
  if (tr == null || en == null || es == null) {
    stderr.writeln('Bir veya daha fazla liste bulunamadı: ${lists.keys}');
    exit(1);
  }
  if (tr.length != en.length || en.length != es.length) {
    stderr.writeln('Uzunluklar eşit değil: tr=${tr.length} en=${en.length} es=${es.length}');
    exit(1);
  }
  final buffer = StringBuffer();
  buffer.writeln('const daily_motivation = {');
  buffer.writeln('  tr: ${_jsArray(tr, '  ')},');
  buffer.writeln('  en: ${_jsArray(en, '  ')},');
  buffer.writeln('  es: ${_jsArray(es, '  ')},');
  buffer.writeln('};');
  // ignore: avoid_print
  print(buffer.toString());
  stderr.writeln('OK — ${tr.length} söz/dil çıkarıldı.');
}
