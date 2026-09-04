/// visual_api.dart — banco de imagens visuais reais (Espelho) + consultor
/// de compras (Mercado), ambos via rotas partilhadas do backend:
///  • GET  /api/galeria-visual?q=&count=  (Pexels no servidor; reserva sem chave)
///  • POST /api/shopping-advisor          (photo → produtos; prioritize → plano;
///                                          brands → marcas locais)
library;

import '../store/profile_store.dart';
import 'api_client.dart';

class VisualItem {
  const VisualItem({
    required this.id,
    required this.url,
    required this.thumb,
    required this.alt,
    required this.autor,
  });

  final String id;
  final String url;
  final String thumb;
  final String alt;
  final String autor;

  factory VisualItem.fromJson(Map<String, dynamic> j) => VisualItem(
    id: (j['id'] as String?) ?? 'v-${j.hashCode}',
    url: (j['url'] as String?) ?? '',
    thumb: (j['thumb'] as String?) ?? (j['url'] as String?) ?? '',
    alt: (j['alt'] as String?) ?? '',
    autor: (j['autor'] as String?) ?? '',
  );
}

class VisualResult {
  const VisualResult({required this.items, required this.source});
  final List<VisualItem> items;
  final String source; // 'pexels' | 'reserva'
}

/// Produtos detectados numa foto de prateleira.
class ProdutoFoto {
  const ProdutoFoto({
    required this.name,
    required this.brand,
    required this.price,
    required this.category,
  });

  final String name;
  final String brand;
  final double price;
  final String category;

  factory ProdutoFoto.fromJson(Map<String, dynamic> j) => ProdutoFoto(
    name: (j['name'] as String?) ?? 'Produto',
    brand: (j['brand'] as String?) ?? '',
    price: (j['price'] as num?)?.toDouble() ?? 0,
    category: (j['category'] as String?) ?? 'outro',
  );
}

/// Item do plano priorizado.
class PlanoItem {
  const PlanoItem({
    required this.name,
    required this.brand,
    required this.price,
    required this.category,
    required this.priority,
    required this.comprar,
    required this.reason,
  });

  final String name;
  final String brand;
  final double price;
  final String category;
  final int priority;
  final bool comprar; // true = comprar agora; false = depois
  final String reason;

  factory PlanoItem.fromJson(Map<String, dynamic> j) => PlanoItem(
    name: (j['name'] as String?) ?? 'Produto',
    brand: (j['brand'] as String?) ?? '',
    price: (j['price'] as num?)?.toDouble() ?? 0,
    category: (j['category'] as String?) ?? 'outro',
    priority: (j['priority'] as num?)?.toInt() ?? 99,
    comprar: (j['verdict'] as String?) != 'depois',
    reason: (j['reason'] as String?) ?? '',
  );
}

class PlanoCompra {
  const PlanoCompra({
    required this.items,
    required this.totalInside,
    required this.advice,
    required this.source,
  });

  final List<PlanoItem> items;
  final double totalInside;
  final String advice;
  final String source;

  factory PlanoCompra.fromJson(Map<String, dynamic> j) => PlanoCompra(
    items: (j['items'] as List?)
            ?.map((e) => PlanoItem.fromJson((e as Map).cast<String, dynamic>()))
            .toList() ??
        const [],
    totalInside: (j['totalInside'] as num?)?.toDouble() ?? 0,
    advice: (j['advice'] as String?) ?? '',
    source: (j['source'] as String?) ?? 'local',
  );
}

/// Marca recomendada para o país do utilizador.
class MarcaLocal {
  const MarcaLocal({
    required this.name,
    required this.domain,
    required this.why,
    required this.priceLevel,
    required this.typicalPrice,
  });

  final String name;
  final String domain; // cabelo | pele | ambos
  final String why;
  final int priceLevel; // 1 = entrada, 2 = intermédio
  final String typicalPrice;

  factory MarcaLocal.fromJson(Map<String, dynamic> j) => MarcaLocal(
    name: (j['name'] as String?) ?? '',
    domain: (j['domain'] as String?) ?? 'ambos',
    why: (j['why'] as String?) ?? '',
    priceLevel: (j['priceLevel'] as num?)?.toInt() ?? 1,
    typicalPrice: (j['typicalPrice'] as String?) ?? '',
  );
}

class VisualApi {
  VisualApi._();
  static final VisualApi I = VisualApi._();

  /// Categorias do Espelho — cada uma com a sua busca real no banco.
  static const Map<String, String> cabeloQueries = {
    'Liso': 'straight glossy hair portrait',
    'Ondulado': 'wavy hair portrait',
    'Cacheado': 'curly hair portrait',
    'Cacheado 4C': 'afro natural hair portrait',
    'Transças': 'braids hairstyle portrait',
    'Coque': 'bun hairstyle woman portrait',
  };

