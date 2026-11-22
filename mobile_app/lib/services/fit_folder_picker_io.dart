import 'dart:io';
import 'package:file_selector/file_selector.dart';

XTypeGroup _mobileAnyFileTypeGroup() => XTypeGroup(
  label: 'FIT folder files',
  mimeTypes: Platform.isAndroid ? const ['*/*'] : null,
  uniformTypeIdentifiers: Platform.isIOS
      ? const ['public.data', 'public.item']
      : null,
);

Future<List<XFile>?> _pickMultipleFilesMobile() async {
  final picked = await openFiles(
    acceptedTypeGroups: [_mobileAnyFileTypeGroup()],
    confirmButtonText: 'Import .fit files',
  );
  return picked.isEmpty ? null : picked;
}

/// On Mobile (Android/iOS), opens the system multi-file selector so the user
/// can open a folder and tap "Select All" without Android SAF `content://` URI
/// or iOS sandbox directory-listing restrictions.
/// On Desktop (Windows/macOS/Linux), opens the native folder picker dialog and
/// lists all files in the selected directory.
Future<List<XFile>?> pickFolderFilesPlatform() async {
  if (Platform.isAndroid || Platform.isIOS) {
    return _pickMultipleFilesMobile();
  }

  try {
    final directoryPath = await getDirectoryPath(
      confirmButtonText: 'Choose a folder',
    );
    if (directoryPath == null || directoryPath.isEmpty) {
      return null;
    }
    final dir = Directory(directoryPath);
    if (!await dir.exists()) {
      return await _pickMultipleFilesMobile();
    }
    final entities = await dir.list(followLinks: false).toList();
    final files = entities.whereType<File>().toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    return files
        .map(
          (f) => XFile(
            f.path,
            name: f.uri.pathSegments.isNotEmpty
                ? f.uri.pathSegments.last
                : f.path.split(RegExp(r'[/\\]')).last,
          ),
        )
        .toList();
  } on UnimplementedError {
    return _pickMultipleFilesMobile();
  }
}
