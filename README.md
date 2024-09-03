# flutter_generate_pdf_isolate

A new Flutter project to demonstrate generation of PDF using HTML on separate thread using Isolates.

## Getting Started

The provided code is a Flutter application that demonstrates how to generate a PDF document using
the html_to_pdf_plus package.
And display it using the syncfusion_flutter_pdfviewer package.
The application also utilizes Dart isolates to perform the PDF generation in a separate thread,
ensuring the main UI thread remains responsive.

The _generatePdf function is responsible for generating the PDF. It defines the HTML content,
retrieves the application's document directory, and uses the HtmlToPdf.convertFromHtmlContent method
to generate the PDF file. The path to the generated PDF file is then returned:

```dart
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

```

The computeIsolate function is used to run the PDF generation in a separate isolate. It creates a
ReceivePort and spawns a new isolate, passing the _IsolateData object containing the function to be
executed and the SendPort for communication. The result from the isolate is received and returned:

```dart
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
```

The _isolateEntry function is the entry point for the spawned isolate. It receives the _IsolateData
object, executes the function, and sends the result back to the main isolate:

```dart 
void _isolateEntry(_IsolateData data) async {
  data.token.register();
  final result = await data.function();
  data.answerPort.send(result);
  data.token.deregister();
}
``` 

The _IsolateData class is a simple data class that holds the function to be executed and the
SendPort for communication:

```dart 
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
```
