FROM python:3.11

WORKDIR /root/

# install yosys
WORKDIR /root/yosys/
ADD https://github.com/YosysHQ/oss-cad-suite-build/releases/download/2025-06-04/oss-cad-suite-linux-x64-20250604.tgz \
    oss-cad-suite.tgz
RUN tar -xvf oss-cad-suite.tgz
ENV PATH="/root/yosys/oss-cad-suite/bin:$PATH"
RUN yosys --version || exit 1

WORKDIR /root/
# install rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | bash -s -- -y
ENV PATH="/root/.cargo/bin:$PATH"
RUN rustup default nightly


RUN apt-get update && apt-get install -y build-essential cmake
