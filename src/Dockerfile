# TODO modify FROM image to support nvidia cuda GPU
From alpine 

WORKDIR /app

COPY ./counter /app/counter

# install dependencies required by counter app:
RUN apk add libc6-compat libstdc++ libgcc

EXPOSE 10000
ENTRYPOINT ["/app/counter"]
