import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:file_selector/file_selector.dart';

@JS('document.createElement')
external _HTMLInputElement _createElement(String tagName);

extension type _HTMLInputElement._(JSObject _) implements JSObject {
  external set type(String value);
  external set multiple(bool value);
  external void setAttribute(String name, String value);
  external _FileList? get files;
  external set onchange(JSFunction? callback);
  external set oncancel(JSFunction? callback);
  external void click();
}

extension type _FileList._(JSObject _) implements JSObject {
  external int get length;
  external _WebFile? item(int index);
}

extension type _WebFile._(JSObject _) implements JSObject {
  external String get name;
  external JSPromise<JSArrayBuffer> arrayBuffer();
}

/// Opens a browser directory picker (`webkitdirectory`) and returns all files
/// inside the selected folder as [XFile] instances, or `null` if cancelled.
Future<List<XFile>?> pickFolderFilesPlatform() async {
  final completer = Completer<List<XFile>?>();
  final input = _createElement('input');
  input.type = 'file';
  input.multiple = true;
  input.setAttribute('webkitdirectory', '');
  input.setAttribute('directory', '');

  Future<void> readSelectedFiles() async {
    if (completer.isCompleted) return;
    final fileList = input.files;
    if (fileList == null) {
      completer.complete(null);
      return;
    }
    final result = <XFile>[];
    final count = fileList.length;
    for (int i = 0; i < count; i++) {
      final f = fileList.item(i);
      if (f == null) continue;
      final name = f.name;
      if (name.toLowerCase().endsWith('.fit')) {
        final buffer = await f.arrayBuffer().toDart;
        final bytes = buffer.toDart.asUint8List();
        result.add(
          XFile.fromData(Uint8List.fromList(bytes), name: name, path: name),
        );
      } else {
        // Do not read bytes of non-.fit files; keep entry so importFitFolder
        // can report skipped non-.fit files.
        result.add(XFile.fromData(Uint8List(0), name: name, path: name));
      }
    }
    if (!completer.isCompleted) {
      completer.complete(result);
    }
  }

  void onInputChanged(JSAny? _) {
    unawaited(readSelectedFiles());
  }

  void onInputCancelled(JSAny? _) {
    if (!completer.isCompleted) {
      completer.complete(null);
    }
  }

  input.onchange = onInputChanged.toJS;
  input.oncancel = onInputCancelled.toJS;

  input.click();
  return completer.future;
}