  static const Map<String, String> estiloQueries = {
    'Clássico': 'classic elegant fashion portrait',
    'Rua': 'street style fashion portrait',
    'Desportivo': 'athleisure sport fashion portrait',
    'Criativo': 'colorful creative fashion portrait',
    'Minimal': 'minimalist fashion portrait',
    'Romântico': 'soft romantic fashion portrait',
  };

  /// Busca imagens reais de uma categoria no banco (servidor decide a fonte).
  Future<VisualResult> buscar(String query, {int count = 10}) async {
    try {
      final data = await ApiClient.I.get(
        '/api/galeria-visual',
        query: {'q': query, 'count': '$count'},
      );
      final fonte = (data['fonte'] as String?) ?? 'reserva';
      final items = (data['items'] as List?)
              ?.map((e) => VisualItem.fromJson((e as Map).cast<String, dynamic>()))
              .toList() ??
          const <VisualItem>[];
      return VisualResult(items: items, source: fonte);
    } catch (_) {
      return const VisualResult(items: [], source: 'offline');
    }
  }

  /// Foto de prateleira → produtos detectados (Vision no servidor).
  Future<List<ProdutoFoto>> fotoParaProdutos(
    String imageBase64, {
    String mimeType = 'image/jpeg',
  }) async {
    try {
      final data = await ApiClient.I.post('/api/shopping-advisor', {
        'mode': 'photo',
        'imageBase64': imageBase64,
        'mimeType': mimeType,
        'country': _pais(),
        'profile': _perfilResumo(),
      });
      final produtos = (data['products'] as List?)
              ?.map((e) => ProdutoFoto.fromJson((e as Map).cast<String, dynamic>()))
              .toList() ??
          const <ProdutoFoto>[];
      return produtos;
    } catch (_) {
      return const [];
    }
  }

  /// Produtos → plano priorizado (o que comprar primeiro e porquê).
  Future<PlanoCompra> priorizar(
    List<ProdutoFoto> produtos, {
    double budget = 0,
  }) async {
    try {
      final data = await ApiClient.I.post('/api/shopping-advisor', {
        'mode': 'prioritize',
        'products': produtos
            .map((p) => {'name': p.name, 'brand': p.brand, 'price': p.price})
            .toList(),
        'budget': budget,
        'country': _pais(),
        'profile': _perfilResumo(),
      });
      return PlanoCompra.fromJson(data);
    } catch (_) {
      // Plano local honesto: ordem de necessidade científica.
      return _planoLocal(produtos, budget);
    }
  }

  /// Marcas acessíveis e honestas no país do utilizador.
  Future<List<MarcaLocal>> marcas() async {
    try {
      final data = await ApiClient.I.post('/api/shopping-advisor', {
        'mode': 'brands',
        'country': _pais(),
        'profile': _perfilResumo(),
      });
      return (data['brands'] as List?)
              ?.map((e) => MarcaLocal.fromJson((e as Map).cast<String, dynamic>()))
              .toList() ??
          const [];
    } catch (_) {
      return const [];
    }
  }

  String _pais() {
    // O país do perfil é inferido no servidor por timezone/país informado.
    return '';
  }

  Map<String, dynamic> _perfilResumo() {
    final p = _perfil;
    return {
      'hairType': p.hairType,
      'styles': p.styles,
      'colors': p.colors,
      'priorities': p.priorities,
      'climate': p.climate,
      'region': p.region,
      'budget': p.budget,
    };
  }

  // Acesso ao perfil sem BuildContext — o store é injetado no arranque.
  static Profile _perfil = const Profile();
  static void bindProfile(Profile p) => _perfil = p;

  PlanoCompra _planoLocal(List<ProdutoFoto> produtos, double budget) {
    const ordemNecessidade = [
      'limpeza-facial',
      'shampoo',
      'condicionador',
      'mascara',
      'proteina',
      'creme-pentear',
      'hidratante',
      'protetor-solar',
      'tratamento',
      'oleo',
      'estilizacao',
      'outro',
    ];
    var total = 0.0;
    final ordenados = [...produtos]..sort(
        (a, b) => ordemNecessidade
            .indexOf(a.category)
            .clamp(0, 99)
            .compareTo(ordemNecessidade.indexOf(b.category).clamp(0, 99)),
      );
    final items = <PlanoItem>[];
    for (var i = 0; i < ordenados.length; i++) {
      final p = ordenados[i];
      final cabe = budget <= 0 || total + p.price <= budget;
      if (cabe && p.price > 0) total += p.price;
      items.add(
        PlanoItem(
          name: p.name,
          brand: p.brand,
          price: p.price,
          category: p.category,
          priority: i + 1,
          comprar: cabe,
          reason: cabe
              ? 'Necessidade base antes do estético'
              : 'Refina depois do essencial',
        ),
      );
    }
    return PlanoCompra(
      items: items,
      totalInside: total,
      advice: budget > 0
          ? 'Plano offline: essência primeiro, estética depois'
          : 'Plano offline pela ordem de necessidade',
      source: 'local',
    );
  }
}
