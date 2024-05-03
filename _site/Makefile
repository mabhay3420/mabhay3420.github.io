JEKYLL = bundle exec jekyll

.PHONY: all serve new

all: serve

serve:
	$(JEKYLL) serve 

define TEMPLATE
---
layout: post
title: $(shell echo $(filter-out $@,$(MAKECMDGOALS)) | tr '[:lower:]' '[:upper:]')
subtitle: And Why they might matter?
cover-img: https://source.unsplash.com/collection/1695735/1920x1080
thumbnail-img: https://source.unsplash.com/collection/1695735/1920x1080
tags: []
comments: true
readtime: true
usemathjax: true
---
endef
export TEMPLATE

new:
	$(eval TODAY := $(shell date +'%Y-%m-%d'))
	$(eval NAME := $(shell echo $(filter-out $@,$(MAKECMDGOALS)) | tr '[:upper:]' '[:lower:]' | tr ' ' '-'))
	touch _posts/$(TODAY)-$(NAME).md
	echo "$$TEMPLATE" > _posts/$(TODAY)-$(NAME).md
	@echo "Created _posts/$(TODAY)-$(NAME).md"

%:
	@:
