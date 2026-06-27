class ChileRegion {
  const ChileRegion({
    required this.id,
    required this.name,
    required this.comunas,
  });

  final String id;
  final String name;
  final List<String> comunas;
}

const chileRegions = <ChileRegion>[
  ChileRegion(
    id: 'valparaiso',
    name: 'Valparaíso',
    comunas: [
      'Quilpué',
      'Viña del Mar',
      'Valparaíso',
      'Villa Alemana',
      'Concón',
      'Limache',
      'Olmué',
      'Quillota',
      'La Calera',
      'San Antonio',
      'San Felipe',
      'Los Andes',
    ],
  ),
  ChileRegion(
    id: 'metropolitana',
    name: 'Región Metropolitana',
    comunas: [
      'Santiago',
      'Providencia',
      'Las Condes',
      'Ñuñoa',
      'Maipú',
      'La Florida',
      'Puente Alto',
      'San Miguel',
      'La Reina',
      'Macul',
      'Recoleta',
      'Independencia',
      'Estación Central',
      'Quilicura',
      'Peñalolén',
      'Pudahuel',
    ],
  ),
];

ChileRegion get defaultChileRegion => chileRegions.first;

String get defaultComuna => 'Viña del Mar';

ChileRegion findRegionById(String? regionId) {
  return chileRegions.firstWhere(
    (region) => region.id == regionId,
    orElse: () => defaultChileRegion,
  );
}
