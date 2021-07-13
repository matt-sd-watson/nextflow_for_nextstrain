FROM continuumio/miniconda3:latest

USER root

WORKDIR /app

ARG DEBIAN_FRONTEND=noninteractive

COPY environment.yml .

RUN conda install mamba -c conda-forge && \
    apt-get update && apt-get install -y python3-pip && \
    conda env create -f environment.yml

SHELL ["conda", "run", "-n", "nf_nextstrain", "/bin/bash", "-c"]

ENV CONDA_DEFAULT_ENV $conda_env

ENV PATH /opt/conda/envs/$conda_env/bin:$PATH

CMD ["python", "/bin/bash", "Rscript"]

ENV PATH /opt/conda/envs/nf_nextstrain/bin:$PATH

ENTRYPOINT ["conda", "run", "--no-capture-output", "-n", "nf_nextstrain", "python", "augur"]

RUN 	apt-get update && \
	apt-get install -y git procps && apt install -y r-base && \
	apt install -f -y r-cran-dplyr && apt install -f -y r-cran-data.table && \
	apt update && apt install -f -y r-cran-optparse

RUN augur --version

RUN python --version

RUN R --version


