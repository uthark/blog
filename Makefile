default: start

start:
	hugo server --buildDrafts --verbose --debug  --enableGitInfo

publish:
	sh deploy.sh

