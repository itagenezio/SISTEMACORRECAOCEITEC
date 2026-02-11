import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'dart:io';

class OcrService {
  Future<String> recognizeText(String imagePath) async {
    // ML Kit só funciona em Android e iOS.
    // Para Windows/Mac/Linux, retornamos um Mock simulado para não travar o app.
    if (!Platform.isAndroid && !Platform.isIOS) {
       await Future.delayed(const Duration(seconds: 1));
       return """
1. A
2. B
3. C
4. D
5. E
(Simulação Desktop)
       """;
    }

    final inputImage = InputImage.fromFilePath(imagePath);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
    await textRecognizer.close();
    return recognizedText.text;
  }
}
