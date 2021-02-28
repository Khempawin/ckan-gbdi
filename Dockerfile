# See CKAN docs on installation from Docker Compose on usage
FROM python:3.8.7-buster
MAINTAINER Open Knowledge

# Install required system packages
RUN apt-get -q -y update \
    && DEBIAN_FRONTEND=noninteractive apt-get -q -y upgrade \
    && apt-get -q -y install \
        libpq-dev \
        libxml2-dev \
        libxslt-dev \
        libgeos-dev \
        libssl-dev \
        libffi-dev \
        postgresql-client \
        build-essential \
        git-core \
        vim \
        wget \
    && apt-get -q clean \
    && rm -rf /var/lib/apt/lists/*

# Define environment variables
ENV CKAN_HOME /usr/lib/ckan
ENV CKAN_VENV $CKAN_HOME/venv
ENV CKAN_CONFIG /etc/ckan
ENV CKAN_STORAGE_PATH=/var/lib/ckan

# Build-time variables specified by docker-compose.yml / .env
ARG CKAN_SITE_URL

# Create ckan user
RUN useradd -r -u 900 -m -c "ckan account" -d $CKAN_HOME -s /bin/false ckan

# Setup virtual environment for CKAN
RUN mkdir -p $CKAN_VENV $CKAN_CONFIG $CKAN_STORAGE_PATH
RUN python3 -m venv $CKAN_VENV && \
    ln -s $CKAN_VENV/bin/pip /usr/local/bin/ckan-pip && \
    ln -s $CKAN_VENV/bin/ckan /usr/local/bin/ckan

# Setup CKAN
ADD ckan/ $CKAN_VENV/src/ckan/
ADD ckanext-envvars/ $CKAN_VENV/src/ckanext-envvars/
ADD ckanext-scheming/ $CKAN_VENV/src/ckanext-scheming/
ADD ckanext-hierarchy/ $CKAN_VENV/src/ckanext-hierarchy/
ADD ckanext-dcat/ $CKAN_VENV/src/ckanext-dcat/
ADD ckanext-thai_gdc/ $CKAN_VENV/src/ckanext-thai_gdc/
ADD ckan-entrypoint.sh /
RUN ckan-pip install -U pip && \
    ckan-pip install --upgrade --no-cache-dir -r $CKAN_VENV/src/ckan/requirement-setuptools.txt && \
    ckan-pip install --upgrade --no-cache-dir -r $CKAN_VENV/src/ckan/requirements.txt && \
    ckan-pip install -e $CKAN_VENV/src/ckan/ && \
    ln -s $CKAN_VENV/src/ckan/ckan/config/who.ini $CKAN_CONFIG/who.ini && \
    chmod +x /ckan-entrypoint.sh && \
    chown -R ckan:ckan $CKAN_HOME $CKAN_VENV $CKAN_CONFIG $CKAN_STORAGE_PATH
RUN ckan-pip install $CKAN_VENV/src/ckanext-envvars/
RUN ckan-pip install $CKAN_VENV/src/ckanext-scheming/
RUN ckan-pip install $CKAN_VENV/src/ckanext-hierarchy/ && \
    ckan-pip install -r $CKAN_VENV/src/ckanext-hierarchy/requirements.txt
RUN ckan-pip install $CKAN_VENV/src/ckanext-dcat/ && \
    ckan-pip install -r $CKAN_VENV/src/ckanext-dcat/requirements.txt
RUN ckan-pip install $CKAN_VENV/src/ckanext-thai_gdc/
ENTRYPOINT ["/ckan-entrypoint.sh"]

USER ckan
EXPOSE 5000

CMD ["ckan","-c","/etc/ckan/ckan.ini", "run", "--host", "0.0.0.0"]
# CMD ["ping","localhost"]
