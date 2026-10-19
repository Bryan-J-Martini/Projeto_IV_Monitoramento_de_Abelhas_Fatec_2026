import 'package:image_picker/image_picker.dart';

class SimulationService {
  final ImagePicker _picker = ImagePicker();

  // Permite selecionar uma imagem da galeria do emulador para simular a câmera do ESP32
  Future<XFile?> pickSimulationImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      return image;
    } catch (e) {
      return null;
    }
  }
}