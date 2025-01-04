import google.generativeai as genai
from dotenv import load_dotenv
from storyExtractor import process_stories
import os
import time

load_dotenv()
genai.configure(api_key=os.getenv("GOOGLE_API_KEY"))
model = genai.GenerativeModel("gemini-1.5-flash")

age = ""
length = " 500 words"

genres = [""]

append_flag = False

for genre in genres:
    for i in range(100):
        try:
            prompt = (
                f"Generate a story in Hindi for children aged {age}. "
                f"The genre should be {genre}. The story should be approximately {length}. "
                "Use diverse and unique characters in each story. Incorporate multiple characters where necessary. "
                "Use unique and intriguing character names and storylines. "
                "Ensure the story is engaging and worth reading. "
                "Your response should follow this exact format: "
                "Story [story number]: Title: [Title of story] Story: [Story content] Moral: [Moral of the story] "
                "DO NOT use markdown language in the response. "
                "Ensure the story length is strictly close to {length}."
            )
            response = model.generate_content(prompt)
            story_content = response.text

            process_stories(story_content, "temp.json", append=append_flag, theme="", genre=genre)
            append_flag = True

        except Exception as e:
            print(f"Error generating story for genre {genre}, iteration {i}: {e}")

        # Pause to avoid hitting rate limits
        time.sleep(1.08)