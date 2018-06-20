FROM alpine:edge

RUN apk --no-cache add bash ca-certificates

WORKDIR /usr/local/bin
RUN wget https://raw.githubusercontent.com/vishnubob/wait-for-it/db049716e42767d39961e95dd9696103dca813f1/wait-for-it.sh && \
    chmod +x wait-for-it.sh

CMD ["cat", "/app/test_files/zzz.txt"]
