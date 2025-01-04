WEBSITES = {
    'websiteA': {
        'base_url': 'https://www.nahi-bataunga-dhoondte-raho-lol.com/stories',
        'headers': {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3'},
        'delay': 1,
        'article_list_selector': 'div.article-list',
        'article_link_selector': 'a.article-link',
        'article_title_selector': 'h1.article-title',
        'article_content_selector': 'div.article-content',
        'exclude_selectors': ['div.ad-section', 'aside.sidebar'],
        'pagination_selector': 'a.next-page',
    },
    'websiteB': {
        'base_url': 'https://www.nahi-bataunga-dhoondte-raho-lol.com/articles',
        'headers': {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3'},
        'delay': 1,
        'article_list_selector': 'ul.articles',
        'article_link_selector': 'h2.title a',
        'article_title_selector': 'h1.title',
        'article_content_selector': 'section.content',
        'exclude_selectors': ['div.ads', 'nav.pagination'],
        'pagination_selector': 'a.next',
    },
}