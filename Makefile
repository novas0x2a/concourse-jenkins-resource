build:
	docker build -t novas0x2a/concourse-jenkins-resource:$$(git describe --always) .

.PHONY: *
