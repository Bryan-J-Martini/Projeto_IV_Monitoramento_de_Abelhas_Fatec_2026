import cv2
import requests
import time
import os

# URL do endpoint de stream do seu servidor FastAPI
SERVER_URL = "http://localhost:8000/api/v1/hives/colmeia_jatai_01/stream-frame"

# Caminho para o seu vídeo de teste (.mp4)
VIDEO_PATH = "0010-1.mp4"

def main():
    if not os.path.exists(VIDEO_PATH):
        print(f"Erro: O arquivo de vídeo '{VIDEO_PATH}' não foi encontrado na raiz do projeto.")
        return

    # Abre o arquivo de vídeo em vez da webcam
    cap = cv2.VideoCapture(VIDEO_PATH)
    
    if not cap.isOpened():
        print(f"Erro: Não foi possível abrir o arquivo de vídeo {VIDEO_PATH}")
        return

    print(f"🎬 Iniciando transmissão de teste com o vídeo: {VIDEO_PATH}")
    print("Pressione Ctrl+C no terminal para encerrar.")

    try:
        while cap.isOpened():
            ret, frame = cap.read()
            
            # Se o vídeo chegar ao fim, reinicia o loop automaticamente
            if not ret:
                print("🔄 Fim do vídeo alcançado. Reiniciando o loop...")
                cap.set(cv2.CAP_PROP_POS_FRAMES, 0)
                continue

            # Codifica o frame atual para formato JPEG em memória
            success, encoded_image = cv2.imencode(".jpg", frame)
            if not success:
                continue

            # Envia o frame via requisição POST multipart/form-data para o FastAPI
            files = {"file": ("frame.jpg", encoded_image.tobytes(), "image/jpeg")}
            try:
                response = requests.post(SERVER_URL, files=files, timeout=1)
                res_data = response.json()
                print(f"Frame processado | Contagens - Entradas: {res_data['counts']['entries']} | Saídas: {res_data['counts']['exits']}")
            except Exception as e:
                print(f"Aviso: Erro ao comunicar com o servidor: {e}")

            # Controla a velocidade de envio (ajuste o sleep se o vídeo estiver muito rápido ou lento)
            time.sleep(0.05)
            
    except KeyboardInterrupt:
        print("\nSimulação por vídeo encerrada pelo utilizador.")
    finally:
        cap.release()

def get_processing_active(self, hive_id: str) -> bool:
    """Retorna se o processamento está ativo para a colmeia."""
    return self.is_processing_active.get(hive_id, True)

if __name__ == "__main__":
    main()