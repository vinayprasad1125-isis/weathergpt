from app.services.language_detection_service import LanguageDetectionService

def test_language_detection_english():
    detector = LanguageDetectionService()
    res = detector.detect_language("What is the weather in Chennai tomorrow?")
    assert res["language"] == "en"

def test_language_detection_tamil():
    detector = LanguageDetectionService()
    res = detector.detect_language("நாளைக்கு சென்னையில் மழை பெய்யுமா?")
    assert res["language"] == "ta"

def test_language_detection_hindi():
    detector = LanguageDetectionService()
    res = detector.detect_language("क्या कल चेन्नई में बारिश होगी?")
    assert res["language"] == "hi"
