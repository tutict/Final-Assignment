import gzip
import os
import random
import re
import sys
import time
import warnings
from html import unescape as html_unescape
from io import TextIOWrapper
from urllib.parse import quote, urljoin, urlparse

import requests
from urllib3.exceptions import InsecureRequestWarning

warnings.simplefilter("ignore", InsecureRequestWarning)

# Baidu normally returns UTF-8 for modern search pages. Some fallback or
# anti-bot pages still use GB-family encodings, so _decode keeps gb18030.
_QUERY_ENCODING = "utf-8"
_RESPONSE_ENCODING = "utf-8"

if sys.platform.startswith("win"):
    sys.stdout = TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace", line_buffering=True)
    sys.stderr = TextIOWrapper(sys.stderr.buffer, encoding="utf-8", errors="replace", line_buffering=True)
else:
    os.environ["PYTHONIOENCODING"] = "utf-8"

try:
    from lxml import html as lxml_html
    _USE_LXML = True
except ImportError:
    from bs4 import BeautifulSoup
    _USE_LXML = False

BAIDU_HOME = "https://www.baidu.com"
SEARCH_URL = "https://www.baidu.com/s?ie=utf-8&tn=baidu&wd="
RESULT_COUNT = 15
ABSTRACT_LEN = 220
REQUEST_TIMEOUT = (4, 12)
REDIRECT_TIMEOUT = (3, 8)
RETRIES = 2
MAX_PAGES = 3

HEADERS_LIST = [
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/124.0 Safari/537.36",
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:125.0) Gecko/20100101 Firefox/125.0",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_4) AppleWebKit/605.1.15 "
    "(KHTML, like Gecko) Version/17.4 Safari/605.1.15",
]

_CLEAN_RE = re.compile(r"[\u200b\u200e\u200f\ufeff\ue62b]+")
_PUNCT_RE = re.compile(r"[\s\-_./\\|,:;!?()\[\]{}<>\"'`~@#$%^&*+=，。！？；：、（）【】《》]+")
_AD_MARKER_RE = re.compile(
    r"(tuiguang|ec[-_]?ad|ad[_-]?icon|cpro|ecom[_-]?ad|data-tuiguang|data-landurl|"
    r"aria-label=[\"']?\u5e7f\u544a)",
    re.IGNORECASE,
)
_AD_LABEL_RE = re.compile(
    r"(^|\s)(\u5e7f\u544a|\u63a8\u5e7f|\u5546\u4e1a\u63a8\u5e7f|\u8d5e\u52a9|"
    r"\u63a8\u5e7f\u94fe\u63a5)(\s|$)"
)
_BLOCKED_DOMAINS = (
    "cpro.baidu.com",
    "e.baidu.com",
    "union.baidu.com",
    "pos.baidu.com",
    "wangmeng.baidu.com",
    "baiduads.com",
)
_LOW_VALUE_DOMAINS = (
    "zhidao.baidu.com",
    "jingyan.baidu.com",
    "wenku.baidu.com",
)
_AUTHORITY_DOMAIN_SUFFIXES = (
    ".gov.cn",
    ".edu.cn",
)
_AUTHORITY_DOMAINS = (
    "mps.gov.cn",
    "122.gov.cn",
    "gab.122.gov.cn",
    "beian.gov.cn",
    "court.gov.cn",
    "xinhuanet.com",
    "people.com.cn",
)
_TRAFFIC_TERMS = (
    "\u4ea4\u901a",
    "\u4ea4\u7ba1",
    "\u8fdd\u6cd5",
    "\u8fdd\u7ae0",
    "\u9a7e\u9a76\u8bc1",
    "\u884c\u9a76\u8bc1",
    "\u9a7e\u9a76\u5458",
    "\u8f66\u8f86",
    "\u7f5a\u6b3e",
    "\u6263\u5206",
    "\u7533\u8bc9",
    "\u4e8b\u6545",
    "12123",
)


