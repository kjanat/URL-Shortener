import os, json

with open("redirects.json", "r") as f:
    redirects = json.load(f)

os.makedirs("docs/goto", exist_ok=True)

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

for slug, url in redirects.items():
    with open(f"docs/goto/{slug}.html", "w") as f:
        f.write(template.format(url, url))

with open("docs/index.html", "w") as index:
    index.write("<!DOCTYPE html>\n<html>\n  <head><title>Short Links</title></head>\n  <body>\n    <h1>Short Links</h1>\n    <ul>\n")
    for slug in redirects:
        index.write(f'      <li><a href=\"goto/{slug}.html\">{slug}</a></li>\n')
    index.write("    </ul>\n  </body>\n</html>")
