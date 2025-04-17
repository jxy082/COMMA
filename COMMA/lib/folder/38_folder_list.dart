import 'package:flutter/material.dart';
import 'package:flutter_plugin/components.dart';

class FolderList extends StatelessWidget {
  final List<Map<String, dynamic>> folders;
  final Function(Map<String, dynamic>) onFolderTap;
  final Function(int) onRename;
  final Function(int) onDelete;

  const FolderList({
    super.key,
    required this.folders,
    required this.onFolderTap,
    required this.onRename,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: folders.asMap().entries.map((entry) {
        int index = entry.key;
        Map<String, dynamic> folder = entry.value;
        return GestureDetector(
          onTap: () => onFolderTap(folder),
          child: FolderListItem(
            folder: folder,
            fileCount: folder['file_count'] ?? 0, // Passing the number of files
            onRename: () => onRename(index),
            onDelete: () => onDelete(index),
          ),
        );
      }).toList(),
    );
  }
}