def _decode(content: bytes, encoding_hint: str = None) -> str:
    if not content:
        return ""

    encodings = []
    if encoding_hint and encoding_hint.lower() not in ("iso-8859-1", "latin-1", "ascii"):
        encodings.append(encoding_hint)
    encodings.extend([_RESPONSE_ENCODING, "gb18030"])

    best = ""
    best_bad_chars = None
    for encoding in encodings:
        try:
            decoded = content.decode(encoding, errors="replace")
        except LookupError:
            continue
        bad_chars = decoded.count("\ufffd")
        if best_bad_chars is None or bad_chars < best_bad_chars:
            best = decoded
            best_bad_chars = bad_chars
        if decoded and bad_chars / max(len(decoded), 1) < 0.005:
            return decoded
    return best


def _clean(text: str) -> str:
    if not text:
        return ""
    text = html_unescape(text)
    text = _CLEAN_RE.sub("", text)
    text = text.replace("\xa0", " ")
    text = re.sub(r"\s+", " ", text)
    return text.strip()


def _clean_title(text: str) -> str:
    text = _clean(text)
    text = re.sub(r"^\s*(\u5e7f\u544a|\u63a8\u5e7f|\u5546\u4e1a\u63a8\u5e7f)\s*[:：-]?\s*", "", text)
    text = re.sub(r"\s*[-_]\s*\u767e\u5ea6\u5feb\u7167\s*$", "", text)
    return text.strip()


def _clip_summary(summary: str) -> str:
    summary = _clean(summary)
    if len(summary) <= ABSTRACT_LEN:
        return summary
    clipped = summary[:ABSTRACT_LEN]
    if " " in clipped:
        clipped = clipped.rsplit(" ", 1)[0]
    return clipped.rstrip("，。；,.; ") + "..."


def _text_of(node) -> str:
    if _USE_LXML:
        return node.text_content()
    return node.get_text(" ", strip=False)


def _html_of(node) -> str:
    if _USE_LXML:
        try:
            return lxml_html.tostring(node, encoding="unicode")
        except Exception:
            return ""
    return str(node)


def _attr(node, name: str) -> str:
    if _USE_LXML:
        value = node.get(name)
    else:
        value = node.attrs.get(name)
        if isinstance(value, list):
            value = " ".join(value)
    return value or ""


def _container_attrs(node) -> str:
    keys = ("id", "class", "tpl", "mu", "srcid", "data-click", "data-tuiguang", "data-landurl")
    return " ".join(_attr(node, key) for key in keys)


def _domain(url: str) -> str:
    try:
        return urlparse(url).netloc.lower().split("@")[-1].split(":")[0]
    except Exception:
        return ""


def _normalize_url(url: str) -> str:
    parsed = urlparse(url)
    path = parsed.path.rstrip("/") or "/"
    return f"{parsed.scheme}://{parsed.netloc.lower()}{path}"


def _blocked_url(url: str) -> bool:
    domain = _domain(url)
    return any(domain == blocked or domain.endswith("." + blocked) for blocked in _BLOCKED_DOMAINS)


def _is_ad_container(node, title: str, summary: str) -> bool:
    attrs = _container_attrs(node)
    html = _html_of(node)[:2500]
    text = _clean(_text_of(node)[:300])
    combined = f"{attrs} {html}"

    if _AD_MARKER_RE.search(combined):
        return True
    if _AD_LABEL_RE.search(text):
        return True
    if title in ("\u5e7f\u544a", "\u63a8\u5e7f", "\u5546\u4e1a\u63a8\u5e7f"):
        return True
    return summary.startswith(("\u5e7f\u544a", "\u63a8\u5e7f", "\u5546\u4e1a\u63a8\u5e7f"))


def _resolve_url(url: str, sess: requests.Session) -> str:
    if not url:
        return ""
    url = urljoin(BAIDU_HOME, url)
    if "baidu.com/link?url=" not in url and "www.baidu.com/link?url=" not in url:
        return url
    try:
        resp = sess.get(url, timeout=REDIRECT_TIMEOUT, allow_redirects=True, verify=False)
        return resp.url or url
    except Exception:
        return url


def _request_with_retry(sess: requests.Session, url: str):
    last_exc = None
    for attempt in range(RETRIES + 1):
        try:
            resp = sess.get(url, timeout=REQUEST_TIMEOUT, verify=False)
            resp.raise_for_status()
            return resp
        except Exception as exc:
            last_exc = exc
            time.sleep(0.5 + attempt * 0.5)
    raise last_exc


