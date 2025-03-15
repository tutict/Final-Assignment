import requests
from bs4 import BeautifulSoup
from urllib.parse import quote, urljoin
import time
import random
import gzip
from io import BytesIO, TextIOWrapper
import sys
import os
import re

# 设置 UTF-8 编码
if 'graalpy' in sys.executable.lower() and sys.platform.startswith("win"):
    sys.stdout = TextIOWrapper(sys.stdout.buffer, encoding='utf-8', line_buffering=True)
    sys.stderr = TextIOWrapper(sys.stderr.buffer, encoding='utf-8', line_buffering=True)
    os.environ["PYTHONIOENCODING"] = "utf-8"
    os.environ["PYTHONLEGACYWINDOWSSTDIO"] = "1"

# 用户代理列表
user_agents = [
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/68.0.3440.106 Safari/537.36',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:89.0) Gecko/20100101 Firefox/89.0',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Safari/605.1.15',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Edge/91.0.864.59'
]

# 请求头信息
HEADERS = {
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8",
    "Content-Type": "application/x-www-form-urlencoded",
    "User-Agent": random.choice(user_agents),
    "Referer": "http://www.baidu.com/",
    "Accept-Encoding": "gzip, deflate",
    "Accept-Language": "zh-CN,zh;q=0.9,en;q=0.8",
    "Connection": "keep-alive",
    "Upgrade-Insecure-Requests": "1",
    "Cache-Control": "max-age=0"
}

baidu_host_url = "http://www.baidu.com"
baidu_search_url = "http://www.baidu.com/s?ie=utf-8&tn=baidu&wd="

ABSTRACT_MAX_LENGTH = 100

session = requests.Session()
session.headers.update(HEADERS)


def resolve_baidu_url(baidu_url):
    if "link?url=" not in baidu_url:
        return baidu_url
    try:
        response = session.get(baidu_url, timeout=5, allow_redirects=True)
        return response.url
    except requests.RequestException:
        return baidu_url


def clean_text(text):
    return re.sub(r'[\ue62b\s]+$', '', text.strip())


def print_no_empty(*args, **kwargs):
    message = " ".join(str(arg) for arg in args)
    if message.strip():
        try:
            print(message.encode('utf-8', errors='replace').decode('utf-8'), **kwargs)
        except UnicodeEncodeError:
            print(message.encode('utf-8', errors='replace').decode('utf-8'), **kwargs)


def search(query, num_results=10, debug=0):
    results = []
    results_fetched = 0
    pages = (num_results + 9) // 10
    seen_urls = set()

    if debug:
        print_no_empty(f"Searching for: {query}, num_results: {num_results}")
        print_no_empty(f"Using User-Agent: {session.headers['User-Agent']}")

    try:
        session.get(baidu_host_url, timeout=10, verify=False)
        if debug:
            print_no_empty("Visited Baidu homepage to establish session")
            print_no_empty(f"Initial Cookies: {session.cookies.get_dict()}")
    except requests.RequestException as e:
        if debug:
            print_no_empty(f"Failed to visit homepage: {e}")

    for page in range(pages):
        if results_fetched >= num_results:
            break

        params = {"wd": query, "pn": page * 10, "rn": 10}
        url = baidu_search_url + quote(query.encode('utf-8')) + "&" + "&".join(
            f"{k}={quote(str(v))}" for k, v in params.items() if k != "wd")

        if debug:
            print_no_empty(f"Requesting URL: {url}")

        try:
            time.sleep(random.uniform(3, 5))
            response = session.get(url, timeout=10, proxies={"http": None, "https": None}, verify=False,
                                   allow_redirects=True)
            response.raise_for_status()

            content = response.content
            encoding = response.headers.get('Content-Encoding', 'none')
            if encoding == 'gzip':
                try:
                    content = gzip.decompress(content)
                except gzip.BadGzipFile:
                    if debug:
                        print_no_empty("Warning: Invalid gzip data, treating as uncompressed")

            text = content.decode('utf-8', errors='replace')

            if debug:
                print_no_empty(f"Response status: {response.status_code}, length: {len(text)}")
                print_no_empty(f"Content-Encoding: {encoding}")
                print_no_empty(f"Response snippet: {text[:500]}")

            soup = BeautifulSoup(text, "html.parser")
            result_containers = soup.select("div.c-container.result")

            if debug:
                print_no_empty(f"Found {len(result_containers)} result containers on page {page}")

            for container in result_containers:
                if results_fetched >= num_results:
                    break
                title_tag = container.select_one("h3 a")
                if title_tag:
                    title = clean_text(title_tag.get_text(strip=True))
                    baidu_url = urljoin(baidu_host_url, title_tag.get("href", "无URL"))
                    url = resolve_baidu_url(baidu_url)
                    abstract_tag = container.select_one("div.c-abstract") or container.select_one("div")
                    abstract = clean_text(abstract_tag.get_text(strip=True)) if abstract_tag else ""
                    if abstract.startswith(title):
                        abstract = abstract[len(title):].strip()
                    if len(abstract) > ABSTRACT_MAX_LENGTH:
                        abstract = abstract[:ABSTRACT_MAX_LENGTH].rsplit(' ', 1)[0] + "..."

                    if url not in seen_urls:
                        seen_urls.add(url)
                        if debug:
                            print_no_empty(f"Title: {title}, URL: {url}")
                            print_no_empty(f"Abstract: {abstract}")
                        results.append({"title": title, "url": url, "abstract": abstract})
                        results_fetched += 1

        except requests.RequestException as e:
            if debug:
                print_no_empty(f"请求错误: {e}")
            break

    if debug:
        print_no_empty(f"Total results fetched: {len(results)}")

    if results:
        print_no_empty(f"Search results (total {len(results)} items):")
        for i, res in enumerate(results, 1):
            print_no_empty(f"{i}. {res['title']}")
            print_no_empty(f"   {res['abstract']}")
            print_no_empty(f"   {res['url']}")
    else:
        print_no_empty("No results found.")

    return results


if __name__ == "__main__":
    query = "今天的热点新闻"
    results = search(query, 5, debug=1)
    print(results)
