HUGO_VERSION =  0.66.0
DOCKER_IMG   := klakegg/hugo:$(HUGO_VERSION)
SERVE_CMD    =  server --buildDrafts --buildFuture --disableFastRender --ignoreCache

clean:
	rm -rf public resources

serve:
	hugo server \
		--buildDrafts \
		--buildFuture \
		--disableFastRender

docker-serve:
	docker run --rm -it -v $(CURDIR):/src -p 1313:1313 $(DOCKER_IMG) $(SERVE_CMD)

production-build: clean
	hugo \
		--minify

preview-build: clean
	hugo \
		--baseURL $(DEPLOY_PRIME_URL) \
		--buildDrafts \
		--buildFuture \
		--minify

link-checker-setup:
	curl https://raw.githubusercontent.com/wjdp/htmltest/master/godownloader.sh | bash

run-link-checker:
	bin/htmltest

check-internal-links: production-build link-checker-setup run-link-checker

check-all-links: production-build link-checker-setup
	bin/htmltest --conf .htmltest.external.yml
