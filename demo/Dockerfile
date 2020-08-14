FROM alpine:edge

RUN apk --no-cache add bash ca-certificates

WORKDIR /usr/local/bin
RUN wget https://raw.githubusercontent.com/vishnubob/wait-for-it/ed77b63706ea721766a62ff22d3a251d8b4a6a30/wait-for-it.sh && \
    chmod +x wait-for-it.sh

CMD ["cat", "/app/test_files/zzz.txt"]
