FROM public.ecr.aws/docker/library/ruby:3.2.2-bullseye

RUN apt-get update -qq

RUN find / -perm /6000 -type f -exec chmod a-s {} \; || true
