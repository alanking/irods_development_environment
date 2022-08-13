FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN \
  apt update && \
  apt install -y \
    sudo \
    git \
    python3 \
    python3-distro \
  && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/*

ARG externals_repo="https://github.com/irods/externals"
ARG externals_branch="main"

WORKDIR /externals
RUN \
  git clone "${externals_repo}" -b "${externals_branch}" /externals && \
  ./install_prerequisites.py && \
  rm -rf /externals

RUN \
  update-alternatives --install /usr/local/bin/gcc gcc /usr/bin/gcc-11 1 && \
  update-alternatives --install /usr/local/bin/g++ g++ /usr/bin/g++-11 1 && \
  hash -r

ENV file_extension="deb"
ENV package_manager="apt"

WORKDIR /
COPY build_and_copy_externals_to_dir.sh /
RUN chmod u+x /build_and_copy_externals_to_dir.sh
ENTRYPOINT ["./build_and_copy_externals_to_dir.sh"]
