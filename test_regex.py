import re
html = "<h1>title</h1>\n<p>description</p>"
print(re.sub(r'</h1>\s*<p>', '</h1>\n<p class="lede">', html))
