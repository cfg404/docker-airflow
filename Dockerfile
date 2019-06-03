# VERSION 1.10.3
# AUTHOR: Matthieu "Puckel_" Roisil
# DESCRIPTION: Basic Airflow container
# BUILD: docker build --rm -t puckel/docker-airflow .
# SOURCE: https://github.com/puckel/docker-airflow

FROM python:3.7-slim
LABEL maintainer="cfg404"

# Airflow
ARG AIRFLOW_VERSION=1.10.3
ARG AIRFLOW_HOME=/usr/local/airflow
ARG MAKEFLAGS=-j4

ENV AIRFLOW_HOME=${AIRFLOW_HOME}

RUN set -ex \
    && buildDeps=' \
        build-essential \
        libffi-dev \
        libssl-dev \
        python3-dev \
    ' \
    && apt-get update && apt-get install -yqq --no-install-recommends \
        ${buildDeps} \
    && useradd -ms /bin/bash -d ${AIRFLOW_HOME} airflow \
    && pip install apache-airflow[crypto,postgres,kubernetes,aws,google_auth]==${AIRFLOW_VERSION} \
    && apt-get purge --auto-remove -yqq $buildDeps \
    && apt-get autoremove -yqq --purge \
    && apt-get clean \
    && rm -rf \
        /var/lib/apt/lists/* \
        /tmp/* \
        /var/tmp/* \
        /usr/share/man \
        /usr/share/doc \
        /usr/share/doc-base

COPY script/entrypoint.sh /entrypoint.sh
COPY config ${AIRFLOW_HOME}/config
COPY hooks ${AIRFLOW_HOME}/hooks

RUN chown -R airflow:airflow ${AIRFLOW_HOME}

EXPOSE 8080

USER airflow

WORKDIR ${AIRFLOW_HOME}

ENTRYPOINT ["/entrypoint.sh"]

CMD ["webserver"] # set default arg for entrypoint
