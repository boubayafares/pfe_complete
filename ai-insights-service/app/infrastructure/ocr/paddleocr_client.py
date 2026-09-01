"""OCR de documents (certificats médicaux, pièces d'identité) via
PaddleOCR — même famille d'outil que ton microservice OCR existant pour
les numéros de maillot, mais ici sur des documents complets plutôt que
des crops de joueur.

⚠️ HONNÊTETÉ: même limite que whisper_client.py — les poids PaddleOCR se
téléchargent depuis les CDN PaddlePaddle au premier usage, hors de la
liste blanche réseau de ce bac à sable. Le code est correct et suit
l'API réelle de PaddleOCR, mais n'a pas pu être exécuté avec un vrai
modèle ici — testé uniquement via un client factice
(tests/test_document_extraction_use_case.py). À valider avec un vrai
`pip install paddleocr` avant mise en production.

RAPPEL SÉCURITÉ (déjà signalé plus tôt dans la conversation): ces
documents contiennent des données sensibles de mineurs (identité, santé)
— même traités localement, ils exigent un chiffrement au repos et une
politique de rétention explicite, pas seulement un pipeline OCR qui
fonctionne.
"""
from __future__ import annotations

from pathlib import Path


class OcrUnavailableError(Exception):
    pass


class PaddleOcrClient:
    def __init__(self, lang: str = "fr") -> None:
        self._lang = lang
        self._engine = None

    def _ensure_loaded(self):
        if self._engine is None:
            try:
                from paddleocr import PaddleOCR

                self._engine = PaddleOCR(use_angle_cls=True, lang=self._lang, show_log=False)
            except Exception as err:  # noqa: BLE001
                raise OcrUnavailableError(str(err)) from err
        return self._engine

    def extract_text(self, image_path: Path) -> list[tuple[str, float]]:
        """Renvoie une liste de (texte_ligne, confiance) dans l'ordre de
        lecture détecté par PaddleOCR."""
        engine = self._ensure_loaded()
        result = engine.ocr(str(image_path), cls=True)
        lines: list[tuple[str, float]] = []
        for page in result:
            for _box, (text, confidence) in page:
                lines.append((text, round(float(confidence), 3)))
        return lines
