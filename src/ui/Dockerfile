FROM ruby:2.2-alpine

ENV APP_HOME /app
WORKDIR $APP_HOME

COPY . $APP_HOME

RUN apk --no-cache --update add build-base=0.4-r1 && \
    bundle instal && \
    apk del build-base

ENV POST_SERVICE_HOST post
ENV POST_SERVICE_PORT 5000
ENV COMMENT_SERVICE_HOST comment
ENV COMMENT_SERVICE_PORT 9292

CMD ["puma"]
