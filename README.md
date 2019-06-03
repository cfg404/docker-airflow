# docker-airflow
[![Docker Hub](https://img.shields.io/badge/docker-ready-blue.svg)](https://hub.docker.com/r/cfg404/airflow)


This repository contains **Dockerfile** of [apache-airflow](https://github.com/apache/incubator-airflow) for [Docker](https://www.docker.com/)'s [automated build](https://cloud.docker.com/u/cfg404/repository/docker/cfg404/airflow) published to the public [Docker Hub Registry](https://registry.hub.docker.com/).

## Info about versions and image

Airflow: 1.10.3
Python: 3.7-slim

Added also:
* https://github.com/puckel/docker-airflow/pull/349
* https://github.com/puckel/docker-airflow/pull/299

## Installation

Pull the image from the Docker repository.

    docker pull cfg404/airflow:tag

Example:

    docker pull cfg404/airflow:latest

## Build

Optionally install [Extra Airflow Packages](https://airflow.incubator.apache.org/installation.html#extra-package) and/or python dependencies at build time :

    docker build --rm --build-arg AIRFLOW_DEPS="datadog,dask" -t cfg404/airflow .
    docker build --rm --build-arg PYTHON_DEPS="flask_oauthlib>=0.9" -t cfg404/airflow .

or combined

    docker build --rm --build-arg AIRFLOW_DEPS="datadog,dask" --build-arg PYTHON_DEPS="flask_oauthlib>=0.9" -t cfg404/airflow .

Don't forget to update the airflow images in the docker-compose files to puckel/docker-airflow:latest.

## Usage

By default, docker-airflow runs Airflow with **SequentialExecutor** :

    docker run -d -p 8080:8080 cfg404/airflow webserver

If you want to run another executor, use the other docker-compose.yml files provided in this repository.

`LOAD_EX=n`

    docker run -d -p 8080:8080 -e LOAD_EX=y cfg404/airflow

If you want to use Ad hoc query, make sure you've configured connections:
Go to Admin -> Connections and Edit "postgres_default" set this values (equivalent to values in airflow.cfg/docker-compose*.yml) :
- Host : postgres
- Schema : airflow
- Login : airflow
- Password : airflow

For encrypted connection passwords (in Local or Celery Executor), you must have the same fernet_key. By default docker-airflow generates the fernet_key at startup, you have to set an environment variable in the docker-compose (ie: docker-compose-LocalExecutor.yml) file to set the same key accross containers. To generate a fernet_key :

    docker run cfg404/airflow python -c "from cryptography.fernet import Fernet; FERNET_KEY = Fernet.generate_key().decode(); print(FERNET_KEY)"

## Configurating Airflow with KubernetesExecutor, PostgreSQL and DAGS from git.

It's possible to set any configuration value for Airflow from environment variables, but in this case we'll focus on how to properly setup Airflow to run with KubernetesExecutor, connect to a PostgreSQL database and retrieve dags from a GIT repository.

The following environment variables are needed in order to make it work properly:

    AIRFLOW__CORE__FERNET_KEY: <my-fernet-key>
    AIRFLOW__CORE__EXECUTOR: KubernetesExecutor
    AIRFLOW__CORE__DAGS_FOLDER: /dags
    AIRFLOW__CORE__SQL_ALCHEMY_CONN: postgresql+psycopg2://username:password@database-host:5432/database-name
    AIRFLOW__CORE__LOAD_SAMPLES: False
    AIRFLOW__KUBERNETES__GIT_REPO: https://github.com/my-user/dags-repo.git/
    AIRFLOW__KUBERNETES__GIT_BRANCH: master
    AIRFLOW__KUBERNETES__GIT_DAGS_FOLDER_MOUNT_POINT: /dags
    AIRFLOW__KUBERNETES__WORKER_SERVICE_ACCOUNT_NAME: <k8s-service-account-name>
    AIRFLOW__KUBERNETES__WORKER_CONTAINER_REPOSITORY: cfg404/airflow
    AIRFLOW__KUBERNETES__WORKER_CONTAINER_TAG: latest
    AIRFLOW__KUBERNETES__NAMESPACE: <name-space-where-airflow-will-run>
    AIRFLOW__WEBSERVER__EXPOSE_CONFIG: True
    AIRFLOW__SCHEDULER__DAG_DIR_LIST_INTERVAL: 30

The general rule is the environment variable should be named `AIRFLOW__<section>__<key>`, for example `AIRFLOW__CORE__SQL_ALCHEMY_CONN` sets the `sql_alchemy_conn` config option in the `[core]` section.

You can view all the parameters of the configuration file [here](https://github.com/apache/airflow/blob/master/airflow/config_templates/default_airflow.cfg) and you can view the Airflow setting configuration options [here](http://airflow.readthedocs.io/en/latest/howto/set-config.html#setting-configuration-options)

## Custom Airflow plugins

Airflow allows for custom user-created plugins which are typically found in `${AIRFLOW_HOME}/plugins` folder. Documentation on plugins can be found [here](https://airflow.apache.org/plugins.html)

In order to incorporate plugins into your docker container
- Create the plugins folders `plugins/` with your custom plugins.
- Mount the folder as a volume by doing either of the following:
    - Include the folder as a volume in command-line `-v $(pwd)/plugins/:/usr/local/airflow/plugins`
    - Use docker-compose-LocalExecutor.yml or docker-compose-CeleryExecutor.yml which contains support for adding the plugins folder as a volume

## Install custom python package

- Create a file "requirements.txt" with the desired python modules
- Mount this file as a volume `-v $(pwd)/requirements.txt:/requirements.txt` (or add it as a volume in docker-compose file)
- The entrypoint.sh script execute the pip install command (with --user option)

## UI Links

- Airflow: [localhost:8080](http://localhost:8080/)
- Flower: [localhost:5555](http://localhost:5555/)
ng docker swarm.

## Running other airflow commands

If you want to run other airflow sub-commands, such as `list_dags` or `clear` you can do so like this:

    docker run --rm -ti cfg404/airflow airflow list_dags

or with your docker-compose set up like this:

    docker-compose -f docker-compose-CeleryExecutor.yml run --rm webserver airflow list_dags

You can also use this to run a bash shell or any other command in the same environment that airflow would be run in:

    docker run --rm -ti cfg404/airflow bash
    docker run --rm -ti cfg404/airflow ipython

## A working KubernetesPodOperator DAG

If you want to use this example, don't forget to update the service_account_name to reflect your setup and update the name of the dag (dag_id) and of course task_id and name.

```
import datetime

from airflow import models
from airflow.contrib.operators import kubernetes_pod_operator

YESTERDAY = datetime.datetime.now() - datetime.timedelta(days=1)

# If a Pod fails to launch, or has an error occur in the container, Airflow
# will show the task as failed, as well as contain all of the task logs
# required to debug.
with models.DAG(
        dag_id='myDag',
        schedule_interval=datetime.timedelta(days=1),
        start_date=YESTERDAY) as dag:
    # Only name, namespace, image, and task_id are required to create a
    # KubernetesPodOperator. In Cloud Composer, currently the operator defaults
    # to using the config file found at `/home/airflow/composer_kube_config if
    # no `config_file` parameter is specified. By default it will contain the
    # credentials for Cloud Composer's Google Kubernetes Engine cluster that is
    # created upon environment creation.
    kubernetes_min_pod = kubernetes_pod_operator.KubernetesPodOperator(
        # The ID specified for the task.
        task_id='myPod',
        # Name of task you want to run, used to generate Pod ID.
        name='myPod',
        # Entrypoint of the container, if not specified the Docker container's
        # entrypoint is used. The cmds parameter is templated.
        cmds=['echo'],
        # The namespace to run within Kubernetes, default namespace is
        # `default`. There is the potential for the resource starvation of
        # Airflow workers and scheduler within the Cloud Composer environment,
        # the recommended solution is to increase the amount of nodes in order
        # to satisfy the computing requirements. Alternatively, launching pods
        # into a custom namespace will stop fighting over resources.
        namespace='<name-space-where-airflow-will-run>',
        # Docker image specified. Defaults to hub.docker.com, but any fully
        # qualified URLs will point to a custom repository. Supports private
        # gcr.io images if the Composer Environment is under the same
        # project-id as the gcr.io images.
        image='ubuntu:latest',
        # Service account name to use when spawning a pod
        service_account_name="<k8s-service-account-name>",
        in_cluster=True,
    )
```

# Wanna help?

Fork, improve and PR. ;-)
