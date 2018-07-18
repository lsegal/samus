FROM python:3.7-alpine

RUN apk add openssh ruby ruby-json nodejs git curl
RUN pip install awscli
RUN gem install rake --no-rdoc --no-ri

COPY . /samus
ENV PATH=$PATH:/samus/bin
