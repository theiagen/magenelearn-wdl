FROM python:3.10-slim as app

ARG MAGENELEARN_VERSION=0.4.0

LABEL maintainer="Theiagen"
LABEL maintainer.email="developers@theiagen.com"
LABEL description="MaGeneLearn, a modular command-line tool for training, evaluating, and applying machine-learning models to bacterial genomics feature tables."
LABEL version="${MAGENELEARN_VERSION}"
LABEL base.image="mambaorg/micromamba:2-debian13-slim"
LABEL software="MaGeneLearn"
LABEL website="https://github.com/jpaganini/magenelearn"
LABEL license="https://github.com/jpaganini/magenelearn/blob/main/LICENSE"

RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    && pip install --upgrade pip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir maGeneLearn

WORKDIR /data  

RUN maGeneLearn --help

WORKDIR /data