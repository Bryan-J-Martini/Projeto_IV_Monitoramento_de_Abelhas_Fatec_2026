from .base_strategy import BaseCountingStrategy
from typing import List, Dict, Tuple, Optional

class LineCrossingStrategy(BaseCountingStrategy):
    def __init__(self, invert_direction: bool = False, cooldown_frames: int = 15):
        # track_id -> (ultimo_centroide, ultimo_lado_valido, frames_desde_ultimo_cruzamento)
        self.track_history: Dict[int, Tuple[Tuple[int, int], int, int]] = {}
        self.entries = 0
        self.exits = 0
        self.invert_direction = invert_direction
        self.cooldown_frames = cooldown_frames  # Impede contagem dupla da mesma abelha

    def _get_side(self, p: Tuple[int, int], line: List[List[int]]) -> int:
        if not line or len(line) < 2:
            return 0
        x1, y1 = line[0]
        x2, y2 = line[1]
        px, py = p
        
        # Produto Vetorial (Determinante 2D)
        val = (x2 - x1) * (py - y1) - (y2 - y1) * (px - x1)
        
        if abs(val) < 1.0:
            return 0
            
        multiplier = -1 if self.invert_direction else 1
        return multiplier if val > 0 else -multiplier

    def update_tracks(
        self, 
        tracks: List[dict], 
        roi_polygons: List[List[List[int]]], 
        boundary_margin: int = 20, 
        frame_width: int = 640, 
        frame_height: int = 480
    ) -> Dict[str, int]:
        
        current_active_ids = set()

        # Extrai a linha de referência do primeiro polígono ou primeira aresta
        reference_line: List[List[int]] = []
        if roi_polygons and len(roi_polygons[0]) >= 2:
            reference_line = [roi_polygons[0][0], roi_polygons[0][1]]
        else:
            # Fallback para linha horizontal no centro da tela
            mid_y = int(frame_height * 0.5)
            reference_line = [[100, mid_y], [frame_width - 100, mid_y]]

        for track in tracks:
            track_id = track.get("track_id")
            centroid = track.get("centroid")
            
            if track_id is None or centroid is None:
                continue

            current_active_ids.add(track_id)
            current_side = self._get_side(centroid, reference_line)

            if track_id in self.track_history:
                prev_centroid, last_side, cooldown = self.track_history[track_id]
                
                # Decrementa o cooldown
                new_cooldown = max(0, cooldown - 1)

                # Verifica se houve troca de lado válida e se o cooldown expirou
                if last_side != 0 and current_side != 0 and last_side != current_side:
                    if new_cooldown == 0:
                        # Lado -1 -> +1 = Entrada
                        if last_side == -1 and current_side == 1:
                            self.entries += 1
                            new_cooldown = self.cooldown_frames
                        # Lado +1 -> -1 = Saída
                        elif last_side == 1 and current_side == -1:
                            self.exits += 1
                            new_cooldown = self.cooldown_frames
                        
                        last_side = current_side
                
                if current_side != 0:
                    last_side = current_side

                self.track_history[track_id] = (centroid, last_side, new_cooldown)
            else:
                self.track_history[track_id] = (centroid, current_side, 0)

        # Limpeza de IDs perdidos
        inactive_ids = set(self.track_history.keys()) - current_active_ids
        for tid in inactive_ids:
            del self.track_history[tid]

        return {"entries": self.entries, "exits": self.exits}