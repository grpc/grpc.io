DRAFT_ARGS = --buildDrafts --buildFuture
BUILD_ARGS = --minify
ifeq (draft, $(or $(findstring draft,$(HEAD)),$(findstring draft,$(BRANCH))))
BUILD_ARGS += $(DRAFT_ARGS)
endif

clean:
	rm -rf public/* resources

serve:
	@./check_hugo.sh
	hugo server

serve-drafts:
	@./check_hugo.sh
	hugo server $(DRAFT_ARGS)

serve-production: clean
	@./check_hugo.sh
	hugo server --minify

production-build: clean
	@./check_hugo.sh
	hugo --minify

preview-build: clean
	@./check_hugo.sh
	hugo --baseURL $(DEPLOY_PRIME_URL) $(BUILD_ARGS)

link-checker-setup:
	curl https://raw.githubusercontent.com/wjdp/htmltest/master/godownloader.sh | bash

run-link-checker:
	bin/htmltest

check-internal-links: production-build link-checker-setup run-link-checker

check-all-links: production-build link-checker-setup
	bin/htmltest --conf .htmltest.external.yml
