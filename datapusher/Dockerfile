# See CKAN docs on installation from Docker Compose on usage
FROM python:3.8.7-buster

# Install required system packages
RUN apt-get -q -y update \
    && DEBIAN_FRONTEND=noninteractive apt-get -q -y upgrade \
    && apt-get -q -y install \
	build-essential \
        vim \
        wget \
	locales \
	locales-all \
    && apt-get -q clean \
    && rm -rf /var/lib/apt/lists/*

# Define environment variables
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

# Build-time variables specified by docker-compose.yml / .env


# Setup virtual environment for datapusher


# Setup datapusher
ADD datapusher datapusher
RUN pip install -U pip && \
    pip install -r /datapusher/requirements.txt && \
    pip install /datapusher && \
    pip install uwsgi

CMD ["python","/datapusher/datapusher/main.py","/datapusher/deployment/datapusher_settings.py"]
#CMD ["ping", "horton-server"]
