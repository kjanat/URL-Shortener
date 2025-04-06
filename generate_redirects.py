import os, json

try:
    with open("redirects.json", "r") as f:
        redirects = json.load(f)
except json.JSONDecodeError as e:
    print(f"Error decoding JSON: {e}")
    print("Please check the format of redirects.json")
    raise

os.makedirs("docs", exist_ok=True)

template = """<!DOCTYPE html>
<html>
  <head>
    <meta http-equiv="refresh" content="0; URL='{}'" />
    <title>Redirecting...</title>
  </head>
  <body>
    <p>Redirecting to {}...</p>
  </body>
</html>
"""

# Generate individual redirect pages
for slug, url in redirects.items():
    with open(f"docs/{slug}.html", "w") as f:
        f.write(template.format(url, url))

# Generate index.html with an overview of all available redirects
with open("docs/index.html", "w") as index:
    index.write("<!DOCTYPE html>\n<html>\n  <head><title>Short Links</title></head>\n  <body>\n    <h1>Short Links</h1>\n    <ul>\n")
    for slug in redirects:
        index.write(f'      <li><a href="{slug}.html">{slug}</a></li>\n')
    index.write("    </ul>\n  </body>\n</html>")
