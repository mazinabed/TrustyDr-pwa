import 'package:easy_localization/easy_localization.dart';

class RelationshipOption {
  final String key;
  final String labelKey;

  const RelationshipOption({required this.key, required this.labelKey});

  String get localizedLabel => labelKey.tr();

  static const List<RelationshipOption> options = [
    RelationshipOption(key: 'son', labelKey: 'relationship.son'),
    RelationshipOption(key: 'daughter', labelKey: 'relationship.daughter'),
    RelationshipOption(key: 'father', labelKey: 'relationship.father'),
    RelationshipOption(key: 'mother', labelKey: 'relationship.mother'),
    RelationshipOption(key: 'husband', labelKey: 'relationship.husband'),
    RelationshipOption(key: 'wife', labelKey: 'relationship.wife'),
    RelationshipOption(key: 'brother', labelKey: 'relationship.brother'),
    RelationshipOption(key: 'sister', labelKey: 'relationship.sister'),
    RelationshipOption(key: 'relative', labelKey: 'relationship.relative'),
    RelationshipOption(key: 'other', labelKey: 'relationship.other'),
  ];
}
