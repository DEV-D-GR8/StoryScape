from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
import logging
import json
from ..serializers import SuggestionsRequestSerializer, SuggestionsResponseSerializer
from ..utils.sagemaker_utils import call_sagemaker_llm
from ..utils.helpers import clean_json_string

logger = logging.getLogger(__name__)

@api_view(['POST'])
def get_suggestions(request):
    serializer = SuggestionsRequestSerializer(data=request.data)
    if serializer.is_valid():
        selected_words = serializer.validated_data.get('selected_words')
        response_language = serializer.validated_data.get('response_language')
        age_group = serializer.validated_data.get('age_group')
        prompt = f"""
Based on the following preferences, generate 5 creative and engaging prompts for stories:
- Selected Words/Genres: {', '.join(selected_words)}
- Response Language: {response_language}
- Age Group: {age_group}

Provide the suggestions in the specified language.
Return ONLY a JSON object with this exact structure:
{{
    "suggestions": ["Suggestion 1", "Suggestion 2", "Suggestion 3", "Suggestion 4", "Suggestion 5"]
}}
Do not include any additional text or explanations.
"""
        try:
            response_text = call_sagemaker_llm(prompt)
            cleaned_json = clean_json_string(response_text)
            suggestions_json = json.loads(cleaned_json)
            response_serializer = SuggestionsResponseSerializer(data=suggestions_json)
            if response_serializer.is_valid():
                return Response(response_serializer.data)
            else:
                logger.error(f"Invalid response data: {response_serializer.errors}")
                return Response({"detail": "Invalid response data"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        except Exception as e:
            logger.error(f"Failed to generate suggestions: {str(e)}")
            return Response({"detail": f"Failed to generate suggestions: {str(e)}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    else:
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
