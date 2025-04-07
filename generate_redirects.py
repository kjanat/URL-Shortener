import os

# Detect and load redirects from JSON or YAML
redirects = {}
json_file = "redirects.json"
yaml_file = "redirects.yml"

if os.path.exists(json_file) and os.path.exists(yaml_file):
    import json
    import yaml

    json_redirects = json.load(open(json_file))
    yaml_redirects = yaml.safe_load(open(yaml_file))
    redirects = (
        json_redirects if len(json_redirects) >= len(yaml_redirects) else yaml_redirects
    )
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
/* General Styles */
body {
  font-family: 'Roboto', sans-serif;
  margin: 0;
  padding: 0;
  background-color: #f4f4f9;
  color: #333;
  transition: background-color 0.3s, color 0.3s; /* Smooth transition for dark mode */
}

/* Dark Mode Styles */
body.dark-mode {
  background-color: #121212;
  color: #eee;
}

.dark-mode h1,
.dark-mode h2 {
  color: #fff;
}

.dark-mode a {
  color: #80cbc4; /* Teal-ish color for links in dark mode */
}

.dark-mode .container {
  background-color: #212121;
  box-shadow: 0 2px 4px rgba(255, 255, 255, 0.1);
}

.dark-mode footer {
  background-color: #333;
  color: #fff;
}

h1,
h2 {
  color: #444;
}

a {
  color: #007BFF;
  text-decoration: none;
  position: relative;
  /* Required for tooltip positioning */
}

a:hover {
  text-decoration: underline;
}

/* Tooltip Styles */
a::after {
  content: attr(abbr);
  position: absolute;
  left: 50%;
  bottom: 100%;
  transform: translateX(-50%);
  background-color: #333;
  color: #fff;
  padding: 5px 10px;
  border-radius: 4px;
  font-size: 0.8em;
  white-space: nowrap;
  opacity: 0;
  visibility: hidden;
  transition: opacity 0.3s, visibility 0.3s;
  margin-bottom: 5px;
  z-index: 1;
}

.dark-mode a::after {
  background-color: #eee;
  color: #333;
}

a:hover::after {
  opacity: 1;
  visibility: visible;
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

footer {
  text-align: center;
  margin-top: 2em;
  padding: 1em;
  background-color: #ddd;
  /* Lock footer to bottom */
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  height: 50px;
}

/* Dark Mode Toggle Button Styles */
#darkModeToggle {
  background-color: #eee;
  color: #333;
  border: none;
  padding: 8px 16px;
  border-radius: 4px;
  cursor: pointer;
  font-size: 1em;
  transition: background-color 0.3s, color 0.3s;
}

.dark-mode #darkModeToggle {
  background-color: #333;
  color: #eee;
}

/* Mobile View Styles */
@media (max-width: 900px) {
  body {
    width: 100%;
    overflow-x: hidden;
  }

  .container {
    max-width: 90%;
    margin: 1em auto;
    padding: 0.5em;
  }

  footer {
    position: absolute; /* Removes fixed positioning on small screens */
    margin-top: 2em; /* Adjust margin for better spacing */
    bottom: 0;
    left: auto;
    right: auto;
    width: 100%;
  }

  /* Mobile Tooltip Styles */
  a::after {
    left: 0;
    right: auto;
    transform: none;
    text-align: center;
    width: auto;
    min-width: 200px;
  }
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
    index.write(
        """<!DOCTYPE html>
<html>
  <head>
    <title>Redirect links</title>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link href='https://fonts.googleapis.com/css2?family=Roboto:wght@400;700&display=swap' rel='stylesheet'>
    <link rel="shortcut icon" href="https://raw.githubusercontent.com/kjanat/pdf-extract-with-ocr/refs/heads/master/static/images/KJANAT.svg" type="image/x-icon" />
    <style>{}</style>
  </head>
  <body>
    <div class='container'>
      <h1>KJANAT URL Shortener</h1>
""".format(style)
    )

    # Group redirects by category
    categorized_redirects = {}
    for slug, data in redirects.items():
        category = (
            data.get("category", "") if isinstance(data, dict) else "Uncategorized"
        )
        if category not in categorized_redirects:
            categorized_redirects[category] = []
        categorized_redirects[category].append((slug, data))

    # Write categories and their links
    for category, items in sorted(categorized_redirects.items()):
        index.write(f"<h2>{category}</h2><ul>")
        for slug, data in sorted(items, key=lambda x: x[0]):
            url = data["url"] if isinstance(data, dict) else data
            description = data.get("description", "") if isinstance(data, dict) else ""
            if description:
                index.write(
                    f'<li><a href="{slug}.html" abbr="Will redirect to: {url}">{slug}</a>: {description}</li>'
                )
            else:
                index.write(
                    f'<li><a href="{slug}.html" abbr="Will redirect to: {url}">{slug}</a></li>'
                )
        index.write("</ul>")

    index.write('<button id="darkModeToggle">Toggle Dark Mode</button></div>')
    index.write(
        """
    <footer>
        <p>
            <a href="https://github.com/kjanat/url-shortener">
                URL Shortener
            </a>
            on GitHub
        </p>
    </footer>
    <script>
        const toggleButton = document.getElementById('darkModeToggle');
        toggleButton.addEventListener('click', () => {
            document.body.classList.toggle('dark-mode');
        });
    </script>
    """
    )
    index.write("</body></html>")
