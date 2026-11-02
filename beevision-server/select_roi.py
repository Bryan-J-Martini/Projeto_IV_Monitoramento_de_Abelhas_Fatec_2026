import cv2
import json
import requests
import numpy as np

# URL do seu servidor FastAPI local
SERVER_URL = "http://localhost:8000/api/v1/hives/colmeia_jatai_01/roi"

polygons = []
current_poly = []

def mouse_callback(event, x, y, flags, param):
    global current_poly, polygons
    if event == cv2.EVENT_LBUTTONDOWN:
        current_poly.append([x, y])
        print(f"Ponto adicionado: [{x}, {y}]")
    elif event == cv2.EVENT_RBUTTONDOWN:
        if len(current_poly) > 2:
            polygons.append(current_poly)
            print(f"Polígono {len(polygons)} fechado com {len(current_poly)} pontos.")
            current_poly = []

def main():
    global polygons, current_poly
    cap = cv2.VideoCapture(0) # ou substitua por caminho de imagem/vídeo
    ret, frame = cap.read()
    if not ret:
        print("Erro ao capturar imagem.")
        return

    # Nome único e padronizado para a janela
    window_name = "Selecione os Poligonos (Esq: Adicionar | Dir: Fechar | ESC: Salvar)"
    
    cv2.namedWindow(window_name)
    cv2.setMouseCallback(window_name, mouse_callback)

    while True:
        img_copy = frame.copy()
        
        # Desenha polígonos já finalizados
        for poly in polygons:
            pts = np.array(poly, np.int32).reshape((-1, 1, 2))
            cv2.polylines(img_copy, [pts], True, (0, 255, 0), 2)
        
        # Desenha o polígono em construção
        if len(current_poly) > 0:
            for pt in current_poly:
                cv2.circle(img_copy, tuple(pt), 4, (255, 0, 0), -1)
            pts_curr = np.array(current_poly, np.int32).reshape((-1, 1, 2))
            cv2.polylines(img_copy, [pts_curr], False, (255, 0, 0), 1)

        cv2.imshow(window_name, img_copy)
        key = cv2.waitKey(1) & 0xFF
        
        if key == 27: # Pressionar ESC para salvar e enviar
            if len(current_poly) > 2:
                polygons.append(current_poly)
                print(f"Polígono finalizado automaticamente com {len(current_poly)} pontos.")
            break

    cap.release()
    cv2.destroyAllWindows()

    # Envia os polígonos configurados para o servidor FastAPI
    payload = {"roi_polygons": polygons}
    try:
        response = requests.post(SERVER_URL, json=payload)
        print("Resposta do Servidor:", response.json())
    except Exception as e:
        print("Erro ao conectar com o servidor:", e)

if __name__ == "__main__":
    main()