from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
from pydantic import BaseModel
from typing import List, Optional
import os
import json

from services.yolo_service import YOLOService
from strategies.line_crossing import LineCrossingStrategy
from strategies.boundary_exit import BoundaryExitStrategy

app = FastAPI(
    title="BeeVision Processing Server",
    description="Servidor local para processamento de visão computacional e tráfego de colmeias (MeliponaCare)",
    version="1.0.0"
)

# Inicializa o serviço YOLO global
yolo_service = YOLOService()

# Garante a existência das pastas necessárias
os.makedirs("media", exist_ok=True)
os.makedirs("static", exist_ok=True)

# Monta os diretórios estáticos e de media
app.mount("/media", StaticFiles(directory="media"), name="media")
app.mount("/static", StaticFiles(directory="static"), name="static")


# Modelos Pydantic
class RoiConfig(BaseModel):
    roi_polygons: List[List[List[int]]]


class LogicConfig(BaseModel):
    counting_strategy: str  # "LINE_CROSSING" ou "BOUNDARY_EXIT"
    boundary_margin_px: Optional[int] = 20


class ProcessingState(BaseModel):
    active: bool


@app.get("/admin", include_in_schema=False)
async def admin_panel():
    """Serve o painel web interativo principal (BeeVision Admin Hub)[cite: 1]."""
    return FileResponse("static/index.html")


@app.post("/api/v1/hives/{hive_id}/stream-frame")
async def stream_frame(hive_id: str, file: UploadFile = File(...)):
    """
    Recebe o frame individual em JPEG, executa o YOLO Nano + Rastreamento e atualiza as contagens[cite: 2].
    """
    try:
        contents = await file.read()
        output_image_path = os.path.join("media", f"{hive_id}_annotated.jpg")
        
        # Processa o frame através do serviço de visão computacional
        counts = yolo_service.process_frame(hive_id, contents, output_image_path)
        
        return {
            "status": "success",
            "hive_id": hive_id,
            "counts": counts,
            "annotated_url": f"http://localhost:8000/media/{hive_id}_annotated.jpg"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/api/v1/hives/{hive_id}/roi")
async def get_roi(hive_id: str):
    """Retorna a ROI salva atualmente no servidor[cite: 1]."""
    polygons = yolo_service.roi_polygons.get(hive_id, [])
    return {
        "status": "success",
        "hive_id": hive_id,
        "roi_polygons": polygons
    }


@app.post("/api/v1/hives/{hive_id}/roi")
async def set_roi(hive_id: str, config: RoiConfig):
    # Atualiza o serviço YOLO e persiste automaticamente no config.json
    yolo_service.set_roi(hive_id, config.roi_polygons)
    return {
        "status": "success",
        "hive_id": hive_id,
        "roi_polygons": config.roi_polygons,
        "message": "ROI multi-poligonal configurada e salva com sucesso."
    }


@app.post("/api/v1/hives/{hive_id}/config/logic")
async def set_logic(hive_id: str, config: LogicConfig):
    if config.counting_strategy == "LINE_CROSSING":
        strategy = LineCrossingStrategy()
    elif config.counting_strategy == "BOUNDARY_EXIT":
        strategy = BoundaryExitStrategy()
    else:
        raise HTTPException(status_code=400, detail="Estratégia inválida.")
        
    yolo_service.set_strategy(hive_id, strategy)
    
    # Persiste também as configurações lógicas no config.json
    config_file = "config.json"
    data = {}
    if os.path.exists(config_file):
        try:
            with open(config_file, "r", encoding="utf-8") as f:
                data = json.load(f)
        except Exception:
            data = {}
            
    data["counting_strategy"] = config.counting_strategy
    data["boundary_margin_px"] = config.boundary_margin_px
    
    try:
        with open(config_file, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2)
    except Exception as e:
        print(f"Erro ao salvar lógica no {config_file}: {e}")
    
    return {
        "status": "success",
        "hive_id": hive_id,
        "active_counting_strategy": config.counting_strategy
    }


@app.post("/api/v1/hives/{hive_id}/processing/toggle")
async def toggle_processing(hive_id: str, state: ProcessingState):
    """Habilita ou desabilita o processamento de frames e dados da colmeia."""
    yolo_service.set_processing_active(hive_id, state.active)
    return {
        "status": "success",
        "hive_id": hive_id,
        "processing_active": state.active
    }


@app.get("/api/v1/hives/{hive_id}/processing/status")
async def get_processing_status(hive_id: str):
    """Retorna o estado atual de processamento (ativo ou pausado)."""
    active = yolo_service.get_processing_active(hive_id)
    return {
        "status": "success",
        "hive_id": hive_id,
        "processing_active": active
    }


@app.get("/api/v1/hives/{hive_id}/traffic/latest")
async def get_latest_traffic(hive_id: str):
    counts = yolo_service.current_counts.get(hive_id, {"entries": 0, "exits": 0})
    
    return {
        "hive_id": hive_id,
        "timestamp": "2026-10-31T11:45:00Z",
        "data": {
            "temperature": 29.5,
            "entries": counts["entries"],
            "exits": counts["exits"],
            "traffic_rate_per_minute": counts["entries"] + counts["exits"],
            "active_counting_strategy": "LINE_CROSSING"
        },
        "media": {
            "annotated_frame_url": f"http://localhost:8000/media/{hive_id}_annotated.jpg"
        }
    }

class LogicConfig(BaseModel):
    counting_strategy: str  # "LINE_CROSSING" ou "BOUNDARY_EXIT"
    boundary_margin_px: Optional[int] = 20
    invert_direction: Optional[bool] = False

@app.post("/api/v1/hives/{hive_id}/config/logic")
async def set_logic(hive_id: str, config: LogicConfig):
    invert = config.invert_direction if config.invert_direction is not None else False

    if config.counting_strategy == "LINE_CROSSING":
        strategy = LineCrossingStrategy(invert_direction=invert)
    elif config.counting_strategy == "BOUNDARY_EXIT":
        strategy = BoundaryExitStrategy()
    else:
        raise HTTPException(status_code=400, detail="Estratégia inválida.")
        
    yolo_service.set_strategy(hive_id, strategy, invert=invert)
    yolo_service.set_margin(hive_id, config.boundary_margin_px)
    
    config_file = "config.json"
    data = {}
    if os.path.exists(config_file):
        try:
            with open(config_file, "r", encoding="utf-8") as f:
                data = json.load(f)
        except Exception:
            data = {}
            
    data["counting_strategy"] = config.counting_strategy
    data["boundary_margin_px"] = config.boundary_margin_px
    data["invert_direction"] = invert
    
    try:
        with open(config_file, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2)
    except Exception as e:
        print(f"Erro ao salvar lógica no {config_file}: {e}")
    
    return {
        "status": "success",
        "hive_id": hive_id,
        "active_counting_strategy": config.counting_strategy,
        "invert_direction": invert
    }

@app.get("/api/v1/hives/{hive_id}/config/logic")
async def get_logic(hive_id: str):
    """Retorna a configuração atual de lógica e direção."""
    strategy_name = "LINE_CROSSING"
    if hive_id in yolo_service.strategies:
        if isinstance(yolo_service.strategies[hive_id], BoundaryExitStrategy):
            strategy_name = "BOUNDARY_EXIT"
            
    return {
        "status": "success",
        "hive_id": hive_id,
        "counting_strategy": strategy_name,
        "boundary_margin_px": yolo_service.boundary_margins.get(hive_id, 20),
        "invert_direction": yolo_service.invert_directions.get(hive_id, False)
    }