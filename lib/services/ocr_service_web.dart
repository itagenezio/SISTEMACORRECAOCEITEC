class OcrService {
  Future<String> recognizeText(String imagePath) async {
    // Simulação para Web
    await Future.delayed(const Duration(seconds: 2));
    // Retorna um texto aleatório que simula o gabarito
    return """
1. A
2. B
3. C
4. D
5. E
    """;
  }
}
