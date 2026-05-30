import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';

part 'folder.g.dart';

@HiveType(typeId: 1)
class Folder extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  int colorValue;

  @HiveField(3)
  String iconName;

  @HiveField(4)
  int position;

  Folder({
    String? id,
    required this.name,
    this.colorValue = 0xFFF49390,
    this.iconName = 'folder',
    this.position = 0,
  }) : id = id ?? const Uuid().v4();

  Color get color => Color(colorValue);

  IconData get icon {
    switch (iconName) {
      case 'work':
        return Icons.work_outline;
      case 'school':
        return Icons.school_outlined;
      case 'home':
        return Icons.home_outlined;
      case 'star':
        return Icons.star_outline;
      case 'heart':
        return Icons.favorite_outline;
      default:
        return Icons.folder_outlined;
    }
  }

  Folder copyWith({
    String? name,
    int? colorValue,
    String? iconName,
    int? position,
  }) {
    return Folder(
      id: id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      iconName: iconName ?? this.iconName,
      position: position ?? this.position,
    );
  }
}
