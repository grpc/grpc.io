HTMLTEST_DIR=tmp
HTMLTEST?=htmltest # Specify as make arg if different
# Use $(HTMLTEST) in PATH, if available; otherwise, we'll get a copy
ifeq (, $(shell which $(HTMLTEST)))
GET_LINK_CHECKER_IF_NEEDED=get-link-checker
override HTMLTEST=$(HTMLTEST_DIR)/bin/htmltest
endif

check-internal-links: $(GET_LINK_CHECKER_IF_NEEDED)
	$(HTMLTEST)

check-all-links: $(GET_LINK_CHECKER_IF_NEEDED)
	$(HTMLTEST) --conf .htmltest.external.yml

clean-htmltest-dir:
	rm -Rf $(HTMLTEST_DIR)

get-link-checker:
	rm -Rf $(HTMLTEST_DIR)/bin
	curl https://htmltest.wjdp.uk | bash -s -- -b $(HTMLTEST_DIR)/bin
