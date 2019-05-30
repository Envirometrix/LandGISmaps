
FROM gcr.io/cloud-datalab/datalab:latest

# update GCP
RUN gcloud components update \
  && apt-get update \
  && apt-get install -y software-properties-common apt-transport-https \
  # SSH server
  && apt-get install -y openssh-server \
  # GDAL-BIN
  && add-apt-repository -y ppa:ubuntugis/ubuntugis-unstable \
  && apt-get update \
  && apt-get install -y gdal-bin \
  && apt-get install -y build-essential libssl-dev libffi-dev \
  && pip install cryptography \
  && apt-get purge -y build-essential libssl-dev libffi-dev \
                      dpkg-dev fakeroot libfakeroot:amd64 \
  # CLEANUP
  && apt-get autoremove -y \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Install the Earth Engine Python API.
RUN source activate $PYTHON_3_ENV && \
    pip uninstall -y google-api-core google-auth-httplib2 google-cloud-monitoring && \
    conda update -n base -c defaults conda && \
    conda install -y -c conda-forge google-auth-httplib2 google-cloud-storage google-cloud-monitoring nb_conda_kernels && \
    pip install earthengine-api && \
    # GDAL in conda
    conda install -y -c conda-forge libgdal gdal

# Install custom files in the container's /datalab directory.
RUN cp /datalab/run.sh /datalab/base-run.sh
ADD run.sh /datalab/
RUN chmod a+x /datalab/run.sh

# Add license information for the new libraries added.
ADD datalab-ee.txt /datalab/
RUN cat /datalab/datalab-ee.txt >> /datalab/web/static/datalab.txt \
  && rm /datalab/datalab-ee.txt
ADD license-ee.txt /datalab/
RUN cat /datalab/license-ee.txt >> /datalab/license.txt \
  && rm /datalab/license-ee.txt





