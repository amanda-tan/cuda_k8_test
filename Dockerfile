# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.
FROM base-notebook-gpu

MAINTAINER aburnap@mit.edu
#MAINTAINER Jupyter Project <jupyter@googlegroups.com>

USER root

# Install all OS dependencies for fully functional notebook server
RUN apt-get update && apt-get install -yq --no-install-recommends \
    build-essential \
    git \
    curl\
    freeglut3-dev \
    libcupti-dev \
    libcurl3-dev \
    libfreetype6-dev \
    libpng12-dev \
    libzmq3-dev \
    pkg-config \
    python-dev \
    rsync \
    software-properties-common \
    inkscape \
    jed \
    libsm6 \
    libxext-dev \
    libxrender1 \
    lmodern \
    pandoc \
    vim \
    unzip \
    libpng-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ENV CUDNN_TAR_FILE cudnn-8.0-linux-x64-v6.0.tgz

RUN wget http://developer.download.nvidia.com/compute/redist/cudnn/v6.0/$CUDNN_TAR_FILE && \
    tar -xzvf $CUDNN_TAR_FILE && \
    cp -P cuda/include/cudnn.h /usr/local/cuda/include && \
    cp -P cuda/lib64/libcudnn* /usr/local/cuda/lib64/ && \
    chmod 777 /usr/local/cuda/lib64/libcudnn* && \
    rm -r cuda && \
    rm $CUDNN_TAR_FILE

# libav-tools for matplotlib anim
RUN apt-get update && \
    apt-get install -y --no-install-recommends libav-tools && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN curl -O https://bootstrap.pypa.io/get-pip.py && \
    python get-pip.py && \
    rm get-pip.py

#COPY jupyter_notebook_config.py ~/.jupyter/

RUN python -m pip install --upgrade pip

RUN pip --no-cache-dir install \
        Pillow \
        h5py \
        ipykernel \
        jupyter \
        matplotlib \
        seaborn \
        numpy \
        pandas \
        scipy \
        sklearn \
        && \
python -m ipykernel.kernelspec

RUN pip --no-cache-dir install \
        tensorflow \
        tensorflow-gpu \
        edward \
        keras && \
python -m ipykernel.kernelspec

RUN conda install pytorch torchvision -c soumith && \
    conda clean -tipsy && \
    fix-permissions $CONDA_DIR

ENV CUDA_HOME /usr/local/cuda-8.0
ENV LD_LIBRARY_PATH /usr/local/cuda-8.0:/usr/local/cuda-8.0/lib64:$LD_LIBRARY_PATH
ENV LD_LIBRARY_PATH /usr/local/cuda/extras/CUPTI/lib64:$LD_LIBRARY_PATH
ENV LIBRARY_PATH $LD_LIBRARY_PATH

# Install facets which does not have a pip or conda package at the moment
RUN cd /tmp && \
    git clone https://github.com/PAIR-code/facets.git && \
    cd facets && \
    jupyter nbextension install facets-dist/ --sys-prefix && \
    rm -rf facets && \
    fix-permissions $CONDA_DIR

# Import matplotlib the first time to build the font cache.
ENV XDG_CACHE_HOME /home/$NB_USER/.cache/
RUN MPLBACKEND=Agg python -c "import matplotlib.pyplot" && \
    fix-permissions /home/$NB_USER

USER $NB_USER
