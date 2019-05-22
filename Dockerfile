# VERSION 1.10.3
# AUTHOR: Matthieu "Puckel_" Roisil
# DESCRIPTION: Basic Airflow container
# BUILD: docker build --rm -t puckel/docker-airflow .
# SOURCE: https://github.com/puckel/docker-airflow

FROM python:3.7-alpine
LABEL maintainer="covidium_"

# Airflow
ARG AIRFLOW_VERSION=1.10.3
ARG AIRFLOW_HOME=/usr/local/airflow
ARG MAKEFLAGS=-j4

COPY script/entrypoint.sh /entrypoint.sh
COPY config/airflow.cfg ${AIRFLOW_HOME}/airflow.cfg

# See: https://github.com/apache/airflow/blob/master/setup.py#L235
RUN apk add --no-cache --update --virtual .build-deps \
    build-base \
    libffi-dev \
    openssl-dev \
    python3-dev \
    postgresql-dev \
    musl-dev \
    libxml2-dev \
    && addgroup -S airflow && adduser -S airflow -G airflow \
    && pip install apache-airflow[crypto,postgres,kubernetes,s3]==${AIRFLOW_VERSION} \
    && apk del --no-cache .build-deps

RUN chown -R airflow:airflow ${AIRFLOW_HOME}

EXPOSE 8080

USER airflow

WORKDIR ${AIRFLOW_HOME}

ENTRYPOINT ["/entrypoint.sh"]

CMD ["webserver"] # set default arg for entrypoint
