from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
import logging
import json
from ..serializers import StoryRequestSerializer, StoryResponseSerializer
from ..utils.sagemaker_utils import call_sagemaker_llm
from ..utils.helpers import clean_json_string
import openai  # For image generation

logger = logging.getLogger(__name__)

@api_view(['POST'])
def generate_story(request):
    serializer = StoryRequestSerializer(data=request.data)
    if serializer.is_valid():
        prompt = serializer.validated_data.get('prompt')
        response_language = serializer.validated_data.get('response_language')
        age_group = serializer.validated_data.get('age_group')
        selected_words = serializer.validated_data.get('selected_words', [])
        try:
            logger.info(f"Received story request with prompt: {prompt}")
            story_prompt = f"""
Create a story suitable for children aged {age_group}, in {response_language}, based on this prompt: "{prompt}".
Incorporate the following words or genres if possible: {', '.join(selected_words)}.
Return ONLY a JSON object with this exact structure:
{{
    "title": "Story title here",
    "introduction": "Introduction paragraph here",
    "middle": "Middle paragraph here",
    "conclusion": "Conclusion paragraph here"
}}
Use only basic punctuation (periods, commas, apostrophes) and avoid special characters.
"""

            # Call SageMaker LLM for story generation
            response_text = call_sagemaker_llm(story_prompt)
            cleaned_json = clean_json_string(response_text)
            story_json = json.loads(cleaned_json)

            # Image generation code kept without modification
            try:
                logger.info("Generating introduction image...")
                intro_image_response = openai.Image.create(
                    prompt=f"Generate an illustration for the following but remember NOT TO INCLUDE ANY TEXT IN THE IMAGE: {story_json['introduction']}",
                    n=1,
                    size="1024x1024"
                )
                intro_image_url = intro_image_response['data'][0]['url']

                logger.info("Generating middle image...")
                middle_image_response = openai.Image.create(
                    prompt=f"Generate an illustration for the following but remember NOT TO INCLUDE ANY TEXT IN THE IMAGE: {story_json['middle']}",
                    n=1,
                    size="1024x1024"
                )
                middle_image_url = middle_image_response['data'][0]['url']
            except Exception as e:
                logger.error(f"Image generation failed: {str(e)}")
                return Response({"detail": f"Image generation failed: {str(e)}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

            logger.info("Successfully generated story and images")
            response_serializer = StoryResponseSerializer({
                'title': story_json['title'],
                'introduction': story_json['introduction'],
                'middle': story_json['middle'],
                'conclusion': story_json['conclusion'],
                'intro_image_url': intro_image_url,
                'middle_image_url': middle_image_url
            })
            return Response(response_serializer.data)
        except Exception as e:
            logger.error(f"Story generation failed: {str(e)}", exc_info=True)
            return Response({"detail": f"Story generation failed: {str(e)}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    else:
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
