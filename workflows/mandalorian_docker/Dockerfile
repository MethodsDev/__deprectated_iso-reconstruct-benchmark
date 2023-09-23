FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get -qq update
RUN apt-get -qq -y install automake
RUN apt-get -qq -y install build-essential
RUN apt-get -qq -y install curl
RUN apt-get -qq -y install libbz2-dev
RUN apt-get -qq -y install libcurl4-openssl-dev
RUN apt-get -qq -y install liblzma-dev
RUN apt-get -qq -y install libncurses-dev
RUN apt-get -qq -y install libncurses5-dev
RUN apt-get -qq -y install python3
RUN apt-get -qq -y install python3-dev
RUN apt-get -qq -y install python3-distutils
RUN apt-get -qq -y install python3-pip
RUN apt-get -qq -y install python3-setuptools
RUN apt-get -qq -y install wget
RUN apt-get -qq -y install zlib1g-dev
RUN apt-get -qq -y install git

ENV SRC=/usr/local/src
ENV BIN=/usr/local/bin

WORKDIR $SRC

RUN git clone https://github.com/christopher-vollmers/Mandalorion.git && \
	cd Mandalorion && \
	chmod +x setup.sh && \
	sh setup.sh && \
	/usr/local/src/Mandalorion/Mando.py -h

RUN mamba install -c bioconda samtools
