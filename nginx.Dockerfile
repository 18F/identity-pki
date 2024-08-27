FROM public.ecr.aws/nginx/nginx:stable-alpine-slim

RUN apk add jq curl

COPY ./k8files/update-ips.sh /update-ips.sh
COPY ./k8files/nginx-prod.conf /etc/nginx/nginx.conf
RUN /update-ips.sh
