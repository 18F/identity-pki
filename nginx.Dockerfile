FROM public.ecr.aws/docker/library/alpine:3

RUN apk add --no-cache jq curl nginx nginx-mod-http-headers-more

COPY ./k8files/update-ips.sh /update-ips.sh
COPY ./k8files/nginx-prod.conf /etc/nginx/nginx.conf
COPY ./k8files/status-map.conf /etc/nginx/
RUN /update-ips.sh
