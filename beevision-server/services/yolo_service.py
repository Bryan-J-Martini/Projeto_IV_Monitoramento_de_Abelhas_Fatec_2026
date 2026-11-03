import cv2
import json
import os
import numpy as np
import threading
from ultralytics import YOLO
from typing import Dict, List
from strategies.line_crossing import LineCrossingStrategy
from strategies.boundary_exit import BoundaryExitStrategy

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CONFIG_FILE = os.path.join(BASE_DIR, "config.json")

class YOLOService:
    def __init__(self, model_path: str = "best.pt"):
        self.model = YOLO(model_path)
        self.strategies: Dict = {}
        self.roi_polygons: Dict[str, List[List[List[int]]]] = {}
        self.current_counts: Dict[str, Dict[str, int]] = {}
        self.is_processing_active: Dict[str, bool] = {}
        self.boundary_margins: Dict[str, int] = {}
        self.invert_directions: Dict[str, bool] = {}
        self._load_config()

    def _load_config(self):
        if os.path.exists(CONFIG_FILE):
            try:
                with open(CONFIG_FILE, "r", encoding="utf-8") as f:
                    data = json.load(f)
                    hive_id = data.get("hive_id", "colmeia_jatai_01")
                    
                    if "roi_polygons" in data:
                        self.roi_polygons[hive_id] = data["roi_polygons"]
                        
                    margin = data.get("boundary_margin_px", 20)
                    self.boundary_margins[hive_id] = margin
                    
                    invert = data.get("invert_direction", False)
                    self.invert_directions[hive_id] = invert

                    strategy_name = data.get("counting_strategy", "LINE_CROSSING")
                    if strategy_name == "BOUNDARY_EXIT":
                        self.strategies[hive_id] = BoundaryExitStrategy()
                    else:
                        self.strategies[hive_id] = LineCrossingStrategy(invert_direction=invert)
            except Exception as e:
                print(f"Erro ao ler {CONFIG_FILE}: {e}")
        else:
            self.strategies["colmeia_jatai_01"] = LineCrossingStrategy()
            self.boundary_margins["colmeia_jatai_01"] = 20
            self.invert_directions["colmeia_jatai_01"] = False

    def set_roi(self, hive_id: str, polygons: List[List[List[int]]]):
        self.roi_polygons[hive_id] = polygons
        self._save_config_field(hive_id, "roi_polygons", polygons)

    def set_strategy(self, hive_id: str, strategy_instance, invert: bool = False):
        self.strategies[hive_id] = strategy_instance
        self.invert_directions[hive_id] = invert

    def set_margin(self, hive_id: str, margin: int):
        self.boundary_margins[hive_id] = margin
        self._save_config_field(hive_id, "boundary_margin_px", margin)

    def set_processing_active(self, hive_id: str, active: bool):
        self.is_processing_active[hive_id] = active

    def get_processing_active(self, hive_id: str) -> bool:
        return self.is_processing_active.get(hive_id, True)

    def _save_config_field(self, hive_id: str, key: str, value):
        data = {}
        if os.path.exists(CONFIG_FILE):
            try:
                with open(CONFIG_FILE, "r", encoding="utf-8") as f:
                    data = json.load(f)
            except Exception:
                data = {}
        data["hive_id"] = hive_id
        data[key] = value
        try:
            with open(CONFIG_FILE, "w", encoding="utf-8") as f:
                json.dump(data, f, indent=2)
        except Exception as e:
            print(f"Erro ao atualizar {key} no config.json: {e}")

    def process_frame(self, hive_id: str, frame_bytes: bytes, output_path: str) -> Dict[str, int]:
        if not self.is_processing_active.get(hive_id, True):
            return self.current_counts.get(hive_id, {"entries": 0, "exits": 0})

        nparr = np.frombuffer(frame_bytes, np.uint8)
        frame = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

        if frame is None:
            return {"entries": 0, "exits": 0}

        height, width, _ = frame.shape
        results = self.model.track(frame, persist=True, tracker="bytetrack.yaml", verbose=False)

        tracks_data = []
        if results and results[0].boxes:
            boxes = results[0].boxes.xyxy.cpu().numpy()
            track_ids = results[0].boxes.id
            classes = results[0].boxes.cls.cpu().numpy()

            if track_ids is not None:
                track_ids = track_ids.cpu().numpy()
                for box, track_id, cls in zip(boxes, track_ids, classes):
                    x1, y1, x2, y2 = map(int, box)
                    cx = int((x1 + x2) / 2)
                    cy = int((y1 + y2) / 2)

                    tracks_data.append({
                        "track_id": int(track_id),
                        "centroid": (cx, cy)
                    })

                    cv2.rectangle(frame, (x1, y1), (x2, y2), (0, 255, 0), 2)
                    cv2.putText(frame, f"ID:{int(track_id)}", (x1, y1 - 10),
                                cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 255, 0), 2)

        polygons = self.roi_polygons.get(hive_id, [])
        for poly in polygons:
            pts = np.array(poly, np.int32).reshape((-1, 1, 2))
            cv2.polylines(frame, [pts], isClosed=True, color=(0, 0, 255), thickness=2)

        counts = {"entries": 0, "exits": 0}
        if hive_id in self.strategies:
            margin = self.boundary_margins.get(hive_id, 20)
            
            counts = self.strategies[hive_id].update_tracks(
                tracks=tracks_data, 
                roi_polygons=polygons, 
                boundary_margin=margin, 
                frame_width=width, 
                frame_height=height
            )
        
        self.current_counts[hive_id] = counts
        cv2.imwrite(output_path, frame)

        return counts