def _query_terms(query: str):
    cleaned = _clean(query).lower()
    latin_terms = re.findall(r"[a-z0-9]{2,}", cleaned)
    terms = set(latin_terms)

    for term in _TRAFFIC_TERMS:
        if term in cleaned:
            terms.add(term)

    compact = _PUNCT_RE.sub("", cleaned)
    cjk_chars = re.findall(r"[\u4e00-\u9fff]", compact)
    for idx in range(len(cjk_chars) - 1):
        terms.add("".join(cjk_chars[idx:idx + 2]))

    return {term for term in terms if len(term) >= 2}


def _is_authority_domain(domain: str) -> bool:
    if not domain:
        return False
    if any(domain == item or domain.endswith("." + item) for item in _AUTHORITY_DOMAINS):
        return True
    return any(domain.endswith(suffix) for suffix in _AUTHORITY_DOMAIN_SUFFIXES)


def _score_result(query: str, terms, title: str, summary: str, url: str, rank: int) -> float:
    title_l = title.lower()
    summary_l = summary.lower()
    haystack = f"{title_l} {summary_l}"
    compact_query = _PUNCT_RE.sub("", _clean(query).lower())
    compact_haystack = _PUNCT_RE.sub("", haystack)

    score = max(0.0, 3.0 - rank * 0.08)
    if compact_query and compact_query in compact_haystack:
        score += 8.0

    for term in terms:
        if term in title_l:
            score += 3.2
        elif term in summary_l:
            score += 1.1

    if terms:
        matched = sum(1 for term in terms if term in haystack)
        score += 4.0 * matched / len(terms)

    domain = _domain(url)
    if _is_authority_domain(domain):
        score += 3.0
    if any(domain == item or domain.endswith("." + item) for item in _LOW_VALUE_DOMAINS):
        score -= 2.5
    if _blocked_url(url):
        score -= 20.0
    return score


def _fingerprint(title: str, url: str) -> str:
    domain = _domain(url)
    title_key = _PUNCT_RE.sub("", title.lower())[:80]
    url_key = _normalize_url(url) if url else ""
    return f"{domain}|{title_key}|{url_key}"


def _extract_title_and_url(container):
    if _USE_LXML:
        nodes = container.xpath(
            './/h3//a | .//a[contains(@class,"c-title-text")] | .//a[contains(@class,"title")]'
        )
    else:
        nodes = container.select("h3 a, a.c-title-text, a.title")
    if not nodes:
        return "", ""

    node = nodes[0]
    return _clean_title(_text_of(node)), _attr(node, "href")


def _extract_summary(container, title: str):
    if _USE_LXML:
        nodes = container.xpath(
            './/*[contains(@class,"c-abstract")] | '
            './/*[contains(@class,"content-abstract")] | '
            './/*[contains(@class,"c-span-last")] | '
            './/*[contains(@class,"content-right")] | '
            './/*[contains(@class,"c-snippet")] | '
            './/p[contains(@class,"content")]'
        )
    else:
        nodes = container.select(
            "div.c-abstract, span.content-abstract, div.c-span-last, "
            "div.content-right, div.c-snippet, p.content"
        )

    summary = ""
    for node in nodes:
        cleaned = _clean(_text_of(node))
        if cleaned and cleaned != title:
            summary = cleaned
            break

    if not summary:
        raw_text = _clean(_text_of(container))
        if raw_text.startswith(title):
            raw_text = raw_text[len(title):].strip()
        summary = raw_text

    if summary.startswith(title):
        summary = summary[len(title):].strip()
    return _clip_summary(summary)


def _result_containers(page_text: str):
    if _USE_LXML:
        doc = lxml_html.fromstring(page_text)
        nodes = doc.xpath(
            '//div[@id="content_left"]//div[contains(concat(" ",normalize-space(@class)," ")," c-container ")] | '
            '//div[@id="content_left"]//div[contains(concat(" ",normalize-space(@class)," ")," result ")] | '
            '//div[contains(concat(" ",normalize-space(@class)," ")," c-container ")]'
        )
    else:
        soup = BeautifulSoup(page_text, "html.parser")
        nodes = soup.select("#content_left div.c-container, #content_left div.result, div.c-container")

    seen_ids = set()
    unique = []
    for node in nodes:
        node_id = id(node)
        if node_id in seen_ids:
            continue
        seen_ids.add(node_id)
        unique.append(node)
    return unique


