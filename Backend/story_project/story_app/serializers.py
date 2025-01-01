from rest_framework import serializers

class StoryRequestSerializer(serializers.Serializer):
    prompt = serializers.CharField()
    response_language = serializers.CharField(default="Hindi")
    age_group = serializers.CharField(default="3-5")
    selected_words = serializers.ListField(child=serializers.CharField(), required=False)

class StoryResponseSerializer(serializers.Serializer):
    title = serializers.CharField()
    introduction = serializers.CharField()
    middle = serializers.CharField()
    conclusion = serializers.CharField()
    intro_image_url = serializers.URLField(allow_null=True, required=False)
    middle_image_url = serializers.URLField(allow_null=True, required=False)

class SuggestionsRequestSerializer(serializers.Serializer):
    selected_words = serializers.ListField(child=serializers.CharField())
    response_language = serializers.CharField()
    age_group = serializers.CharField()

class SuggestionsResponseSerializer(serializers.Serializer):
    suggestions = serializers.ListField(child=serializers.CharField())
