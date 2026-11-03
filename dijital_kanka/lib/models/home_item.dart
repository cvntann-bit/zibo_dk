/// Zibo'nun Evi kataloğu modelleri. Veri: `lib/data/home_catalog.dart`
/// (üretilmiş; kaynak taslak `docs/home_studio/`). Eşyalar görsel değil,
/// kodla çizilir: [HomeItem.style] hangi çizimin, [HomeItem.color] hangi
/// rengin kullanılacağını söyler.
enum HomeRoom {
  kitchen('mutfak'),
  bath('banyo'),
  bedroom('yatak'),
  living('salon');

  const HomeRoom(this.id);

  /// Kalıcı kimlik (Firestore `homeDecorState` anahtarı) — değiştirilmez.
  final String id;

  static HomeRoom? fromId(String id) {
    for (final room in values) {
      if (room.id == id) return room;
    }
    return null;
  }
}

/// Kategori türü, mağazada önizlemenin nasıl çizileceğini belirler.
enum HomeCategoryKind { swatch, wallpaper, floor, tile, furniture, blanket, cloth }

class HomeItem {
  const HomeItem(this.id, this.nameTr, {this.style, this.color, this.color2, required this.price, this.eventOnly = false});

  /// Kategori içinde kalıcı kimlik — satın alımlar bununla saklanır.
  final String id;
  final String nameTr;

  /// Çizim türü ya da desen adı; `'none'` = boş yuva ("Yok").
  final String? style;
  final int? color;
  final int? color2;

  /// ZC. 0 = başlangıç eşyası, herkese bedava.
  final int price;

  /// Yalnızca etkinlik ödülü (Faz 6): mağazada satılmaz, sahip olunmadıkça
  /// görünmez. [price] yalnızca nadirlik kademesini belirler.
  final bool eventOnly;

  bool get isEmpty => style == 'none';
}

class HomeCategory {
  const HomeCategory(this.id, this.nameTr, this.kind, this.items);

  final String id;
  final String nameTr;
  final HomeCategoryKind kind;
  final List<HomeItem> items;

  HomeItem? item(String id) {
    for (final it in items) {
      if (it.id == id) return it;
    }
    return null;
  }
}

class HomeRoomDef {
  const HomeRoomDef({required this.room, required this.nameTr, required this.defaults, required this.categories});

  final HomeRoom room;
  final String nameTr;

  /// Kategori → başlangıçta takılı eşya (hepsi bedava).
  final Map<String, String> defaults;
  final List<HomeCategory> categories;

  HomeCategory? category(String id) {
    for (final c in categories) {
      if (c.id == id) return c;
    }
    return null;
  }
}

class HomeFood {
  const HomeFood(this.id, this.nameTr, {required this.hunger, required this.price, required this.group});

  /// Fluent görselleri için dosya adı da bu (`simit`/`churros` kodla çizilir).
  final String id;
  final String nameTr;

  /// Tokluğa eklenen puan (0–100 ölçeği).
  final int hunger;
  final int price;
  final String group;

  bool get isFree => price == 0;
}

class HomeSoap {
  const HomeSoap(this.id, this.nameTr, {this.foam, this.foamStroke, this.bar, this.barStroke, required this.price});

  final String id;
  final String nameTr;

  /// Köpük rengi; `null` = gökkuşağı (karışık renk).
  final int? foam;
  final int? foamStroke;
  final int? bar;
  final int? barStroke;
  final int price;

  bool get isRainbow => foam == null;
}
