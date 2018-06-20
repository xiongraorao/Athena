#!/bin/bash

docker run -u root --rm  -d \
  -p 8081:8080  \
  -p 50000:50000 \
  -v jenkins-data:/var/jenkins_home  \
  -v /var/run/docker.sock:/var/run/docker.sock  \
  jenkinsci/blueocean:1.5.0
