import 'dart:ffi';
import 'dart:io';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:ffi/ffi.dart';

// C function signature: 
// const char* generate_jasper_pdf(const char* jrxml_path, const char* output_path, const char* json_data, const char* jar_path)
typedef _GeneratePdfC = Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>);
typedef _GeneratePdfDart = Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>);

// void free_string(char* str)
typedef _FreeStringC = Void Function(Pointer<Utf8>);
typedef _FreeStringDart = void Function(Pointer<Utf8>);

class JasperFlutterBridge {
  static final DynamicLibrary _lib = () {
    if (Platform.isMacOS || Platform.isIOS) {
      return DynamicLibrary.process();
    }
    if (Platform.isAndroid || Platform.isLinux) {
      return DynamicLibrary.open('libflutter_jasper_reports.so');
    }
    if (Platform.isWindows) {
      return DynamicLibrary.open('flutter_jasper_reports.dll');
    }
    throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
  }();

  static final _GeneratePdfDart _generatePdf = _lib
      .lookup<NativeFunction<_GeneratePdfC>>('generate_jasper_pdf')
      .asFunction();

  static final _FreeStringDart _freeString = _lib
      .lookup<NativeFunction<_FreeStringC>>('free_string')
      .asFunction();

  /// Compiles a .jrxml asset file, fills it with data, and exports it to PDF.
  /// 
  /// The [parameters] are for high-level Jasper fields (like report title, Author, strings).
  /// The [dataList] is for the detail band records (List of Maps, simulating a database).
  /// The [outputFileName] is the final name of the generated PDF file.
  /// The [jarPath] is the absolute path to the compiled Java Fat JAR containing Jasper dependencies.
  static Future<File> exportPdf({
    required String assetJrxmlPath,
    Map<String, dynamic>? parameters,
    List<Map<String, dynamic>>? dataList,
    required String outputFileName,
    required String jarPath,
  }) async {
    // 1. Setup temporary directory for absolute paths
    final tempDir = await getTemporaryDirectory();
    final jrxmlFile = File('${tempDir.path}/temp_report.jrxml');
    final pdfFile = File('${tempDir.path}/$outputFileName');

    // 2. Load JRXML from assets and copy to temp directory
    final jrxmlData = await rootBundle.load(assetJrxmlPath);
    await jrxmlFile.writeAsBytes(
      jrxmlData.buffer.asUint8List(jrxmlData.offsetInBytes, jrxmlData.lengthInBytes)
    );

    // 3. Prepare JSON data combining parameters and root list
    final requestBody = {
      "parameters": parameters ?? {},
      "data": dataList ?? []
    };
    final jsonDataString = jsonEncode(requestBody);

    // 4. Convert strings to native UTF-8 pointers
    final jrxmlPointer = jrxmlFile.path.toNativeUtf8();
    final outPointer = pdfFile.path.toNativeUtf8();
    final jsonPointer = jsonDataString.toNativeUtf8();
    final jarPointer = jarPath.toNativeUtf8();

    try {
      // 5. Invoke FFI C function
      final resultPointer = _generatePdf(
        jrxmlPointer, 
        outPointer, 
        jsonPointer, 
        jarPointer
      );
      
      final resultString = resultPointer.toDartString();
      
      // Free the result string allocated in C/JNI layer
      _freeString(resultPointer);

      if (resultString.startsWith('ERROR:')) {
        throw Exception('JasperReports Error: $resultString');
      }

      return pdfFile;
    } finally {
      // Free dart-allocated native strings
      malloc.free(jrxmlPointer);
      malloc.free(outPointer);
      malloc.free(jsonPointer);
      malloc.free(jarPointer);
    }
  }
}
