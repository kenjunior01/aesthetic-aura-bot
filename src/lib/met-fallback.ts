/**
 * met-fallback.ts — reserva embutida do Acervo (The Metropolitan Museum of Art).
 * Todos os itens foram verificados: isPublicDomain=true + primaryImageSmall ativa.
 * Serve de garantia quando a API do Met está indisponível — a galeria nunca
 * amanhece vazia. Gerado por scripts/gen-fallback-ts.mjs (met-fallback.json).
 */

export type MetItem = {
  objectID: number;
  title: string;
  artist: string;
  date: string;
  culture: string;
  medium: string;
  department: string;
  image: string;
  objectURL: string;
};

export const MET_RESERVA: Record<string, MetItem[]> = {
  "vestidos": [
    {
      "objectID": 12127,
      "title": "Madame X (Virginie Amélie Avegno Gautreau)",
      "artist": "John Singer Sargent",
      "date": "1883–84",
      "culture": "American",
      "medium": "Oil on canvas",
      "department": "The American Wing",
      "image": "https://images.metmuseum.org/CRDImages/ad/web-large/DP-29006-001.jpg",
      "objectURL": "https://www.metmuseum.org/art/collection/search/12127"
    },
    {
      "objectID": 436141,
      "title": "The Dancing Class",
      "artist": "Edgar Degas",
      "date": "ca. 1870",
      "culture": "",
      "medium": "Oil on wood",
      "department": "European Paintings",
      "image": "https://images.metmuseum.org/CRDImages/ep/web-large/DP-25445-001.jpg",
      "objectURL": "https://www.metmuseum.org/art/collection/search/436141"
    },
    {
      "objectID": 437430,
      "title": "By the Seashore",
      "artist": "Auguste Renoir",
      "date": "1883",
      "culture": "",
      "medium": "Oil on canvas",
      "department": "European Paintings",
      "image": "https://images.metmuseum.org/CRDImages/ep/web-large/DP-14936-039.jpg",
      "objectURL": "https://www.metmuseum.org/art/collection/search/437430"
    },
    {
      "objectID": 438818,
      "title": "Joseph-Antoine Moltedo (born 1775)",
      "artist": "Jean Auguste Dominique Ingres",
      "date": "ca. 1810",
      "culture": "",
      "medium": "Oil on canvas",
      "department": "European Paintings",
      "image": "https://images.metmuseum.org/CRDImages/ep/web-large/DP151185.jpg",
      "objectURL": "https://www.metmuseum.org/art/collection/search/438818"
    }
  ],
  "texteis": [
    {
      "objectID": 450541,
      "title": "Tile Fragment",
      "artist": "Desconhecido",
      "date": "1334–1434",
      "culture": "",
      "medium": "Stonepaste; glazed",
      "department": "Islamic Art",
      "image": "https://images.metmuseum.org/CRDImages/is/web-large/sf45-103-1.jpg",
      "objectURL": "https://www.metmuseum.org/art/collection/search/450541"
    },
    {
      "objectID": 449537,
      "title": "Mihrab (Prayer Niche)",
      "artist": "Desconhecido",
      "date": "dated 755 AH/1354–55 CE",
      "culture": "",
      "medium": "Mosaic of polychrome-glazed cut tiles on stonepaste body; set into mortar",
      "department": "Islamic Art",
      "image": "https://images.metmuseum.org/CRDImages/is/web-large/DP235035.jpg",
      "objectURL": "https://www.metmuseum.org/art/collection/search/449537"
    },
    {
      "objectID": 448402,
      "title": "Earring, One of a Pair",
      "artist": "Desconhecido",
      "date": "11th century",
      "culture": "",
      "medium": "Gold; wire, strips, filigree, and granulation",
      "department": "Islamic Art",
      "image": "https://images.metmuseum.org/CRDImages/is/web-large/LC-30_95_38.jpg",
      "objectURL": "https://www.metmuseum.org/art/collection/search/448402"
    },
    {
      "objectID": 453168,
      "title": "Page of Calligraphy from the Kulliyat of Sa'di",
      "artist": "Abd al-Majid Taleqani",
      "date": "18th century",
      "culture": "",
      "medium": "Ink, opaque watercolor, and gold on paper",
      "department": "Islamic Art",
      "image": "https://images.metmuseum.org/CRDImages/is/web-large/sf1982-120-5.jpg",
      "objectURL": "https://www.metmuseum.org/art/collection/search/453168"
    }
  ],
  "joalharia": [
    {
      "objectID": 450084,
      "title": "Jewelry",
      "artist": "Desconhecido",
      "date": "probably 8th–12th century",
      "culture": "",
      "medium": "Stone or bone",
      "department": "Islamic Art",
      "image": "https://images.metmuseum.org/CRDImages/is/web-large/sf40-170-409a.jpg",
      "objectURL": "https://www.metmuseum.org/art/collection/search/450084"
    },
    {
      "objectID": 256975,
      "title": "Ganymede jewelry",
      "artist": "Greek",
      "date": "ca. 330–300 BCE",
      "culture": "Greek",
      "medium": "Gold, rock crystal, emerald",
      "department": "Greek and Roman Art",
      "image": "https://images.metmuseum.org/CRDImages/gr/web-large/DT283.jpg",
      "objectURL": "https://www.metmuseum.org/art/collection/search/256975"
    },
    {
      "objectID": 256976,
      "title": "Set of jewelry",
      "artist": "Etruscan",
      "date": "early 5th century BCE",
      "culture": "Etruscan",
      "medium": "Gold, glass, rock crystal, agate, carnelian",
      "department": "Greek and Roman Art",
      "image": "https://images.metmuseum.org/CRDImages/gr/web-large/DP122702.jpg",
      "objectURL": "https://www.metmuseum.org/art/collection/search/256976"
    },
    {
      "objectID": 465818,
      "title": "Disk Brooch",
      "artist": "Frankish",
      "date": "second half 7th century",
      "culture": "Frankish",
      "medium": "Gold sheet, filigree, moonstone/adularia, glass cabochons, garnets, mother-of-pearl, and moonstone",
      "department": "Medieval Art",
      "image": "https://images.metmuseum.org/CRDImages/md/web-large/dp30495.jpg",
      "objectURL": "https://www.metmuseum.org/art/collection/search/465818"
    },
    {
      "objectID": 446798,
      "title": "Bracelet (Kada), One of a Pair",
      "artist": "Desconhecido",
      "date": "19th century",
      "culture": "",
      "medium": "Gold, rubies, emerald",
      "department": "Islamic Art",
      "image": "https://images.metmuseum.org/CRDImages/is/web-large/LC-15_95_135.jpg",
      "objectURL": "https://www.metmuseum.org/art/collection/search/446798"
    }
  ],
  "armaduras": [
    {
      "objectID": 22895,
      "title": "Parade Shield Depicting the Conversion of Saint Paul",
      "artist": "Italian, Milan",
      "date": "ca. 1570",
      "culture": "Italian, Milan",
      "medium": "Steel, gold, silver",
      "department": "Arms and Armor",
      "image": "https://images.metmuseum.org/CRDImages/aa/web-large/DT293353.jpg",
      "objectURL": "https://www.metmuseum.org/art/collection/search/22895"
    },
    {
      "objectID": 21974,
      "title": "Helmet all'Antica",
      "artist": "Filippo Negroli",
      "date": "ca. 1532–35",
      "culture": "Italian, Milan",
      "medium": "Steel",
      "department": "Arms and Armor",
      "image": "https://images.metmuseum.org/CRDImages/aa/web-large/DT277024.jpg",
      "objectURL": "https://www.metmuseum.org/art/collection/search/21974"
    },
    {
      "objectID": 22020,
      "title": "Armor (Gusoku)",
      "artist": "Japanese",
      "date": "19th century",
      "culture": "Japanese",
      "medium": "Iron, leather, lacquer, silk, copper alloy",
      "department": "Arms and Armor",
      "image": "https://images.metmuseum.org/CRDImages/aa/web-large/DP264123.jpg",
      "objectURL": "https://www.metmuseum.org/art/collection/search/22020"
    },
    {
      "objectID": 35789,
      "title": "Composite Armor",
      "artist": "Jörg Wagner",
      "date": "comprehensively ca. 1485–95",
      "culture": "Austrian, Innsbruck and Mühlau",
      "medium": "Steel",
      "department": "Arms and Armor",
      "image": "https://images.metmuseum.org/CRDImages/aa/web-large/DP108845.jpg",
      "objectURL": "https://www.metmuseum.org/art/collection/search/35789"
    },
    {
      "objectID": 22013,
      "title": "Turban Helmet",
      "artist": "Turkish, possibly Istanbul, in the style of Turkman armor",
      "date": "late 15th century–1st quarter 16th century",
      "culture": "Turkish, possibly Istanbul, in the style of Turkman armor",
      "medium": "Steel, iron, gold, silver, copper alloy",
      "department": "Arms and Armor",
      "image": "https://images.metmuseum.org/CRDImages/aa/web-large/DP147295.jpg",
      "objectURL": "https://www.metmuseum.org/art/collection/search/22013"
    },
    {
      "objectID": 22198,
      "title": "Halberd of the Swiss Guard of Johann Georg II of Saxony (reigned 1656–80)",
      "artist": "German",
      "date": "dated 1680",
      "culture": "German",
      "medium": "Steel, gold, wood",
      "department": "Arms and Armor",
      "image": "https://images.metmuseum.org/CRDImages/aa/web-large/14.25.332_001june2014.jpg",
      "objectURL": "https://www.metmuseum.org/art/collection/search/22198"
    }
  ],
  "retratos": [
    {
      "objectID": 437875,
      "title": "Portrait of a Man",
      "artist": "Velázquez",
      "date": "ca. 1650",
      "culture": "",
      "medium": "Oil on canvas",
      "department": "European Paintings",
      "image": "https://images.metmuseum.org/CRDImages/ep/web-large/DP276131.jpg",
      "objectURL": "https://www.metmuseum.org/art/collection/search/437875"
    },
    {
      "objectID": 436152,
      "title": "Portrait of a Woman in Gray",
      "artist": "Edgar Degas",
      "date": "ca. 1865",
      "culture": "",
      "medium": "Oil on canvas",
      "department": "European Paintings",
      "image": "https://images.metmuseum.org/CRDImages/ep/web-large/DT1912.jpg",
      "objectURL": "https://www.metmuseum.org/art/collection/search/436152"
    },
    {
      "objectID": 436337,
      "title": "Portrait of a Monk in Prayer",
      "artist": "French Painter",
      "date": "",
      "culture": "",
      "medium": "Oil on wood",
      "department": "European Paintings",
      "image": "https://images.metmuseum.org/CRDImages/ep/web-large/DP345572.jpg",
      "objectURL": "https://www.metmuseum.org/art/collection/search/436337"
    },
    {
      "objectID": 436532,
      "title": "Self-Portrait with a Straw Hat (obverse: The Potato Peeler)",
      "artist": "Vincent van Gogh",
      "date": "1887",
      "culture": "",
      "medium": "Oil on canvas",
      "department": "European Paintings",
      "image": "https://images.metmuseum.org/CRDImages/ep/web-large/DT1502_cropped2.jpg",
      "objectURL": "https://www.metmuseum.org/art/collection/search/436532"
    },
    {
      "objectID": 436105,
      "title": "The Death of Socrates",
      "artist": "Jacques Louis David",
      "date": "1787",
      "culture": "",
      "medium": "Oil on canvas",
      "department": "European Paintings",
      "image": "https://images.metmuseum.org/CRDImages/ep/web-large/DP-13139-001.jpg",
      "objectURL": "https://www.metmuseum.org/art/collection/search/436105"
    },
    {
      "objectID": 435841,
      "title": "Baron Joseph Dominique Louis (1755–1837)",
      "artist": "Pierre Laurent Canon",
      "date": "1844",
      "culture": "",
      "medium": "Ivory",
      "department": "European Paintings",
      "image": "https://images.metmuseum.org/CRDImages/ep/web-large/DP-43806-001.jpg",
      "objectURL": "https://www.metmuseum.org/art/collection/search/435841"
    },
    {
      "objectID": 436536,
      "title": "Women Picking Olives",
      "artist": "Vincent van Gogh",
      "date": "1889",
      "culture": "",
      "medium": "Oil on canvas",
      "department": "European Paintings",
      "image": "https://images.metmuseum.org/CRDImages/ep/web-large/DP-17161-001.jpg",
      "objectURL": "https://www.metmuseum.org/art/collection/search/436536"
    }
  ],
  "fotografias": [
    {
      "objectID": 267988,
      "title": "[Landscape with Distant View of Earthwork Fortifications]",
      "artist": "Unknown",
      "date": "1861–65",
      "culture": "",
      "medium": "Albumen silver print from glass negative",
      "department": "Photographs",
      "image": "https://images.metmuseum.org/CRDImages/ph/web-large/DP70778.jpg",
      "objectURL": "https://www.metmuseum.org/art/collection/search/267988"
    }
  ]
};
