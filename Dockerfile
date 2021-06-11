FROM ubuntu:bionic

RUN apt-get update && apt-get install -y git make wget software-properties-common

RUN apt-get update && \
    apt-get install -y git make g++  zlib1g zlib1g-dev
RUN cd /tmp/ && \
    git clone https://github.com/OpenGene/fastp.git && \
    cd fastp && \
    git checkout $fastp_version && \
    make && \
    make install

RUN add-apt-repository -y \
    ppa:webupd8team/java

RUN apt-get update && \
    apt-get install -y openjdk-8-jdk && \
    apt-get install -y ant && \
    apt-get clean;
# Fix certificate issues
RUN apt-get update && \
    apt-get install ca-certificates-java && \
    apt-get clean && \
    update-ca-certificates -f;

# Setup JAVA_HOME -- useful for docker commandline
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64/
RUN export JAVA_HOME

RUN cd /usr/local/bin/ && \
    apt-get install unzip && \
    wget https://www.bioinformatics.babraham.ac.uk/projects/fastqc/fastqc_v0.11.9.zip && \
    unzip fastqc_v0.11.9.zip && \
    chmod 755 FastQC/fastqc && \
    ln -s $PWD/FastQC/fastqc /usr/local/bin/

RUN git clone https://github.com/lh3/bwa.git \
&& cd bwa; make \
&& ln -s $PWD/bwa /usr/local/bin/

RUN wget http://cab.spbu.ru/files/release3.15.2/SPAdes-3.15.2-Linux.tar.gz && \
    tar -xzf SPAdes-3.15.2-Linux.tar.gz && \
    ln -s $PWD/SPAdes-3.15.2-Linux/bin/rnaspades.py /usr/local/bin/

RUN apt-get -y install python2.7 

RUN apt-get install -y autoconf automake make gcc perl zlib1g-dev libbz2-dev liblzma-dev libcurl4-gnutls-dev libssl-dev libncurses5-dev unzip
RUN wget https://github.com/samtools/samtools/releases/download/1.12/samtools-1.12.tar.bz2
RUN tar -xjf samtools-1.12.tar.bz2 \
&& cd samtools-1.12 \
&& make install

RUN wget http://hgdownload.cse.ucsc.edu/admin/exe/linux.x86_64/blat/blat &&\
    chmod +x blat && \
    ln -s $PWD/blat /usr/local/bin/ && \
    apt-get install -y libcurl3


# Install the dependencies
RUN apt-get update
RUN DEBIAN_FRONTEND="noninteractive" apt-get -y install tzdata 
RUN apt-get install -y wget python-pip python-matplotlib make unzip samtools emboss emboss-lib zlib1g-dev
RUN pip install gffutils 
RUN pip install joblib 

# Install rnaQUAST-1.2.0
RUN wget -O-  http://cab.spbu.ru/files/rnaquast/release2.2.0/rnaQUAST-2.2.0.tar.gz | tar zxvf - && \
    ln -s $PWD/rnaQUAST-2.2.0/rnaQUAST.py /usr/local/bin/


RUN apt-get update && apt-get -y upgrade && apt-get install -y build-essential vim git wget ncbi-blast+ python3 python3-pip 

WORKDIR /usr/src

# install Hmmer
RUN wget http://eddylab.org/software/hmmer/hmmer-3.1b2.tar.gz && tar xvfz hmmer-3.1b2.tar.gz && \
	cd hmmer-3.1b2 && ./configure && make && make install && cd ..

# install Augustus
RUN apt install -y augustus augustus-data augustus-doc && \
	wget -O /usr/bin/augustus https://github.com/Gaius-Augustus/Augustus/releases/download/3.3.2/augustus
ENV AUGUSTUS_CONFIG_PATH /usr/share/augustus/config

# install BUSCO and set the default in the scripts to python3 so I don't have to type it each time
# and full path each time when called
RUN git clone --recursive https://gitlab.com/ezlab/busco.git && \
	cd busco && \
	git reset --soft 3927d240 && \
	python3 setup.py install && cd .. && \
	sed -i 's?/usr/bin/env python?/usr/bin/env python3?' /usr/src/busco/scripts/generate_plot.py && \
	sed -i 's?/usr/bin/env python?/usr/bin/env python3?' /usr/src/busco/src/busco/run_BUSCO.py && \
	ln -s /usr/src/busco/scripts/*.py /usr/bin/ && \
	ln -s /usr/src/busco/scr/busco/*.py /usr/bin/ 

ADD config.ini /usr/src/busco/config
ENV BUSCO_CONFIG_FILE /usr/src/busco/config/config.ini

#Install R (R installation asks for timezone interactively so this needs to be switched off and set before)
ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN true
## preesed tzdata, update package index, upgrade packages and install needed software
# and finally ggplot2 with all dependencies
RUN echo "tzdata tzdata/Areas select Europe" > /tmp/preseed.txt; \
	echo "tzdata tzdata/Zones/Europe select Vienna" >> /tmp/preseed.txt; \
	debconf-set-selections /tmp/preseed.txt && \
	apt-get update && \
	apt-get install -y tzdata r-base && \
	R --vanilla -e 'install.packages("ggplot2", repos="http://cran.wu.ac.at/")'
