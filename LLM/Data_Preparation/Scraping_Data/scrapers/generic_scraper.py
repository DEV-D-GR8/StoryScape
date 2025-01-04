import requests
from bs4 import BeautifulSoup
from urllib.parse import urljoin
import time
from utils.logger import logger

class GenericScraper:
    def __init__(self, website_name):
        from config.settings import WEBSITES
        self.config = WEBSITES.get(website_name, {})
        if not self.config:
            raise ValueError(f"No configuration found for {website_name}")
        self.base_url = self.config['base_url']
        self.headers = self.config['headers']
        self.delay = self.config['delay']
        self.article_list_selector = self.config['article_list_selector']
        self.article_link_selector = self.config['article_link_selector']
        self.article_title_selector = self.config.get('article_title_selector', '')
        self.article_content_selector = self.config['article_content_selector']
        self.exclude_selectors = self.config['exclude_selectors']
        self.pagination_selector = self.config.get('pagination_selector', '')
        self.stories = []

    def fetch_page(self, url):
        try:
            response = requests.get(url, headers=self.headers)
            response.raise_for_status()
            return BeautifulSoup(response.content, 'html.parser')
        except requests.exceptions.RequestException as e:
            logger.error(f"Error fetching {url}: {e}")
            return None

    def get_article_links(self, soup):
        article_list = soup.select_one(self.article_list_selector)
        if not article_list:
            logger.warning(f"No article list found for selector {self.article_list_selector}")
            return []
        links = article_list.select(self.article_link_selector)
        return [link['href'] for link in links if 'href' in link.attrs]

    def fetch_article_content(self, article_url):
        soup = self.fetch_page(article_url)
        if not soup:
            return None
        for selector in self.exclude_selectors:
            elements = soup.select(selector)
            for elem in elements:
                elem.decompose()
        content_elem = soup.select_one(self.article_content_selector)
        title_elem = soup.select_one(self.article_title_selector)
        if content_elem and title_elem:
            content = content_elem.get_text()
            title = title_elem.get_text()
            return {'title': title, 'content': content}
        else:
            logger.warning(f"No content or title found for {article_url}")
            return None

    def get_next_page_url(self, soup):
        next_link = soup.select_one(self.pagination_selector)
        if next_link and 'href' in next_link.attrs:
            return urljoin(self.base_url, next_link['href'])
        else:
            return None

    def scrape(self):
        current_url = self.base_url
        while current_url:
            soup = self.fetch_page(current_url)
            if not soup:
                break
            article_links = self.get_article_links(soup)
            for link in article_links:
                absolute_link = urljoin(self.base_url, link)
                content_data = self.fetch_article_content(absolute_link)
                if content_data:
                    content_data['url'] = absolute_link
                    self.stories.append(content_data)
                time.sleep(self.delay)
            current_url = self.get_next_page_url(soup)