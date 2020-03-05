HUGO_VERSION =  0.66.0
DOCKER_IMG   := klakegg/hugo:$(HUGO_VERSION)
SERVE_CMD    =  server --buildDrafts --buildFuture --disableFastRender --ignoreCache

serve:
	hugo server \
		--buildDrafts \
		--buildFuture \
		--disableFastRender

docker-serve:
	docker run --rm -it -v $(CURDIR):/src -p 1313:1313 $(DOCKER_IMG) $(SERVE_CMD)

production-build:
	hugo \
		--minify

preview-build:
	hugo \
		--baseURL $(DEPLOY_PRIME_URL) \
		--buildDrafts \
		--buildFuture \
		--minify
