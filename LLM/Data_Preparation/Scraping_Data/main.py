from config.settings import WEBSITES
from scrapers.generic_scraper import GenericScraper
from utils.logger import logger
import json

def main():
    all_stories = []
    for website_name in WEBSITES.keys():
        scraper = GenericScraper(website_name)
        scraper.scrape()
        all_stories.extend(scraper.stories)
    # Save all stories to a file
    with open('stories.json', 'w', encoding='utf-8') as f:
        json.dump(all_stories, f, ensure_ascii=False, indent=4)
    logger.info(f"Successfully collected {len(all_stories)} stories.")

if __name__ == '__main__':
    main()