import openai  # Keep OpenAI for TTS
from .helpers import clean_json_string

def prepare_text_for_tts(story):
    """Prepare story text for TTS by adding natural pauses, emphasis, and tone variations."""
    tts_prompt = f"""
Modify this story for text-to-speech via OpenAI TTS-1-HD model by adding natural pauses, emphasis, and tone variations.
Story title: {story['title']}
Story content: {story['introduction']} {story['middle']} {story['conclusion']}

Return the modified text such that it helps the TTS model in natural storytelling.
Focus on pacing, emphasis, and emotional tone.
"""

    # Intermediate text generation code kept without modification
    response = openai.ChatCompletion.create(
        model="gpt-4o-mini",
        messages=[
            {"role": "system", "content": "You are an expert in preparing text for natural-sounding text-to-speech conversion."},
            {"role": "user", "content": tts_prompt}
        ]
    )
    tts_text = response.choices[0].message.content
    return tts_text
