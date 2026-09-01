"""Thin wrapper around statsbombpy — isolates the third-party dependency so
the calibration script (and any future caller) doesn't import statsbombpy
directly. StatsBomb's open data requires no authentication but does require
attribution in any published output — see README.
"""
from __future__ import annotations

import pandas as pd


class StatsBombClient:
    def __init__(self) -> None:
        # Import différé: statsbombpy n'est requis que pour la calibration
        # offline (scripts/calibrate_from_statsbomb.py), jamais au runtime
        # de l'API de scoring — inutile d'alourdir l'image Docker du
        # service principal avec cette dépendance si elle n'est utilisée
        # que ponctuellement en local pour recalibrer.
        from statsbombpy import sb

        self._sb = sb

    def list_matches(self, competition_id: int, season_id: int) -> pd.DataFrame:
        return self._sb.matches(competition_id=competition_id, season_id=season_id)

    def events(self, match_id: int) -> pd.DataFrame:
        return self._sb.events(match_id=match_id)

    def lineups(self, match_id: int) -> dict:
        return self._sb.lineups(match_id=match_id)
