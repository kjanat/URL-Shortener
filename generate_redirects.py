import os

# Detect and load redirects from JSON or YAML
redirects = {}
json_file = "redirects.json"
yaml_file = "redirects.yml"

if os.path.exists(json_file) and os.path.exists(yaml_file):
    import json, yaml
    json_redirects = json.load(open(json_file))
    yaml_redirects = yaml.safe_load(open(yaml_file))
    redirects = json_redirects if len(json_redirects) >= len(yaml_redirects) else yaml_redirects
elif os.path.exists(json_file):
    import json
    redirects = json.load(open(json_file))
elif os.path.exists(yaml_file):
    import yaml
    redirects = yaml.safe_load(open(yaml_file))
else:
    raise FileNotFoundError("No redirects.json or redirects.yml file found.")

# Ensure docs directory is clean
if os.path.exists("docs"):
    for file in os.listdir("docs"):
        os.remove(os.path.join("docs", file))
else:
    os.makedirs("docs")

template = """<!DOCTYPE html>
<html>
  <head>
    <meta http-equiv=\"refresh\" content=\"0; URL='{}'\" />
    <title>Redirecting...</title>
  </head>
  <body>
    <p>Redirecting to {}...</p>
  </body>
</html>
"""

# Generate individual redirect pages
for slug, data in redirects.items():
    url = data["url"] if isinstance(data, dict) else data
    with open(f"docs/{slug}.html", "w") as f:
        f.write(template.format(url, url))

# Generate index.html with an overview of all available redirects
with open("docs/index.html", "w") as index:
    index.write("<!DOCTYPE html>\n<html>\n  <head><title>Redirect links</title></head>\n  <body>\n    <h1>Short Links</h1>\n    <ul>\n")
    for slug, data in sorted(redirects.items()):  # Sort by slug
        url = data["url"] if isinstance(data, dict) else data
        description = data.get("description", "") if isinstance(data, dict) else ""
        if description:
            index.write(f'      <li><a href="{slug}.html">{slug}</a>: {description}</li>\n')
        else:
            index.write(f'      <li><a href="{slug}.html">{slug}</a></li>\n')
    index.write("    </ul>\n  </body>\n</html>")
