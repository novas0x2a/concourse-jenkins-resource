FROM redfactorlabs/concourse-smuggler-resource:alpine

MAINTAINER "Mike Lundy <mike@fluffypenguin.org>"

COPY smuggler.yml /opt/resource/
