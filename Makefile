NAME := novas0x2a/concourse-jenkins-resource
VERSION := $$(git describe --always)

build:
	docker build -t $(NAME):$(VERSION) .

push:
	docker tag $(NAME):$(VERSION) $(NAME):latest
	docker push $(NAME):$(VERSION)
	docker push $(NAME):latest

.PHONY: *
