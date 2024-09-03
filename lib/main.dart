import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:html_to_pdf_plus/html_to_pdf_plus.dart';
import 'package:path_provider/path_provider.dart';

import 'pdf_viewer.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PDF Generation with Isolates')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            var path = await computeIsolate(_generatePdf);
            debugPrint(path);

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    PDFViewer(path: path, appBarTitle: 'Generated PDF'),
              ),
            );
          },
          child: const Text('Generate PDF'),
        ),
      ),
    );
  }
}

Future<String> _generatePdf() async {
  const htmlContent = """
    <!DOCTYPE html>
    <html>
      <head>
        <style>
        table, th, td {
          border: 1px solid black;
          border-collapse: collapse;
        }
        th, td, p {
          padding: 5px;
          text-align: left;
        }
        </style>
      </head>
      <body>
        <h2>PDF generated using html_to_pdf_plus plugin with Isolates</h2>
        <h2>By Sabin Ranabhat</h2>

        <table style="width:100%">
          <caption>Sample HTML Table</caption>
          <tr>
            <th>Portfolio</th>
            <th>Link</th>
          </tr>
          <tr>
            <td>Github</td>
            <td><a href="https://github.com/sawin0">https://github.com/sawin0</a></td>
          </tr>
          <tr>
            <td>LinkedIn</td>
            <td><a href="https://www.linkedin.com/in/sawin0/">https://www.linkedin.com/in/sawin0/</a></td>
         </tr>
        </table>

        <img src="https://avatars.githubusercontent.com/u/10590708?v=4" alt="web-img">
      </body>
    </html>
    """;

  Directory targetPath = await getApplicationDocumentsDirectory();
  var targetFileName = "example_pdf_file";

  final generatedPdfFile = await HtmlToPdf.convertFromHtmlContent(
    htmlContent: htmlContent,
    configuration: PdfConfiguration(
      targetDirectory: targetPath.path,
      targetName: targetFileName,
      printSize: PrintSize.A4,
      printOrientation: PrintOrientation.Landscape,
      linksClickable: true,
    ),
  );

  return generatedPdfFile.path;
}

Future<String> computeIsolate(Future<String> Function() function) async {
  final receivePort = ReceivePort();
  var rootToken = RootIsolateToken.instance!;
  await Isolate.spawn<_IsolateData>(
    _isolateEntry,
    _IsolateData(
      token: rootToken,
      function: function,
      answerPort: receivePort.sendPort,
    ),
  );
  return await receivePort.first;
}

void _isolateEntry(_IsolateData isolateData) async {
  BackgroundIsolateBinaryMessenger.ensureInitialized(isolateData.token);
  final answer = await isolateData.function();
  isolateData.answerPort.send(answer);
}

class _IsolateData {
  final RootIsolateToken token;
  final Future<String> Function() function;
  final SendPort answerPort;

  _IsolateData({
    required this.token,
    required this.function,
    required this.answerPort,
  });
}
