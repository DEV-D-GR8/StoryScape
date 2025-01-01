from django.urls import path
from .views import get_suggestions, generate_story, analyze_image, generate_audio

urlpatterns = [
    path('get_suggestions/', get_suggestions, name='get_suggestions'),
    path('generate_story/', generate_story, name='generate_story'),
    path('analyze_image/', analyze_image, name='analyze_image'),
    path('generate_audio/', generate_audio, name='generate_audio'),
]
