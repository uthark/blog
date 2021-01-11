default: start

start:
	hugo server --minify --buildDrafts --verbose --debug  --enableGitInfo

publish:
	sh deploy.sh

