FROM public.ecr.aws/docker/library/ruby:3.4.1-bullseye

RUN apt-get update -qq

RUN find / -perm /6000 -type f -exec chmod a-s {} \; || true
