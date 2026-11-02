import cv2
import numpy as np
from .base_strategy import BaseCountingStrategy
from typing import List, Dict, Tuple

class BoundaryExitStrategy(BaseCountingStrategy):
    def __init__(self, invert_direction: bool = False):
        # track_id -> (ultimo_centroide, estava_dentro_da_roi)
        self.previous_tracks: Dict[int, Tuple[Tuple[int, int], bool]] = {}
        self.entries = 0
        self.exits = 0
        self.invert_direction = invert_direction

    def _is_inside_roi(self, point: Tuple[int, int], roi_polygons: List[List[List[int]]]) -> bool:
        if not roi_polygons:
            return False
        
        px, py = point
        for poly in roi_polygons:
            if len(poly) < 3:
                continue
            pts = np.array(poly, np.int32)
            # Retorna > 0 se dentro, == 0 na borda, < 0 fora
            dist = cv2.pointPolygonTest(pts, (float(px), float(py)), False)
            if dist >= 0:
                return True
        return False

    def update_tracks(
        self, 
        tracks: List[dict], 
        roi_polygons: List[List[List[int]]], 
        boundary_margin: int = 20, 
        frame_width: int = 640, 
        frame_height: int = 480
    ) -> Dict[str, int]:
        
        current_active_ids = set()

        for track in tracks:
            track_id = track.get("track_id")
            centroid = track.get("centroid")
            
            if track_id is None or centroid is None:
                continue

            current_active_ids.add(track_id)
            inside_now = self._is_inside_roi(centroid, roi_polygons)

            if track_id in self.previous_tracks:
                prev_centroid, inside_before = self.previous_tracks[track_id]

                # Transição: FORA -> DENTRO
                if not inside_before and inside_now:
                    if self.invert_direction:
                        self.exits += 1
                    else:
                        self.entries += 1

                # Transição: DENTRO -> FORA
                elif inside_before and not inside_now:
                    if self.invert_direction:
                        self.entries += 1
                    else:
                        self.exits += 1

                self.previous_tracks[track_id] = (centroid, inside_now)
            else:
                self.previous_tracks[track_id] = (centroid, inside_now)

        # Trata abelhas que perderam a detecção (ID sumiu) estando perto da borda real da imagem
        disappeared_ids = set(self.previous_tracks.keys()) - current_active_ids
        for tid in disappeared_ids:
            last_pos, inside_before = self.previous_tracks[tid]
            x, y = last_pos

            # Se o rastreador sumiu perto da borda externa da imagem
            is_near_edge = (x <= boundary_margin or x >= frame_width - boundary_margin or 
                            y <= boundary_margin or y >= frame_height - boundary_margin)

            if is_near_edge and inside_before:
                if self.invert_direction:
                    self.entries += 1
                else:
                    self.exits += 1

            del self.previous_tracks[tid]

        return {"entries": self.entries, "exits": self.exits}