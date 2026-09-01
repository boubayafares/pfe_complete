import pytest

from app.domain.entities import PlayerFeatures, RecommendedStatus, ScoreWeights
from app.domain.services import compute_recommendation


def test_weights_must_sum_to_one():
    with pytest.raises(ValueError):
        ScoreWeights(presence=0.5, performance=0.5, fatigue=0.5)


def test_default_weights_are_equal_thirds():
    w = ScoreWeights.default()
    assert w.presence == pytest.approx(1 / 3)
    assert w.performance == pytest.approx(1 / 3)
    assert w.fatigue == pytest.approx(1 / 3)


def test_high_everything_gives_starter():
    features = PlayerFeatures(
        player_id=1,
        presence_rate=0.95,
        recent_performance_rating=8.5,
        acute_chronic_workload_ratio=1.0,  # sweet spot
        days_since_last_match=5,
    )
    result = compute_recommendation(features, ScoreWeights.default())
    assert result.recommended_status == RecommendedStatus.STARTER
    assert result.final_score >= 70


def test_low_presence_gives_not_selected():
    features = PlayerFeatures(
        player_id=2,
        presence_rate=0.1,
        recent_performance_rating=3.0,
        acute_chronic_workload_ratio=2.5,  # forte surcharge
        days_since_last_match=0,
    )
    result = compute_recommendation(features, ScoreWeights.default())
    assert result.recommended_status == RecommendedStatus.NOT_SELECTED


def test_overload_acwr_penalizes_fatigue_score():
    low_acwr = PlayerFeatures(1, 0.8, 7.0, 1.0, 3)
    high_acwr = PlayerFeatures(1, 0.8, 7.0, 2.5, 3)
    weights = ScoreWeights.default()
    result_low = compute_recommendation(low_acwr, weights)
    result_high = compute_recommendation(high_acwr, weights)
    assert result_high.fatigue_score < result_low.fatigue_score


def test_invalid_presence_rate_rejected():
    with pytest.raises(ValueError):
        PlayerFeatures(player_id=1, presence_rate=1.5, recent_performance_rating=5, acute_chronic_workload_ratio=1.0, days_since_last_match=1)