def search(query: str, num_results: int = RESULT_COUNT, debug: bool = False):
    query = _clean(query)
    if not query:
        return []
    try:
        num_results = max(1, min(int(num_results), 30))
    except Exception:
        num_results = RESULT_COUNT

    sess = requests.Session()
    sess.headers.update({
        "User-Agent": random.choice(HEADERS_LIST),
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
        "Accept-Encoding": "gzip, deflate",
        "Accept-Language": "zh-CN,zh;q=0.9,en;q=0.7",
        "Referer": BAIDU_HOME + "/",
        "Connection": "keep-alive",
    })

    candidates = []
    seen = set()
    terms = _query_terms(query)
    candidate_target = min(max(num_results * 3, 12), 30)
    pages = min(MAX_PAGES, max(1, (candidate_target + 9) // 10))

    if debug:
        print(f"[DEBUG] use_lxml={_USE_LXML}, query={query!r}, want={num_results}, terms={sorted(terms)}")

    try:
        sess.get(BAIDU_HOME, timeout=REQUEST_TIMEOUT, verify=False)
    except Exception:
        pass

    for page in range(pages):
        if len(candidates) >= candidate_target:
            break

        pn = page * 10
        encoded_query = quote(query, encoding=_QUERY_ENCODING, errors="ignore")
        url = f"{SEARCH_URL}{encoded_query}&pn={pn}&rn=10"
        if debug:
            print(f"[DEBUG] fetching page {pn}")

        try:
            time.sleep(random.uniform(0.3, 0.8))
            resp = _request_with_retry(sess, url)
            content = resp.content
            if resp.headers.get("Content-Encoding") == "gzip":
                try:
                    content = gzip.decompress(content)
                except Exception:
                    pass
            text = _decode(content, resp.encoding)
            if not text:
                continue
            if debug:
                with open(f"page_{pn}.html", "w", encoding="utf-8") as handle:
                    handle.write(text)
        except Exception as exc:
            if debug:
                print(f"[DEBUG] request failed: {exc}")
            break

        for rank_in_page, container in enumerate(_result_containers(text)):
            if len(candidates) >= candidate_target:
                break

            title, raw_url = _extract_title_and_url(container)
            if not title:
                continue

            summary = _extract_summary(container, title)
            if _is_ad_container(container, title, summary):
                if debug:
                    print(f"[DEBUG] skipped ad: {title}")
                continue

            resolved_url = _resolve_url(raw_url, sess)
            if _blocked_url(resolved_url):
                if debug:
                    print(f"[DEBUG] skipped blocked domain: {resolved_url}")
                continue

            key = _fingerprint(title, resolved_url)
            if key in seen:
                continue
            seen.add(key)

            rank = page * 10 + rank_in_page
            score = _score_result(query, terms, title, summary, resolved_url, rank)
            candidates.append({
                "title": title,
                "abstract": summary,
                "url": resolved_url,
                "_score": score,
                "_rank": rank,
            })

            if debug:
                print(f"[{len(candidates):02d}] score={score:.2f} title={title}")
                print(f"     url={resolved_url}")
                print(f"     {summary}")

    candidates.sort(key=lambda item: (-item["_score"], item["_rank"]))
    relevant = [item for item in candidates if item["_score"] >= 1.0]
    if len(relevant) < min(num_results, 3):
        relevant = candidates

    results = []
    for item in relevant[:num_results]:
        results.append({
            "title": item["title"],
            "abstract": item["abstract"],
            "url": item["url"],
        })

    if debug:
        print(f"[DEBUG] total candidates: {len(candidates)}, returned: {len(results)}")
    return results


if __name__ == "__main__":
    out = search("\u5982\u4f55\u67e5\u8be2\u6211\u7684\u4ea4\u901a\u8fdd\u6cd5\u8bb0\u5f55\uff1f", debug=True)
    for idx, item in enumerate(out, 1):
        print(f"{idx:02d}. {item['title']}")
        print(f"    {item['abstract']}")
        print(f"    {item.get('url', '')}")
