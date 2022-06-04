---
title: "Quick Entry Task to Omnifocus from Terminal"
date: 2020-10-05T22:07:21-07:00
draft: false
toc: false
comments: false
categories:
- omnifocus
- tip
tags:
- tip
- automation
- omnifocus
---

I use OmniFocus a lot and wanted to share with you simple automation that 
will allow adding tasks to OmniFocus without switching to the main window or 
using QuickEntry.

<!--more-->

We will use AppleScript, which comes with macOS out of the box.

1. Create a new Apple Script using Script Editor with the following content:

```applescript
on run argv
  tell application "OmniFocus"
    tell default document
      parse tasks into it with transport text item 1 of argv
    end tell
  end tell
end run
```

Save it to a folder like `~/bin` under the name `omni.scpt` (obviously, you can 
change it, and don't forget to update the shell script below).

2. Create a shell script `omni` and make it executable:

```bash
#!/bin/sh

# detect current folder.
script_path=$(dirname "$0")
# join all arguments to a single line
task="$*"
# invoke apple script and pass entry to it.
osascript "$script_path/omni.scpt" "$task"
```

3. Add the folder with both files to your `$PATH`.

4. That's it.

Example usage:

```sh
omni review agenda for meeting with Super team @review
```

Note that you can use tags when entering tasks. 
