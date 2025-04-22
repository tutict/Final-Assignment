import requests
import random
import time
import gzip
import re
import sys
import os
from io import TextIOWrapper
from urllib.parse import quote, urljoin

# Suppress SSL warnings
import warnings
from urllib3.exceptions import InsecureRequestWarning
warnings.simplefilter('ignore', InsecureRequestWarning)

# Use GBK for query encoding, UTF-8 for response decoding and output
_QUERY_ENCODING = "gbk"
_RESPONSE_ENCODING = "utf-8"

# Configure standard input/output for UTF-8
if sys.platform.startswith("win"):
    sys.stdout = TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace", line_buffering=True)
    sys.stderr = TextIOWrapper(sys.stderr.buffer, encoding="utf-8", errors="replace", line_buffering=True)
else:
    os.environ["PYTHONIOENCODING"] = "utf-8"

# Attempt to import lxml, fall back to BeautifulSoup
try:
    from lxml import html
    _USE_LXML = True
except ImportError:
    from bs4 import BeautifulSoup
    _USE_LXML = False

# Constants
BAIDU_HOME = "http://www.baidu.com"
SEARCH_URL = "http://www.baidu.com/s?ie=gbk&tn=baidu&wd="
RESULT_COUNT = 15
ABSTRACT_LEN = 200
HEADERS_LIST = [
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:89.0) Gecko/20100101 Firefox/89.0',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Safari/605.1.15',
]

def _decode(content: bytes) -> str:
    return content.decode(_RESPONSE_ENCODING, errors="replace")

def _clean(text: str) -> str:
    return re.sub(r'[\ue62b\s]+$', '', text.strip())

def _resolve_url(u: str, sess: requests.Session) -> str:
    if "link?url=" not in u:
        return u
    try:
        return sess.get(u, timeout=5, allow_redirects=True).url
    except:
        return u

def search(query: str, num_results: int = RESULT_COUNT, debug: bool = False):
    sess = requests.Session()
    sess.headers.update({
        "User-Agent": random.choice(HEADERS_LIST),
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
        "Accept-Encoding": "gzip, deflate",
        "Connection": "keep-alive",
    })

    results = []
    seen = set()
    pages = (num_results + 9) // 10

    if debug:
        print(f"[DEBUG] use_lxml={_USE_LXML}, query={query!r}, want={num_results}")

    try:
        sess.get(BAIDU_HOME, timeout=10, verify=False)
    except:
        pass

    for page in range(pages):
        if len(results) >= num_results:
            break

        pn = page * 10
        url = f"{SEARCH_URL}{quote(query.encode(_QUERY_ENCODING))}&pn={pn}&rn=10"
        if debug:
            print(f"[DEBUG] fetching page {pn}")

        try:
            time.sleep(random.uniform(0.5, 1.0))
            resp = sess.get(url, timeout=15, verify=False)
            resp.raise_for_status()
            content = resp.content
            if resp.headers.get("Content-Encoding") == "gzip":
                try:
                    content = gzip.decompress(content)
                except:
                    pass
            text = _decode(content)
            if debug:
                with open(f"page_{pn}.html", "w", encoding="utf-8") as f:
                    f.write(text)
        except Exception as e:
            if debug:
                print(f"[DEBUG] request failed: {e}")
            break

        if _USE_LXML:
            doc = html.fromstring(text)
            containers = doc.xpath('//div[contains(@class,"c-container") or contains(@class,"result")]')
        else:
            soup = BeautifulSoup(text, "html.parser")
            containers = soup.select("div.c-container, div.result")

        for cont in containers:
            if len(results) >= num_results:
                break

            # Extract title
            if _USE_LXML:
                title_nodes = cont.xpath('.//h3//a | .//a[@class="c-title-text"] | .//a[contains(@class,"title")]')
            else:
                title_nodes = cont.select("h3 a, a.c-title-text, a.title")
            if not title_nodes:
                continue
            raw_title = title_nodes[0].text_content() if _USE_LXML else title_nodes[0].get_text()
            title = _clean(raw_title)
            if debug:
                print(f"[DEBUG] raw title: {repr(raw_title)}")

            # Extract abstract
            summary = ""
            if _USE_LXML:
                abs_nodes = cont.xpath(
                    './/div[contains(@class,"c-abstract")] | '
                    './/span[contains(@class,"content-abstract")] | '
                    './/div[contains(@class,"c-row")]//span | '
                    './/div[@class="c-span-last"] | '
                    './/div[contains(@class,"content-right")] | '
                    './/p[contains(@class,"content")]'
                )
                for node in abs_nodes:
                    raw_abs = node.text_content()
                    if raw_abs.strip():
                        summary = _clean(raw_abs)
                        if debug:
                            print(f"[DEBUG] raw abstract: {repr(raw_abs)}")
                        break
            else:
                abs_nodes = cont.select(
                    "div.c-abstract, span.content-abstract, div.c-row span, "
                    "div.c-span-last, div.content-right, p.content"
                )
                for node in abs_nodes:
                    raw_abs = node.get_text()
                    if raw_abs.strip():
                        summary = _clean(raw_abs)
                        if debug:
                            print(f"[DEBUG] raw abstract: {repr(raw_abs)}")
                        break

            # Fallback: use snippet text if no abstract found
            if not summary and _USE_LXML:
                snippet_nodes = cont.xpath('.//div[contains(@class,"c-snippet")]//text()')
                if snippet_nodes:
                    summary = _clean(" ".join(snippet_nodes).strip())
                    if debug:
                        print(f"[DEBUG] fallback snippet: {repr(summary)}")
            elif not summary:
                snippet_nodes = cont.select("div.c-snippet")
                if snippet_nodes:
                    summary = _clean(snippet_nodes[0].get_text().strip())
                    if debug:
                        print(f"[DEBUG] fallback snippet: {repr(summary)}")

            if summary.startswith(title):
                summary = summary[len(title):].strip()
            if len(summary) > ABSTRACT_LEN:
                summary = summary[:ABSTRACT_LEN].rsplit(" ", 1)[0] + "……"

            if title in seen:
                continue
            seen.add(title)

            results.append({
                "title": title,
                "abstract": summary
            })
            if debug:
                idx = len(results)
                print(f"[{idx:02d}] {title}")
                print(f"     {summary}")

    if debug:
        print(f"[DEBUG] total fetched: {len(results)}")
    return results

if __name__ == "__main__":
    out = search("如何查询我的交通违法记录？", debug=True)
    for idx, item in enumerate(out, 1):
        print(f"{idx:02d}. {item['title']}")
        print(f"    {item['abstract']}")