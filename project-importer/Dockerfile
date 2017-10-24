FROM alpine

RUN apk add --no-cache tini curl jq

COPY ./entrypoint.sh /

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/entrypoint.sh"]
