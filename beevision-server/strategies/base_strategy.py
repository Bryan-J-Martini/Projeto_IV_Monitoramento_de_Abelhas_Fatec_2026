from abc import ABC, abstractmethod
from typing import List, Dict

class BaseCountingStrategy(ABC):
    @abstractmethod
    def update_tracks(
        self, 
        tracks: List[dict], 
        roi_polygons: List[List[List[int]]], 
        boundary_margin: int = 20, 
        frame_width: int = 640, 
        frame_height: int = 480
    ) -> Dict[str, int]:
        """
        Processa as trilhas atuais e retorna o acumulado de entradas e saídas.
        """
        pass