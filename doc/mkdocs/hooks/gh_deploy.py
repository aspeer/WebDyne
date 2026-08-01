import re

def rewrite_md(markdown, page, config, files):
    markdown = re.sub(r'\(https?://demo.webdyne.org/example(/[^)]*)\)',
                      r'(https://demo.webdyne.org\1)', markdown)
    base = (config.get("site_url") or "").rstrip("/")
    markdown = markdown.replace("{{CDN}}", f"{base}/assets")
    return markdown
