import re
import json
import os

def clean_text(text):
    # Remove timestamps and sender information
    cleaned_text = re.sub(r'\[\d{1,2}:\d{2} [APMapm]{2}, \d{1,2}/\d{1,2}/\d{4}\] [^\:]*\:', '', text)
    return cleaned_text

def extract_story_details(text, theme_provided=True, theme="", genre_provided=True, genre=""):
    # Remove Markdown symbols and extract details
    details = {}
    
    # Extract Title
    title_match = re.search(r'Title:\s*(.*)', text)
    details['Title'] = title_match.group(1).strip() if title_match else "Title not found"
    
    # Extract Theme
    if theme_provided:
        details['Theme'] = theme
    else:
        theme_match = re.search(r'Theme:\s*(.*)', text)
        details['Theme'] = theme_match.group(1).strip() if theme_match else "Theme not found"
    
    # Extract Genre
    if genre_provided:
        details['Genre'] = genre
    else:
        genre_match = re.search(r'Genre:\s*(.*)', text)
        details['Genre'] = genre_match.group(1).strip() if genre_match else "Genre not found"
    
    # Extract Story
    story_match = re.search(r'Story:\s*(.*?)\nMoral:', text, re.DOTALL)
    details['Story'] = story_match.group(1).strip() if story_match else "Story not found"
    
    # Extract Moral
    moral_match = re.search(r'Moral:\s*(.*)', text)
    details['Moral'] = moral_match.group(1).strip() if moral_match else "Moral not found"
    
    return details

def save_to_json(details, filename, append=False):
    # If append, load existing data
    if append and os.path.exists(filename):
        with open(filename, 'r', encoding='utf-8') as jsonfile:
            data = json.load(jsonfile)
    else:
        data = []

    # Append new story details
    data.append(details)

    # Save to JSON
    with open(filename, 'w', encoding='utf-8') as jsonfile:
        json.dump(data, jsonfile, ensure_ascii=False, indent=4)

def process_stories(text, filename, append=False, theme="", genre=""):
    cleaned_text = clean_text(text)  # Clean the text first
    stories = cleaned_text.split('Title:')[1:]  # Split text into individual stories based on the "Title:" keyword
    for story in stories:
        details = extract_story_details("Title:" + story, theme=theme, genre=genre)
        save_to_json(details, filename, append=append)
        append = True  # Ensure subsequent stories are appended to the JSON file
