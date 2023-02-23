# How to run
# 1. Copy your private key to ./api/clients/devkit/Dockerfile/api-client directory with the name private-key.pem
# 2. Create one-line file with issuer-id in it. Name it issuer and put it to ./api/clients/devkit/Dockerfile/api-client
# 3. For accesing swagger you need to expose port 8080 in your container with: -p <YOUR_PORT>:8080 flag
# 4. Now you can run the container with this command:
# docker run -p <YOUR_PORT>:8080 -v <harbormaster-path>/api/clients/devkit/Dockerfile/api-client/:/api-client/ -d <IMAGE_NAME>
#
# You are ready to go!
# To use python script: docker exec <CONTAINER_ID> python3 samples/python/<PATH_TO_SCRIPT>
# To use ansible playbook: docker exec <CONTAINER_ID> ansible-playbook samples/ansible/<PATH_TO_PLAYBOOK>
# To use hmctl: docker exec <CONTAINER_ID> hmctl <COMMAND>
# You can also enter interactive session: docker exec -it <CONTAINER_ID> /bin/bash

FROM swaggerapi/swagger-ui:v4.15.5

# Install required tools
RUN apk update
RUN apk add wget git py3-pip 
RUN apk add --no-cache bash bash-completion
RUN apk add terraform --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community

# Install Python SDK and Ansible
RUN pip3 install --upgrade pip && pip3 install purefusion cryptography==3.4.8 ansible netaddr

# Install ansible's fusion collection
RUN ansible-galaxy collection install purestorage.fusion

# Get ansible playbooks and python scripts
RUN mkdir samples
COPY ansible  ./samples/ansible
COPY python  ./samples/python

# Install hmctl 
RUN wget -O /bin/hmctl https://github.com/PureStorage-OpenConnect/hmctl/releases/latest/download/hmctl-linux-amd64
RUN chmod +x /bin/hmctl
RUN mkdir /etc/bash_completion.d
RUN hmctl completion bash > /etc/bash_completion.d/hmctl

# Swagger settings
ENV SWAGGER_JSON=/generated_spec.yaml
COPY ./generated/generated_spec.yaml /generated_spec.yaml

# Add entrypoint
COPY 50-fusion.sh /docker-entrypoint.d/50-fusion.sh
RUN chmod +x /docker-entrypoint.d/50-fusion.sh
RUN echo "$(cat /docker-entrypoint.d/50-fusion.sh)" > /etc/profile.d/bashrc.sh
