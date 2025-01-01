import logging
import re
import hashlib
import json

logger = logging.getLogger(__name__)

def clean_json_string(text):
    """Clean and prepare text for JSON parsing."""
    logger.debug(f"Original text received: {repr(text)}")

    # Remove any potential markdown code block syntax
    text = re.sub(r'```json\s*|\s*```', '', text)
    logger.debug(f"After removing code blocks: {repr(text)}")

    # Remove any non-JSON text before or after the JSON object
    json_match = re.search(r'\{.*\}', text, re.DOTALL)
    if not json_match:
        logger.error("No JSON object found in the text")
        raise ValueError("No JSON object found in the text")

    json_str = json_match.group(0)
    logger.debug(f"Extracted JSON string: {repr(json_str)}")

    # Replace smart quotes and other problematic characters
    json_str = json_str.replace('“', '"').replace('”', '"')
    json_str = json_str.replace('\n', ' ').replace('\r', '')
    json_str = re.sub(r'[\u2018\u2019]', "'", json_str)
    json_str = re.sub(r'[\u201C\u201D]', '"', json_str)
    json_str = re.sub(r'[\u2013\u2014]', '-', json_str)

    logger.debug(f"Final cleaned JSON string: {repr(json_str)}")
    return json_str

def generate_audio_filename(story_content):
    """Generate a unique filename for the audio file based on story content"""
    content_string = f"{story_content['title']}{story_content['introduction']}{story_content['middle']}{story_content['conclusion']}"
    filename_hash = hashlib.md5(content_string.encode()).hexdigest()
    return f"story_audio_{filename_hash}.mp3"
