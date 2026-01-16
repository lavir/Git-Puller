ARG BUILD_FROM
FROM $BUILD_FROM

RUN apk add --no-cache mc jq curl git openssh-client

# Copy data for add-on
COPY data/run.sh /
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]