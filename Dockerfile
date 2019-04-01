FROM python:3.7-alpine

RUN apk add -U --no-cache openssh ruby ruby-json nodejs git curl
RUN pip install awscli
RUN gem install bundler -v '1.17.3' --no-rdoc --no-ri
RUN gem install rake --no-rdoc --no-ri
RUN mkdir -p ~/.ssh
RUN echo "Host *" > ~/.ssh/config
RUN echo "    StrictHostKeyChecking no" >> ~/.ssh/config
RUN chmod 400 ~/.ssh/config

RUN git config --global user.email "bot@not.human"
RUN git config --global user.name "Samus Release Bot"

COPY . /samus
ENV PATH=$PATH:/samus/bin

WORKDIR /build
ENTRYPOINT [ "/samus/entrypoint.sh" ]
