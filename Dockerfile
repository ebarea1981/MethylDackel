# Stage 1: Build stage
FROM ubuntu:24.04 as builder

# Metadata
LABEL base.image="ubuntu" \
    version="1" \
    software="MethylDackel" \
    maintainer="Eduardo Barea Bermudez" \
    maintainer.email="ebarea1981@gmail.com"

ENV PATH=/usr/local/bin:$PATH \
    LANG=C.UTF-8 \
    LD_LIBRARY_PATH=/usr/local/lib

WORKDIR /workdir

# Obtain required library for samtools/HTSLib
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \ 
    software-properties-common \
    build-essential \
    autoconf automake perl \
    zlib1g-dev libbz2-dev \
    liblzma-dev libcurl4-gnutls-dev \
    libssl-dev libncurses5-dev \
    libbigwig-dev \
    git gcc \
    && rm -rf /var/lib/apt/lists/*
    
# Clone and install HTSLib
RUN git clone https://github.com/samtools/htslib.git && \
    cd htslib && \
    autoreconf -i && \
    git submodule update --init --recursive && \
    ./configure && \
    make -j$(nproc) && \
    make install

# Clone and install MethylDackel
RUN git clone https://github.com/ebarea1981/MethylDackel.git && \
    cd MethylDackel && \
	make -j$(nproc) LIBBIGWIG="/usr/lib/x86_64-linux-gnu/libBigWig.a" && \
	make install;

# Stage 2: Final runtime stage
FROM ubuntu:24.04

# Metadata
LABEL base.image="ubuntu" \
    version="1" \
    software="MethylDackel" \
    maintainer="Eduardo Barea Bermudez" \
    maintainer.email="ebarea@epimethyl.com"

ENV PATH=/usr/local/bin:$PATH \
    LANG=C.UTF-8 \
    LD_LIBRARY_PATH=/usr/local/lib

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \ 
    zlib1g libbz2-dev \
    liblzma-dev libcurl4-gnutls-dev \
    libssl-dev libncurses5-dev \
    libbigwig-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy built dependencies from the builder stage
COPY --from=builder /usr/local/lib/ /usr/local/lib/
COPY --from=builder /usr/local/bin/ /usr/local/bin/

WORKDIR /workdir
