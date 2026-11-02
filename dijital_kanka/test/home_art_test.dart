// Zibo Dünyası Faz 2 (docs/zibo_world_roadmap.md): kodla çizilen odalar.
// Katalogdaki her eşyanın bir çizimi olmalı; her eşya seçimiyle sahne
// hatasız, iyi biçimli SVG üretmeli.

import 'package:flutter_test/flutter_test.dart';

import 'package:dijital_kanka/data/home_catalog.dart';
import 'package:dijital_kanka/models/home_item.dart';
import 'package:dijital_kanka/widgets/home_art/furniture_art.dart';
import 'package:dijital_kanka/widgets/home_art/room_art.dart';
import 'package:dijital_kanka/widgets/home_art/surface_art.dart';
import 'package:dijital_kanka/widgets/home_art/svg_kit.dart';

Map<String, HomeItem> _defaults(HomeRoomDef def) => {
  for (final c in def.categories) c.id: c.item(def.defaults[c.id] ?? '') ?? c.items.first,
};

/// Etiketlerin açılıp kapandığını kabaca doğrular (`<x .../>` ya da `<x>…</x>`).
void _expectBalanced(String svg) {
  final stack = <String>[];
  for (final m in RegExp(r'<(/?)([a-zA-Z]+)[^>]*?(/?)>').allMatches(svg)) {
    final closing = m.group(1) == '/';
    final selfClosing = m.group(3) == '/';
    final name = m.group(2)!;
    if (selfClosing) continue;
    if (closing) {
      expect(stack.isNotEmpty && stack.last == name, isTrue, reason: '</$name> beklenmedik');
      stack.removeLast();
    } else {
      stack.add(name);
    }
  }
  expect(stack, isEmpty);
  expect(svg.contains('null'), isFalse);
  expect(svg.contains('NaN'), isFalse);
  // Kullanılan her url(#id) tanımlı olmalı.
  for (final m in RegExp(r'url\(#(\w+)\)').allMatches(svg)) {
    expect(svg.contains('id="${m.group(1)}"'), isTrue, reason: 'tanımsız #${m.group(1)}');
  }
  for (final m in RegExp(r'href="#(\w+)"').allMatches(svg)) {
    expect(svg.contains('id="${m.group(1)}"'), isTrue, reason: 'tanımsız #${m.group(1)}');
  }
  // flutter_svg web'de <pattern> çizmiyor — kullanılmamalı.
  expect(svg.contains('<pattern'), isFalse);
}

void main() {
  test('her eşyanın çizimi ya da deseni var', () {
    for (final def in homeRooms) {
      for (final c in def.categories) {
        for (final it in c.items) {
          final where = '${def.room.id}:${c.id}:${it.id} (${it.style})';
          switch (c.kind) {
            case HomeCategoryKind.furniture:
              expect(furnitureArt.containsKey(it.style), isTrue, reason: where);
            case HomeCategoryKind.wallpaper:
              expect(wallArt.containsKey(it.style), isTrue, reason: where);
            case HomeCategoryKind.floor:
              expect(floorArt.containsKey(it.style), isTrue, reason: where);
            case HomeCategoryKind.tile:
              expect(tileArt.containsKey(it.style), isTrue, reason: where);
            case HomeCategoryKind.cloth || HomeCategoryKind.blanket:
              expect(it.style == 'none' || wallArt.containsKey(it.style), isTrue, reason: where);
            case HomeCategoryKind.swatch:
              expect(it.color, isNotNull, reason: where);
          }
        }
      }
    }
  });

  test('her oda, her eşya seçimiyle ve bakım modunda geçerli SVG üretir', () {
    for (final def in homeRooms) {
      for (final care in [false, true]) {
        for (final c in def.categories) {
          for (final it in c.items) {
            final items = _defaults(def)..[c.id] = it;
            final scene = RoomArt.build(def.room, (cat) => items[cat]!, care: care, dark: care);
            _expectBalanced(scene.back);
            _expectBalanced(scene.front);
          }
        }
      }
    }
  });

  test('Zibo katmanı: kanepe oturağı ve yorgan önde kalır', () {
    HomeRoomDef def(HomeRoom r) => homeRooms.firstWhere((d) => d.room == r);
    final salon = def(HomeRoom.living);
    final scene = RoomArt.build(HomeRoom.living, (cat) => _defaults(salon)[cat]!);
    expect(scene.front, contains('<g transform="translate(70 520)">'));
    final bed = def(HomeRoom.bedroom);
    final sleeping = RoomArt.build(HomeRoom.bedroom, (cat) => _defaults(bed)[cat]!, care: true);
    expect(sleeping.front, contains('M24 250h452v126'));
    expect(sleeping.back, isNot(contains('M24 250h452v126')));
  });

  test('renk karıştırma taslakla aynı', () {
    expect(SvgKit.mix('#FF0000', .5), '#FF8080');
    expect(SvgKit.mix('#FF8040', -.5), '#804020');
    expect(SvgKit.hex(0xFFA9DDF2), '#A9DDF2');
  });
}
