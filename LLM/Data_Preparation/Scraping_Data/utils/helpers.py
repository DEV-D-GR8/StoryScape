import re
from bs4 import BeautifulSoup

def clean_text(text):
    """
    Cleans the input text by stripping extra whitespace and replacing newline characters.
    """
    text = text.strip()
    text = text.replace('\n', ' ')
    text = re.sub(r'\s+', ' ', text)
    return text

def remove_html_tags(text):
    """
    Removes HTML tags from the input text.
    """
    soup = BeautifulSoup(text, 'html.parser')
    text = soup.get_text()
    return text