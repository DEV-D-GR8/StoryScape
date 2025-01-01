from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
import logging
import io
from ..utils.helpers import generate_audio_filename
from ..utils.tts_utils import prepare_text_for_tts
from ..utils.s3_utils import check_s3_for_audio, upload_to_s3, get_audio_stream_from_s3
import openai  # For TTS

logger = logging.getLogger(__name__)

@api_view(['POST'])
def generate_audio(request):
    try:
        story_content = request.data.get('story_content')
        if not story_content:
            return Response({"detail": "No story content provided."}, status=status.HTTP_400_BAD_REQUEST)

        # Generate filename based on story content
        filename = generate_audio_filename(story_content)

        # Check if audio already exists in S3
        if check_s3_for_audio(filename):
            logger.info(f"Found existing audio file: {filename}")
            return get_audio_stream_from_s3(filename)

        # Prepare text for TTS
        story_text = prepare_text_for_tts(story_content)

        # Generate speech using OpenAI TTS
        response = openai.Audio.synthesize(
            model="tts-1-hd",
            voice="onyx",
            input=story_text,
            speed=0.95,
        )

        # Create an in-memory bytes buffer
        audio_bytes = io.BytesIO(response['audio'])

        # Upload to S3
        upload_to_s3(audio_bytes, filename)

        # Return the audio stream from S3
        return get_audio_stream_from_s3(filename)
    except Exception as e:
        logging.error(f"Audio generation failed: {str(e)}")
        return Response({"detail": f"Audio generation failed: {str(e)}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
