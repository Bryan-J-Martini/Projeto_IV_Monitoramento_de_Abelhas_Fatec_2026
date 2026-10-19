import 'dart:io';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class BeeDetectorService {
  Interpreter? _interpreter;
  bool _isModelLoaded = false;

  // Carrega o modelo tflite da pasta assets
  Future<void> loadModel() async {
    if (_isModelLoaded) return;
    try {
      // Configurações opcionais do interpretador (ex: número de threads)
      final options = InterpreterOptions()..threads = 4;
      
      _interpreter = await Interpreter.fromAsset(
        'assets/model/abelha.tflite',
        options: options,
      );
      _isModelLoaded = true;
      print('Modelo abelha.tflite carregado com sucesso!');
    } catch (e) {
      print('Erro ao carregar o modelo TFLite: $e');
      _isModelLoaded = false;
    }
  }

  // Executa a detecção na imagem informada
  // Retorna uma lista de caixas delimitadoras (bounding boxes) das abelhas encontradas
  Future<List<Rect>> detectBees(File imageFile, Rect roiNormalized, Size imageSize) async {
    if (!_isModelLoaded || _interpreter == null) {
      await loadModel();
      if (!_isModelLoaded) return [];
    }

    // Nota: Aqui o ideal é redimensionar a imagem para 640x640 pixels, 
    // normalizar os pixels (0.0 a 1.0 ou -1 a 1 dependendo do seu treinamento YOLO)
    // e executar _interpreter?.run(input, output);

    // Para fins de teste inicial no emulador sem travar, retornamos uma lista simulada 
    // ou processada. No próximo ajuste, faremos o pré-processamento exato do tensor.
    
    return [];
  }

  void dispose() {
    _interpreter?.close();
  }
}