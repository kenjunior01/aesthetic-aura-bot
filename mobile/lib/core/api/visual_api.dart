/// visual_api.dart — banco de imagens visuais reais (Espelho) + consultor
/// de compras (Mercado), ambos via rotas partilhadas do backend:
///  • GET  /api/galeria-visual?q=&count=  (Pexels no servidor; reserva sem chave)
///  • POST /api/shopping-advisor          (photo → produtos; prioritize → plano;
///                                          brands → marcas locais)
library;

import '../store/profile_store.dart';
import 'api_client.dart';
import 'groq_ai.dart';
import 'image_bank.dart';

class VisualItem {
  const VisualItem({
    required this.id,
    required this.url,
    required this.thumb,
    required this.alt,
    required this.autor,
    this.fonte = '',
  });

  final String id;
  final String url;
  final String thumb;
  final String alt;
  final String autor;

  /// Banco de origem: 'pexels' | 'unsplash' | 'backend' | 'reserva' | ''.
  final String fonte;

  factory VisualItem.fromJson(Map<String, dynamic> j) => VisualItem(
    id: (j['id'] as String?) ?? 'v-${j.hashCode}',
    url: (j['url'] as String?) ?? '',
    thumb: (j['thumb'] as String?) ?? (j['url'] as String?) ?? '',
    alt: (j['alt'] as String?) ?? '',
    autor: (j['autor'] as String?) ?? '',
    fonte: (j['fonte'] as String?) ?? '',
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

  /// Busca imagens reais de uma categoria — bancos diretos no telemóvel
  /// (Pexels + Unsplash intercalados) com fallback ao backend e reserva.
  Future<VisualResult> buscar(String query, {int count = 10}) =>
      BancoImagens.I.buscar(query, count: count);

  /// Foto de prateleira → produtos detectados.
  /// Cadeia: Groq visão direto → Vision no backend → vazio.
  Future<List<ProdutoFoto>> fotoParaProdutos(
    String imageBase64, {
    String mimeType = 'image/jpeg',
  }) async {
    // 1. Groq direto — o telemóvel vê a prateleira sozinho.
    final bruto = await GroqAi.I.vision(
      prompt: 'Você é o Aura, consultor de compras de beleza. Analise a foto '
          'de prateleira/ produtos e liste o que reconhece. Responda APENAS '
          'JSON: {"products":[{"name":"nome do produto","brand":"marca",'
          '"price":0,"category":"shampoo|condicionador|mascara|creme-pentear|'
          'oleo|proteina|limpeza-facial|hidratante|protetor-solar|tratamento|'
          'estilizacao|outro"}],"observations":"o que notou na prateleira '
          '(máx 25 palavras)"}. Preço 0 se não estiver visível.',
      imageBase64: imageBase64,
      mimeType: mimeType,
      json: true,
      maxTokens: 800,
    );
    final direto = GroqAi.I.extrairJson(bruto);
    final produtosDireto = (direto?['products'] as List?)
        ?.whereType<Map<String, dynamic>>()
        .map(ProdutoFoto.fromJson)
        .toList();
    if (produtosDireto != null && produtosDireto.isNotEmpty) {
      return produtosDireto;
    }

    // 2. Backend partilhado.
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
  /// Cadeia: Groq direto → backend → plano local por necessidade científica.
  Future<PlanoCompra> priorizar(
    List<ProdutoFoto> produtos, {
    double budget = 0,
  }) async {
    // 1. Groq direto — mesmo contrato do backend (prioritize).
    if (produtos.isNotEmpty) {
      final bruto = await GroqAi.I.chat(
        system: 'Você é o Aura, consultor de compras de beleza. Responde em '
            'português, apenas JSON válido, sem markdown.',
        turns: [
          {
            'role': 'user',
            'content':
                'Produtos na prateleira: ${produtos.map((p) => '{"name":"${p.name}","brand":"${p.brand}","price":${p.price},"category":"${p.category}"}').join(', ')}. '
                'Orçamento: ${budget <= 0 ? 'não definido' : budget}. Perfil: cabelo ${_perfil.hairType}, prioridades ${_perfil.priorities.join(', ')}, clima ${_perfil.climate}. '
                'Responda APENAS JSON: {"items":[{"name":"","brand":"","price":0,'
                '"category":"","priority":1,"verdict":"comprar|depois","reason":"motivo curto (1 linha, moeda local se preço)"}],'
                '"totalInside":0,"advice":"conselho de 1 frase sobre a compra"}. '
                'Prioridade 1 = comprar primeiro. itens veredicto "depois" ficam fora do totalInside.',
          },
        ],
        temperature: 0.4,
        maxTokens: 900,
        json: true,
      );
      final direto = GroqAi.I.extrairJson(bruto);
      if (direto != null && direto['items'] is List && (direto['items'] as List).isNotEmpty) {
        direto['source'] = 'groq';
        return PlanoCompra.fromJson(direto);
      }
    }

    // 2. Backend partilhado.
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
      // 3. Plano local honesto: ordem de necessidade científica.
      return _planoLocal(produtos, budget);
    }
  }

  /// Marcas acessíveis e honestas no país do utilizador.
  /// Cadeia: Groq direto (comento marcas e evito as agressivas) → backend.
  Future<List<MarcaLocal>> marcas() async {
    final pais = _pais();
    final bruto = await GroqAi.I.chat(
      system: 'Você é o Aura, consultor de compras de beleza. Responde em '
          'português, apenas JSON válido, sem markdown.',
      turns: [
        {
          'role': 'user',
          'content': 'Perfil: cabelo ${_perfil.hairType}, tom de pele ${_perfil.skinTone}/10 (subtom ${_perfil.undertone}), '
              'orçamento ${_perfil.budget}, país ${pais.isEmpty ? 'inferido pelo contexto lusófono' : pais}. '
              'Recomenda 6 marcas de beleza ACESSÍVEIS e honestas para esse contexto. '
              'Evite marcas com histórico de ingredientes agressivos ou polêmica de segurança. '
              'Responda APENAS JSON: {"brands":[{"name":"marca","domain":"cabelo|pele|ambos","why":"porquê em 1 linha","priceLevel":1,"typicalPrice":"faixa de preço em moeda local"}]}. priceLevel: 1=entrada, 2=intermédio.',
        },
      ],
      temperature: 0.5,
      maxTokens: 800,
      json: true,
    );
    final direto = GroqAi.I.extrairJson(bruto);
    final marcasDireto = (direto?['brands'] as List?)
        ?.whereType<Map<String, dynamic>>()
        .map(MarcaLocal.fromJson)
        .toList();
    if (marcasDireto != null && marcasDireto.isNotEmpty) return marcasDireto;

    try {
      final data = await ApiClient.I.post('/api/shopping-advisor', {
        'mode': 'brands',
        'country': pais,
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
