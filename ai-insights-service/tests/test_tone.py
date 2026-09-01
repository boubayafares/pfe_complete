from app.domain.tone.entities import ToneFlag
from app.domain.tone.services import analyze_tone


def test_empty_comment_flagged():
    result = analyze_tone("   ")
    assert result.flag == ToneFlag.EMPTY


def test_harsh_comment_flagged_with_suggestion():
    result = analyze_tone("Ce joueur est nul, aucun niveau.")
    assert result.flag == ToneFlag.TOO_HARSH
    assert "nul" in result.matched_terms
    assert result.suggestion is not None


def test_short_generic_comment_flagged():
    result = analyze_tone("bien")
    assert result.flag == ToneFlag.TOO_GENERIC


def test_generic_word_in_detailed_comment_is_not_flagged():
    result = analyze_tone("A bien géré la pression en fin de match, a su relancer proprement sous pression.")
    assert result.flag == ToneFlag.OK


def test_constructive_detailed_comment_is_ok():
    result = analyze_tone("Perd trop souvent le ballon sous pression, à travailler en conduite de balle la semaine prochaine.")
    assert result.flag == ToneFlag.OK


def test_arabic_harsh_term_detected():
    result = analyze_tone("مستوى ضعيف جدا اليوم")
    assert result.flag == ToneFlag.TOO_HARSH
