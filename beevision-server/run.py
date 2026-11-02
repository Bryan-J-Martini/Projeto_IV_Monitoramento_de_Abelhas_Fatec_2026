import os
import subprocess
import sys
import webbrowser
import time
from threading import Timer

def open_browser():
    url = "http://localhost:8000/admin"
    print(f"Abrindo navegador em: {url}")
    webbrowser.open(url)

if __name__ == "__main__":
    print("Iniciando o BeeVision Admin Hub...")
    
    # Garante a existência dos diretórios necessários
    os.makedirs("media", exist_ok=True)
    os.makedirs("static/js", exist_ok=True)
    os.makedirs("static/css", exist_ok=True)

    # Agenda a abertura do navegador após 1.5 segundos para dar tempo do servidor subir
    Timer(1.5, open_browser).start()

    try:
        # Inicializa o Uvicorn apontando para o FastAPI (main:app)
        import uvicorn
        uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
    except KeyboardInterrupt:
        print("\nServidor encerrado pelo utilizador.")