---
categories:
- development
- article
- octopress
comments: true
date: 2014-03-02T00:00:00Z
title: Fixing unescaped quotes in page rendering in Octopress
url: /2014/03/02/octopress-quote-fix/
---

When I created [About Me](/about) page I found issue with rendering: for some reason styles and some javascripts were missing on the page.

Investigation showed that content in `meta tag` description contained unquoted quotes, thus resulting in broken HTML.

After searching within [octopress sources] I found the issue:

Rendering of description tag, excerpt from _includes/head.html: 


``` ruby 
{% capture description %}
    {% if page.description %}
        {{ page.description }}
    {% else %}
        {{ content | raw_content }}
    {% endif %}
{% endcapture %}
<meta name="description" content="{{ description | strip_html | condense_spaces | truncate:150 }}">
```

After capturing, `description` is being processed with filters, defined in `plugins/octopress_filters.rb`. In this case, the following filter are applied:

* strip_html
* condense_spaces
* truncate

So, as you can see, if description contains quotes, then it will be rendered as is, without any escaping and quotes will break resulting page.

In order to fix this I decided to add new filter, which will just remove quotes.

So, let's add new function, `strip_quotes` in `plugins/octopress_filters.rb`:

strip_quotes function: 

``` ruby 
# Strips quotes
def strip_quotes(input)
    input.gsub(/[\'\""]/, '')
end
```

And then we need to update rendering of description tag - add newly created filter:


``` html
<meta name="description" content="{{ description | strip_html | condense_spaces | strip_quotes | truncate:150 }}">
```

After this fix description is being rendered properly.

P.S. In order to render properly `{{` and `}}` in the octopress it is required to put content you want to render within `raw` and `endraw` tags. See [StackOverflow][so1] [questions][so2] for details.

[octopress sources]: https://github.com/imathis/octopress/
[so1]: http://stackoverflow.com/questions/15786144/how-to-escape-in-markdown-on-octopress
[so2]: http://stackoverflow.com/questions/3426182/how-to-escape-liquid-template-tags/13582517#13582517

