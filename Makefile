default: start

.PHONY: start
start:
	hugo server --minify --buildDrafts --verbose --debug  --enableGitInfo

.PHONY: publish
publish:
	sh deploy.sh

.PHONY: new
new:
	hugo new content/post/$$(date "+%Y-%m-%d")-$(TITLE).md
