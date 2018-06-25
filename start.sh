#!/bin/sh
echo "\\033[0;33mStarting hugo server\\033[0m"

hugo server --buildDrafts --verbose --debug  --enableGitInfo

