import scrapy
import random
import re
import logging
import json
import sys
import argparse
from urllib.parse import quote, urljoin
from scrapy.exceptions import DropItem


# 数据结构
class BaiduSearchItem(scrapy.Item):
    title = scrapy.Field()
    url = scrapy.Field()
    abstract = scrapy.Field()


# 数据处理管道
class BaiduSearchPipeline:
    ABSTRACT_MAX_LENGTH = 100
    seen_urls = set()

    def __init__(self):
        self.logger = logging.getLogger(__name__)

    def clean_text(self, text):
        """清理文本，去除多余空格和特殊字符"""
        text = text.encode('gbk', errors='replace').decode('gbk', errors='replace')
        return re.sub(r'[\ue62b\s]+$', '', text.strip())

    def process_item(self, item, spider):
        """处理爬取结果"""
        item['title'] = self.clean_text(item['title'])
        item['abstract'] = self.clean_text(item['abstract'])

        if item['abstract'].startswith(item['title']):
            item['abstract'] = item['abstract'][len(item['title']):].strip()

        if len(item['abstract']) > self.ABSTRACT_MAX_LENGTH:
            item['abstract'] = item['abstract'][:self.ABSTRACT_MAX_LENGTH].rsplit(' ', 1)[0] + "..."

        if item['url'] in self.seen_urls:
            raise DropItem(f"Duplicate URL found: {item['url']}")
        self.seen_urls.add(item['url'])

        if spider.debug:
            self.logger.info(f"Title: {item['title'].encode('gbk', errors='replace').decode('gbk')}")
            self.logger.info(f"URL: {item['url']}")
            self.logger.info(f"Abstract: {item['abstract'].encode('gbk', errors='replace').decode('gbk')}")

        # 存储到 spider.results
        spider.results.append(dict(item))
        return item


# 爬虫逻辑
class BaiduSpider(scrapy.Spider):
    name = 'baidu'
    allowed_domains = ['baidu.com']
    baidu_host_url = "http://www.baidu.com"
    baidu_search_url = "http://www.baidu.com/s?ie=gbk&tn=baidu&wd="

    custom_settings = {
        'BOT_NAME': 'baidu_scraper',
        'USER_AGENT_LIST': [
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:89.0) Gecko/20100101 Firefox/89.0',
            'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Safari/605.1.15',
        ],
        'ROBOTSTXT_OBEY': False,
        'DOWNLOAD_DELAY': 3,
        'RANDOMIZE_DOWNLOAD_DELAY': True,
        'DEFAULT_REQUEST_HEADERS': {
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
            "Content-Type": "application/x-www-form-urlencoded",
            "Referer": "http://www.baidu.com/",
            "Accept-Encoding": "gzip, deflate",
            "Accept-Language": "zh-CN,zh;q=0.9,en;q=0.8",
            "Connection": "keep-alive",
        },
        'ITEM_PIPELINES': {
            '__main__.BaiduSearchPipeline': 300,
        },
        'LOG_LEVEL': 'DEBUG',
        'LOG_ENCODING': 'gbk',
        'FEED_EXPORT_ENCODING': 'gbk',
        'DOWNLOADER_MIDDLEWARES': {
            'scrapy.downloadermiddlewares.httpcompression.HttpCompressionMiddleware': None,
        }
    }

    def __init__(self, query='今天的热点新闻', num_results=10, debug=0, *args, **kwargs):
        super(BaiduSpider, self).__init__(*args, **kwargs)
        self.query = query.encode('gbk', errors='replace').decode('gbk')
        self.num_results = int(num_results)
        self.debug = int(debug)
        self.results = []  # 初始化 results 列表

    def start_requests(self):
        if self.debug:
            self.logger.info(
                f"Searching for: {self.query.encode('gbk', errors='replace').decode('gbk')}, num_results: {self.num_results}")
            self.logger.info(f"Visiting Baidu homepage to establish session")
        yield scrapy.Request(
            url=self.baidu_host_url,
            callback=self.parse_homepage,
            errback=self.handle_error,
            meta={'dont_redirect': True}
        )

    def parse_homepage(self, response):
        if self.debug:
            self.logger.info(f"Homepage response status: {response.status}")
            self.logger.info(f"Initial Cookies: {response.headers.getlist('Set-Cookie')}")

        pages = (self.num_results + 9) // 10
        for page in range(pages):
            params = {"wd": self.query, "pn": page * 10, "rn": 10}
            url = self.baidu_search_url + quote(self.query.encode('gbk')) + "&" + "&".join(
                f"{k}={quote(str(v).encode('gbk'))}" for k, v in params.items() if k != "wd")
            if self.debug:
                self.logger.info(f"Requesting URL: {url}")
            yield scrapy.Request(
                url=url,
                callback=self.parse_search,
                errback=self.handle_error,
                meta={'page': page, 'dont_redirect': True}
            )

    def parse_search(self, response):
        page = response.meta['page']
        response._set_body(response.body.decode('gbk', errors='replace').encode('gbk'))
        if self.debug:
            self.logger.info(f"Search page {page} response status: {response.status}, length: {len(response.text)}")
            self.logger.info(f"Response snippet: {response.text[:500].encode('gbk', errors='replace').decode('gbk')}")

        result_containers = response.css("div.c-container.result")
        if self.debug:
            self.logger.info(f"Found {len(result_containers)} result containers on page {page}")

        for container in result_containers:
            if len(self.results) >= self.num_results:
                return

            title_tag = container.css("h3 a::text").get()
            if title_tag:
                title = title_tag.strip()
                baidu_url = container.css("h3 a::attr(href)").get(default="无URL")
                baidu_url = urljoin(self.baidu_host_url, baidu_url)
                yield scrapy.Request(
                    url=baidu_url,
                    callback=self.parse_redirect,
                    errback=self.handle_error,
                    meta={
                        'title': title,
                        'abstract': container.css("div.c-abstract::text, div::text").get(default="").strip(),
                        'dont_redirect': False
                    }
                )

    def parse_redirect(self, response):
        if len(self.results) >= self.num_results:
            return

        item = BaiduSearchItem()
        item['title'] = response.meta['title'].encode('gbk', errors='replace').decode('gbk')
        item['url'] = response.url
        item['abstract'] = response.meta['abstract'].encode('gbk', errors='replace').decode('gbk')

        if self.debug:
            self.logger.info(f"Fetched result: {item['title'].encode('gbk', errors='replace').decode('gbk')}")
        yield item

    def handle_error(self, failure):
        if self.debug:
            self.logger.error(f"Request failed: {str(failure).encode('gbk', errors='replace').decode('gbk')}")


# 主函数（仅用于调试）
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Baidu Scrapy Spider")
    parser.add_argument("-q", "--query", default="交通违法处罚条款", help="Search query")
    parser.add_argument("-n", "--num-results", type=int, default=5, help="Number of results")
    parser.add_argument("-d", "--debug", type=int, default=0, help="Debug mode (0 or 1)")
    args = parser.parse_args()

    from scrapy.crawler import CrawlerProcess
    from scrapy.utils.project import get_project_settings

    settings = get_project_settings()
    settings.update(BaiduSpider.custom_settings)
    process = CrawlerProcess(settings)
    process.crawl(BaiduSpider, query=args.query, num_results=args.num_results, debug=args.debug)
    process.start()
