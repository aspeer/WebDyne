import os, re

def rewrite_md(markdown, page, config, files):
    # Only run when MKDOCS_ENV=deploy (or when on GitHub Actions)
    #if not (os.getenv("MKDOCS_ENV") == "deploy" or os.getenv("GITHUB_ACTIONS") == "true"):
    #    return markdown

    # Example rewrite(s)
    markdown = re.sub(r'\(https?://demo.webdyne.org/example(/[^)]*)\)',
                      r'(http://192.168.0.1:5000\1)', markdown)
    base = (config.get("site_url") or "").rstrip("/")
    markdown = markdown.replace("{{CDN}}", f"{base}/assets")
    return markdown
