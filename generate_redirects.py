import os
import shutil
import json
import yaml
from datetime import datetime

# UI Variables
## Title for the index page
index_title = "KJANAT URL Shortener"
page_description = index_title
## Title header above uncategorized redirects
uncategorized_title = ""

## Footer settings
### Repo name and URL
repo_name = "URL Shortener"
repo_url = "https://github.com/kjanat/url-shortener"
### Attribution for the footer
current_year = datetime.now().year
footer_attribution = f"© {current_year} KJANAT. All rights reserved."

# Icon path for the favicon
custom_domain = "https://io.kjanat.com"
icon_path = "https://raw.githubusercontent.com/kjanat/kjanat/refs/heads/master/assets/images/KJANAT.svg"

# Meta tag for robots
robots = "noindex, nofollow"

# Redirect delay in seconds
redirect_delay = 0

# Detect and load redirects from JSON or YAML
redirects = {}
json_file = "redirects.json"
yaml_file = "redirects.yml"

if os.path.exists(json_file) and os.path.exists(yaml_file):
    json_redirects = json.load(open(json_file))
    yaml_redirects = yaml.safe_load(open(yaml_file))
    redirects = (
        json_redirects if len(json_redirects) >= len(yaml_redirects) else yaml_redirects
    )
elif os.path.exists(json_file):
    json_redirects = json.load(open(json_file))
    redirects = json_redirects
elif os.path.exists(yaml_file):
    yaml_redirects = yaml.safe_load(open(yaml_file))
    redirects = yaml_redirects
else:
    raise FileNotFoundError("No redirects.json or redirects.yml file found.")

# Ensure public directory is clean
if os.path.exists("public"):
    for file in os.listdir("public"):
        os.remove(os.path.join("public", file))
else:
    os.makedirs("public")

# Copy static files from static/ to public directory
shutil.copytree("static/", "public/", dirs_exist_ok=True)

# Set the default head for the HTML template
head = """<!DOCTYPE html>
<html lang="en">\n\n<head>
\t<!-- Default header values for all pages -->
\t<meta charset="UTF-8">
\t<meta name="viewport" content="width=device-width, initial-scale=1.0">
\t<meta http-equiv="X-UA-Compatible" content="ie=edge">
\t<meta name="robots" content="{2}">
\t<link rel="preconnect" href="https://fonts.googleapis.com">
\t<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
\t<link rel="preconnect" href="{0}">
\t<link rel="preload" href="style.css" as="style">
\t<link rel="preload" href="script.js" as="script">
\t<link href="https://fonts.googleapis.com/css2?family=Roboto:ital,wght@0,100..900;1,100..900&display=swap" rel="stylesheet">
\t<link href="style.css" rel="stylesheet" type="text/css">
\t<meta name="description" content="{1}">
\t<!-- Page generated dynamically -->
""".format(custom_domain, page_description, robots)

# Set the footer for the HTML template
footer = """\t<footer>
\t\t<span>
\t\t\t<a href="{1}" target="_blank" rel="noopener" title="GitHub Repository">
\t\t\t\t{0}
\t\t\t</a>
\t\t\ton GitHub
\t\t</span>
\t\t<span>{2}</span>
\t</footer>""".format(
    repo_name, repo_url, footer_attribution
)

# Set the template for the redirect pages
# The template includes a meta tag for redirection and a message for the user
template = """{0}\t<meta http-equiv="refresh" content="{3}; URL='{1}'">
\t<title>Redirecting...</title>\n</head>\n
<body>
\t<div class="container">
\t\t<p>Redirecting to <em>{1}</em>...</p>
\t</div>
{2}
\t<script src='script.js'></script>
</body>\n
</html>
"""

# Generate individual redirect pages
for slug, data in redirects.items():
    url = data["url"] if isinstance(data, dict) else data
    with open(f"public/{slug}.html", "w") as f:
        f.write(template.format(head, url, footer, redirect_delay))

# Generate the index.html file with the updated style
with open("public/index.html", "w") as index:
    index.write(
        """{0}\t<link rel="shortcut icon" href="{1}" type="image/x-icon">
\t<title>Redirect links</title>
</head>\n
<body>
\t<div class="container">
\t\t<h1>{2}</h1>
""".format(head, icon_path, index_title)
    )

    # Group redirects by category
    categorized_redirects = {}
    for slug, data in redirects.items():
        category = (
            data.get("category", uncategorized_title) if isinstance(data, dict) else uncategorized_title
        )
        if category not in categorized_redirects:
            categorized_redirects[category] = []
        categorized_redirects[category].append((slug, data))

    # Write categories and their links
    for category, items in sorted(categorized_redirects.items()):
        index.write(f"\t\t<h2>{category}</h2>\n\t\t<ul>\n")
        for slug, data in sorted(items, key=lambda x: x[0]):
            url = data["url"] if isinstance(data, dict) else data
            description = data.get("description", "") if isinstance(data, dict) else ""
            if description:
                index.write(
                    f'\t\t\t<li><a href="{slug}.html" title="Will redirect to: {url}">{slug}</a>: {description}</li>\n'
                )
            else:
                index.write(
                    f'\t\t\t<li><a href="{slug}.html" title="Will redirect to: {url}">{slug}</a></li>\n'
                )
        index.write("\t\t</ul>\n")

    index.write(
        """\t\t<button id="darkModeToggle">Toggle Dark Mode</button>
\t</div>
{0}
\t<script src='script.js'></script>
</body>\n
</html>\n""".format(footer)
    )
