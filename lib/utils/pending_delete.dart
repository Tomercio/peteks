import '../models/note.dart';

/// Holds a note that is pending deletion so the home screen can offer Undo.
class PendingDelete {
  static Note? note;
  static List<String> imagePaths = [];

  static void set(Note n, List<String> imgs) {
    note = n;
    imagePaths = List.from(imgs);
  }

  static void clear() {
    note = null;
    imagePaths = [];
  }
}
