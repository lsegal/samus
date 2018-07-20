FROM python:3.7-alpine

RUN apk add openssh ruby ruby-json nodejs git curl
RUN pip install awscli
RUN gem install rake --no-rdoc --no-ri
RUN mkdir -p ~/.ssh
RUN echo "Host *" > ~/.ssh/config
RUN echo "    StrictHostKeyChecking no" >> ~/.ssh/config
RUN chmod 400 ~/.ssh/config

COPY . /samus
ENV PATH=$PATH:/samus/bin
