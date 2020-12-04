HUGO_VERSION =  0.79.0

clean:
	rm -rf public resources

serve:
	@./check_hugo.sh
	hugo server \
		--buildDrafts \
		--buildFuture \
		--disableFastRender

production-build: clean
	@./check_hugo.sh
	hugo \
		--minify

preview-build: clean
	@./check_hugo.sh
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
