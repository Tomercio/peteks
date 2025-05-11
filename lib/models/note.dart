import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'note.g.dart'; // This will be generated later

@HiveType(typeId: 0)
class Note extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String content;

  @HiveField(3)
  DateTime createdAt;

  @HiveField(4)
  DateTime modifiedAt;

  @HiveField(5)
  List<String> tags;

  @HiveField(6)
  bool isPinned;

  @HiveField(7)
  bool isFavorite;

  @HiveField(8)
  List<String> imagePaths;

  @HiveField(9)
  int position;

  @HiveField(10)
  String formattedContent;

  @HiveField(11)
  DateTime? reminderDateTime;

  @HiveField(12)
  String? filePath;

  @HiveField(13)
  String? fileType;

  @HiveField(14)
  String? audioPath;

  @HiveField(15)
  bool isSecure;

  @HiveField(16)
  String? securityType; // 'password' or 'pattern'

  @HiveField(17)
  String? securityHash;

  Note({
    String? id,
    this.title = '',
    this.content = '',
    DateTime? createdAt,
    DateTime? modifiedAt,
    List<String>? tags,
    this.isPinned = false,
    this.isFavorite = false,
    List<String>? imagePaths,
    this.position = 0,
    this.formattedContent = '',
    this.reminderDateTime,
    this.filePath,
    this.fileType,
    this.audioPath,
    this.isSecure = false,
    this.securityType,
    this.securityHash,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        modifiedAt = modifiedAt ?? DateTime.now(),
        tags = tags ?? [],
        imagePaths = imagePaths ?? [];

  // האם יש תמונות בפתק
  bool get hasImages => imagePaths.isNotEmpty;

  // קבלת התמונה הראשונה (לתמונה ממוזערת)
  String? get thumbnailImage => imagePaths.isNotEmpty ? imagePaths.first : null;

  Note copyWith({
    String? title,
    String? content,
    DateTime? modifiedAt,
    List<String>? tags,
    bool? isPinned,
    bool? isFavorite,
    List<String>? imagePaths,
    int? position,
    String? formattedContent,
    DateTime? reminderDateTime,
    String? filePath,
    String? fileType,
    String? audioPath,
    bool? isSecure,
    String? securityType,
    String? securityHash,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      tags: tags ?? this.tags,
      isPinned: isPinned ?? this.isPinned,
      isFavorite: isFavorite ?? this.isFavorite,
      imagePaths: imagePaths ?? this.imagePaths,
      position: position ?? this.position,
      formattedContent: formattedContent ?? this.formattedContent,
      reminderDateTime: reminderDateTime ?? this.reminderDateTime,
      filePath: filePath ?? this.filePath,
      fileType: fileType ?? this.fileType,
      audioPath: audioPath ?? this.audioPath,
      isSecure: isSecure ?? this.isSecure,
      securityType: securityType ?? this.securityType,
      securityHash: securityHash ?? this.securityHash,
    );
  }

  // Preview of the note content (first 100 characters)
  String get preview {
    if (content.isEmpty) return '';
    return content.length > 100 ? '${content.substring(0, 100)}...' : content;
  }

  // Calculate number of words in the note
  int get wordCount {
    if (content.isEmpty) return 0;
    return content
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .length;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt.toIso8601String(),
      'tags': tags,
      'imagePaths': imagePaths,
      'isFavorite': isFavorite,
      'isPinned': isPinned,
      'reminderDateTime': reminderDateTime?.toIso8601String(),
      'position': position,
      'filePath': filePath,
      'fileType': fileType,
      'audioPath': audioPath,
      'isSecure': isSecure,
      'securityType': securityType,
      'securityHash': securityHash,
    };
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      createdAt: DateTime.parse(json['createdAt']),
      modifiedAt: DateTime.parse(json['modifiedAt']),
      tags: List<String>.from(json['tags']),
      imagePaths: List<String>.from(json['imagePaths']),
      isFavorite: json['isFavorite'],
      isPinned: json['isPinned'],
      reminderDateTime: json['reminderDateTime'] != null
          ? DateTime.parse(json['reminderDateTime'])
          : null,
      position: json['position'],
      filePath: json['filePath'],
      fileType: json['fileType'],
      audioPath: json['audioPath'],
      isSecure: json['isSecure'] ?? false,
      securityType: json['securityType'],
      securityHash: json['securityHash'],
    );
  }
}
