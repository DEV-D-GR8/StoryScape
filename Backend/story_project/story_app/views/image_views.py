from rest_framework.decorators import api_view, parser_classes
from rest_framework.response import Response
from rest_framework import status
from rest_framework.parsers import MultiPartParser, FormParser
import logging
import base64
import json
import openai  # For image analysis and generation
from ..serializers import StoryResponseSerializer
from ..utils.sagemaker_utils import call_sagemaker_llm
from ..utils.helpers import clean_json_string

logger = logging.getLogger(__name__)

@api_view(['POST'])
@parser_classes([MultiPartParser, FormParser])
def analyze_image(request):
    try:
        file = request.FILES.get('file')
        prompt = request.data.get('prompt')
        response_language = request.data.get('response_language', 'Hindi')
        age_group = request.data.get('age_group', '3-5')
        selected_words = request.data.getlist('selected_words', [])
        include_images = request.data.get('include_images', 'True') == 'True'

        # Read and encode the image
        contents = file.read()
        base64_image = base64.b64encode(contents).decode('utf-8')

        # Image analysis code kept without modification
        image_analysis_response = openai.ChatCompletion.create(
            model="gpt-4",
            messages=[
                {
                    "role": "user",
                    "content": [
                        {"type": "text", "text": "Describe this image in detail to use as a story prompt. Focus on the main elements, mood, and any interesting details that could inspire a story."},
                        {
                            "type": "image",
                            "image": {
                                "base64": base64_image
                            }
                        }
                    ]
                }
            ],
            max_tokens=300
        )
        image_description = image_analysis_response.choices[0].message.content

        # Combine image description with user prompt
        combined_prompt = f"{prompt}\nIncorporating these visual elements: {image_description}"

        # Build the prompt for story generation
        story_prompt = f"""
Create a story suitable for children aged {age_group}, in {response_language}, based on this prompt: "{combined_prompt}".
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

        intro_image_url = None
        middle_image_url = None

        if include_images:
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
        else:
            logger.info("Skipping image generation as per user request.")

        # Return the response
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
        logger.error(f"Image analysis and story generation failed: {str(e)}")
        return Response({"detail": f"Image analysis and story generation failed: {str(e)}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
