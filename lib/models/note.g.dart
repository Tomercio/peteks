// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NoteAdapter extends TypeAdapter<Note> {
  @override
  final int typeId = 0;

  @override
  Note read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Note(
      id: fields[0] as String?,
      title: fields[1] as String,
      content: fields[2] as String,
      createdAt: fields[3] as DateTime?,
      modifiedAt: fields[4] as DateTime?,
      tags: (fields[5] as List?)?.cast<String>(),
      isPinned: fields[6] as bool? ?? false,
      isFavorite: fields[7] as bool? ?? false,
      imagePaths: (fields[8] as List?)?.cast<String>(),
      position: fields[9] as int,
      formattedContent: fields[10] as String,
      reminderDateTime: fields[11] as DateTime?,
      filePath: fields[12] as String?,
      fileType: fields[13] as String?,
      audioPath: fields[14] as String?,
      isSecure: fields[15] as bool? ?? false,
      securityType: fields[16] as String?,
      securityHash: fields[17] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Note obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.content)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.modifiedAt)
      ..writeByte(5)
      ..write(obj.tags)
      ..writeByte(6)
      ..write(obj.isPinned)
      ..writeByte(7)
      ..write(obj.isFavorite)
      ..writeByte(8)
      ..write(obj.imagePaths)
      ..writeByte(9)
      ..write(obj.position)
      ..writeByte(10)
      ..write(obj.formattedContent)
      ..writeByte(11)
      ..write(obj.reminderDateTime)
      ..writeByte(12)
      ..write(obj.filePath)
      ..writeByte(13)
      ..write(obj.fileType)
      ..writeByte(14)
      ..write(obj.audioPath)
      ..writeByte(15)
      ..write(obj.isSecure)
      ..writeByte(16)
      ..write(obj.securityType)
      ..writeByte(17)
      ..write(obj.securityHash);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
