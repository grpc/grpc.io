HTMLTEST?=htmltest # Specify as make arg if different
HTMLTEST_ARGS?=--skip-external
HTMLTEST_DIR=tmp

# Use $(HTMLTEST) in PATH, if available; otherwise, we'll get a copy
ifeq (, $(shell which $(HTMLTEST)))
override HTMLTEST=$(HTMLTEST_DIR)/bin/htmltest
ifeq (, $(shell which $(HTMLTEST)))
GET_LINK_CHECKER_IF_NEEDED=get-link-checker
endif
endif

check-links: $(GET_LINK_CHECKER_IF_NEEDED)
	$(HTMLTEST) $(HTMLTEST_ARGS)

# Until htmltext >0.14.x is released, get and build our own from source:
get-link-checker:
	rm -Rf $(HTMLTEST_DIR)
	mkdir -p $(HTMLTEST_DIR)/bin && \
	pushd $(HTMLTEST_DIR) && \
	git clone --depth=1 https://github.com/wjdp/htmltest.git && \
	cd htmltest && \
	./build.sh && \
	cp bin/htmltest ../bin && \
	popd

# Once htmltext >0.14.x is released, replace the get-and-build code above with this:
# get-link-checker:
# 	rm -Rf $(HTMLTEST_DIR)/bin
# 	curl https://htmltest.wjdp.uk | bash -s -- -b $(HTMLTEST_DIR)/bin
