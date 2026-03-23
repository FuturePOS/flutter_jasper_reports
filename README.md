# flutter_jasper_reports

A Flutter desktop plugin (Windows, macOS, Linux) that allows you to compile `.jrxml` files and generate PDFs locally using JasperReports. 

Because JasperReports is a Java library, this plugin is built utilizing:
1. **Dart FFI** - To communicate natively out of Dart.
2. **C++ JNI Bridge** - To dynamically spin up a Java Virtual Machine (JVM).
3. **Java Fat JAR** - Executing the Jasper compiler and PDF export through an embedded Java archive.

## Prerequisites

- **Java JDK/JRE**: Because this plugin uses JNI to embed a Java Virtual Machine, the device compiling and running this application must have a valid Java Development Kit or Java Runtime installed and accessible via system paths (like `JAVA_HOME`).
- **CMake**: Necessary for the C++ compiler to link JNI headers.

## 1. Building the Java Dependencies

Before compiling or running your Flutter app, you **must build** the Java Native Wrapper into a "Fat JAR." This JAR contains JasperReports, its JSON dependencies, and the PDF generation logic.

1. Navigate to the `java` folder inside this plugin:
   ```bash
   cd java
   ```
2. Build the Fat JAR using Gradle:
   ```bash
   gradle shadowJar
   # or ./gradlew shadowJar if you use a wrapper
   ```
3. Copy the generated `jasper-generator-1.0-SNAPSHOT.jar` from `java/build/libs/` into the `assets/` directory at the root of this plugin project. If the directory doesn't exist, create it.

## 2. Installing via Git

To use this plugin directly from a Git repository instead of pub.dev, add the following to the `dependencies` section of your app's `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_jasper_reports:
    git:
      url: https://github.com/FuturePOS/flutter_jasper_reports.git
      ref: master # (Optional) specify branch, tag, or commit hash
```

## 3. Usage

Inside your application, you can simply invoke the plugin! The required Java dependencies are bundled in the package assets automatically and extracted to your device temp folder at runtime.

```dart
import 'package:flutter_jasper_reports/jasper_flutter_bridge.dart';

// ... 

final pdfFile = await JasperFlutterBridge.exportPdf(
  // Path to your JRXML inside flutter assets
  assetJrxmlPath: 'assets/reports/my_report.jrxml',
  
  // Top-level document parameters
  parameters: {
    "ReportTitle": "Monthly Sales Data",
    "Author": "Your Flutter App"
  },
  
  // Detail band data sets (Iterates over Jasper Rows)
  dataList: [
    {"itemName": "Product A", "price": 40.0, "qty": 1},
    {"itemName": "Product B", "price": 10.0, "qty": 5}
  ],
  
  // Required Output name (Will be saved to device's temporary directory)
  outputFileName: "generated_report.pdf",
);

print('Success! PDF temporary file saved to: ${pdfFile.path}');

// Example: Copying the PDF to your system's Documents Directory
final docsDir = await getApplicationDocumentsDirectory();
final permanentPath = '${docsDir.path}/generated_report.pdf';
final finalPdfFile = await pdfFile.copy(permanentPath);

print('Success! PDF permanently saved to: ${finalPdfFile.path}');
```

## Troubleshooting

- **"Could not find class com.jasperbridge.JasperGenerator"**: The Jar path passed to `exportPdf` is invalid or the Jar wasn't correctly built with `shadowJar`.
- **"Failed to initialize JVM"**: Your system lacks a JRE/JDK, or CMake failed to link against the local JNI libraries on your host machine.
