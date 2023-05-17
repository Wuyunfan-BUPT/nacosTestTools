FROM cloudnativeofalibabacloud/test-runner:v0.0.1

# Copies your code file from your action repository to the filesystem path `/` of the container
COPY entry.sh /entry.sh

# Code file to execute when the docker container starts up (`entry.sh`)
ENTRYPOINT ["/entry.sh"]
