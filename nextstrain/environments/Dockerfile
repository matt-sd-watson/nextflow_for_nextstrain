FROM continuumio/miniconda3:latest

USER root

COPY environment.yml .

RUN conda install mamba -c conda-forge && \
    apt-get update && apt-get install -y python3-pip && \
    mamba env create -f environment.yml

FROM ubuntu:20.04

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y gpgv &&\
	apt-get install -y git procps && apt install -y r-base && \
	apt install -f -y r-cran-dplyr && apt install -f -y r-cran-data.table && \
	apt install -f -y r-cran-optparse

WORKDIR /app
