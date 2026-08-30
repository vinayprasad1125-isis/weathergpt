class LanguageDetectionService:
    def detect_language(self, text: str) -> dict:
        # Simple heuristic based on Unicode blocks for speed and reliability
        # Tamil: U+0B80 - U+0BFF
        # Devanagari (Hindi): U+0900 - U+097F
        
        tamil_count = sum(1 for c in text if 0x0B80 <= ord(c) <= 0x0BFF)
        hindi_count = sum(1 for c in text if 0x0900 <= ord(c) <= 0x097F)
        
        if tamil_count > 0 and tamil_count >= hindi_count:
            return {"language": "ta", "confidence": 0.9}
        elif hindi_count > 0:
            return {"language": "hi", "confidence": 0.9}
        return {"language": "en", "confidence": 0.9}
