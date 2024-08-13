FROM ruby:latest

RUN gem install httparty
COPY scan.rb /usr/app/

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app
COPY ./run .
CMD ["./run"]
ENTRYPOINT []
