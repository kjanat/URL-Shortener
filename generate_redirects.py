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

# Ensure public directory is clean
if os.path.exists("public"):
    for file in os.listdir("public"):
        os.remove(os.path.join("public", file))
else:
    os.makedirs("public")

# Update the style variable
style = """
body {
  font-family: 'Roboto', sans-serif;
  margin: 0;
  padding: 0;
  background-color: #f4f4f9;
  color: #333;
}
h1, h2 {
  color: #444;
}
a {
  color: #007BFF;
  text-decoration: none;
}
a:hover {
  text-decoration: underline;
}
ul {
  list-style-type: none;
  padding: 0;
}
li {
  margin: 0.5em 0;
}
.container {
  max-width: 800px;
  margin: 2em auto;
  padding: 1em;
  background: #fff;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}
"""

# Update the template to use the escaped style
template = """<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="refresh" content="0; URL='{}'" />
        <title>Redirecting...</title>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <link href='https://fonts.googleapis.com/css2?family=Roboto:wght@400;700&display=swap' rel='stylesheet'>
        <style>{}</style>
    </head>
    <body>
        <div class='container'>
            <p>Redirecting to {}...</p>
        </div>
    </body>
</html>
"""

# Generate individual redirect pages
for slug, data in redirects.items():
    url = data["url"] if isinstance(data, dict) else data
    with open(f"public/{slug}.html", "w") as f:
        f.write(template.format(url, style, url))

# Generate the index.html file with the updated style
with open("public/index.html", "w") as index:
    index.write("""<!DOCTYPE html>
<html>
  <head>
    <title>Redirect links</title>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link href='https://fonts.googleapis.com/css2?family=Roboto:wght@400;700&display=swap' rel='stylesheet'>
    <style>{}</style>
  </head>
  <body>
    <div class='container'>
      <h1>KJANAT URL Shortener</h1>
""".format(style))

    # Group redirects by category
    categorized_redirects = {}
    for slug, data in redirects.items():
        category = data.get("category", "") if isinstance(data, dict) else "Uncategorized"
        if category not in categorized_redirects:
            categorized_redirects[category] = []
        categorized_redirects[category].append((slug, data))

    # Write categories and their links
    for category, items in sorted(categorized_redirects.items()):
        index.write(f"<h2>{category}</h2><ul>")
        for slug, data in sorted(items):
            url = data["url"] if isinstance(data, dict) else data
            description = data.get("description", "") if isinstance(data, dict) else ""
            if description:
                index.write(f'<li><a href="{slug}.html">{slug}</a>: {description}</li>')
            else:
                index.write(f'<li><a href="{slug}.html">{slug}</a></li>')
        index.write("</ul>")

    index.write("</div></body></html>")
