# TODO modify FROM image to support nvidia cuda GPU
#FROM alpine 
# install dependencies required by counter app:
#RUN apk add libc6-compat libstdc++ libgcc
FROM nvidia/cuda:12.4.1-base-ubuntu22.04

WORKDIR /app

COPY ./counter /app/counter

# RUN apt update && apt install -y --no-install-recommends libc6 # dependencies already exist in ubuntu22.04

EXPOSE 10000

ENTRYPOINT ["/app/counter"]
