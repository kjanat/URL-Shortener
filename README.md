# URL Shortener

This project is a simple URL shortener that generates HTML redirect pages
based on a JSON file of redirects.

## How It Works

1. The script `generate_redirects.py` reads a `redirects.json` file containing mappings of slugs to URLs.
2. It generates individual HTML files for each slug in the `docs/` directory, which redirect to the corresponding URL.
3. An `index.html` file is also created in the `docs/` directory, listing all available slugs with links to their respective redirect pages.

## Usage

1. Create a [`redirects.json`](redirects.json) or [`redirects.yml`](redirects.yml) file in the project root with the following format:

``` json
{
    "slug1": "https://example.com/page1",
    "slug2": "https://example.com/page2",
    "slug3": {
        "url": "https://example.com/page3",
        "description": "This is a description for page 3"
    }
}
```

or

``` yaml
slug1: https://example.com/page1
slug2: https://example.com/page2
slug3:
    description: "This is a description for page 3"
    url: https://example.com/page3
```

> [!IMPORTANT]
> If both `redirects.json` and `redirects.yml` files are present,
> the script will check which file has more entries,
> and use that one for generating redirects.  
> *When both files have the same number of entries,
> the script will use `redirects.json` by default.*
  
> [!TIP]
> Add a description for each slug in the JSON/YAML file
> to provide additional context for the redirect.  
> *The description is optional and will be included in the generated HTML file.*

2. Run the script:

``` bash
python generate_redirects.py
```

3. The generated HTML files will be available in the `docs/` directory.

## Requirements

- Python 3.x
