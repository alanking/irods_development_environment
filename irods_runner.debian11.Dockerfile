# syntax=docker/dockerfile:1.5
#
# iRODS Runner
#
ARG runner_base=debian:11
FROM ${runner_base} as irods-runner

SHELL [ "/bin/bash", "-c" ]
ENV DEBIAN_FRONTEND=noninteractive

# Re-enable apt caching for RUN --mount
RUN rm -f /etc/apt/apt.conf.d/docker-clean && \
    echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache

# Make sure we're starting with an up-to-date image
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get autoremove -y --purge && \
    rm -rf /tmp/*
# To mark all installed packages as manually installed:
#apt-mark showauto | xargs -r apt-mark manual

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && \
    apt-get install --no-install-recommends -y \
        systemd \
        dbus-broker \
        dbus-user-session \
        libnss-systemd \
    && \
    apt-get install -y \
        apt-transport-https \
        wget \
        lsb-release \
        sudo \
        gnupg \
        procps \
        rsyslog \
        python3 \
        python3-psutil \
        python3-requests \
        python3-jsonschema \
        python3-pyodbc \
        python3-distro \
        libssl1.1 \
        super \
        lsof \
        postgresql \
        odbc-postgresql \
        libjson-perl \
    && \
    rm -rf /tmp/*

# install and configure rsyslog
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && \
    apt-get install -y \
        rsyslog \
    && \
    rm -rf /tmp/*
COPY irods.rsyslog /etc/rsyslog.d/00-irods.conf
COPY irods.logrotate /etc/logrotate.d/irods

# irodsauthuser required for some tests
# UID and GID ranges picked to hopefully not overlap with anything
RUN useradd \
        --key UID_MIN=40050 \
        --key UID_MAX=49000 \
        --key GID_MIN=40050 \
        --key GID_MAX=49000 \
        --create-home \
        --shell /bin/bash \
        irodsauthuser && \
    echo 'irodsauthuser:;=iamnotasecret' | chpasswd

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && \
    apt-get install -y \
        git \
        vim \
        nano \
        rsyslog \
    && \
    rm -rf /tmp/*

RUN wget -qO - https://packages.irods.org/irods-signing-key.asc | apt-key add - && \
    echo "deb [arch=amd64] https://packages.irods.org/apt/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/renci-irods.list && \
    wget -qO - https://core-dev.irods.org/irods-core-dev-signing-key.asc | apt-key add - && \
    echo "deb [arch=amd64] https://core-dev.irods.org/apt/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/renci-irods-core-dev.list

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && \
    apt-get install -y \
        'irods-externals*' \
    && \
    rm -rf /tmp/*

# Disable unwanted systemd units, set default target
RUN find /etc/systemd/system \
        /lib/systemd/system \
        \( -path '*.wants/*' -or -path '*.requires/*' -or -path '*.upholds/*' \) \
        -not -name '*journald*' \
        -not -name '*dbus*' \
        -not -name '*rsyslog*' \
        -not -name '*systemd-journal*' \
        -not -name '*systemd-tmpfiles*' \
        -not -name '*systemd-user-sessions*' \
        -not -name '*systemd-sysext*' \
        -delete && \
    rm -rf /lib/systemd/system/timers.target.wants/systemd-tmpfiles-clean.timer && \
    ln -sf /lib/systemd/system/multi-user.target /etc/systemd/system/default.target
# Note that the patterns passed to find above are being *excluded* from the delete command

COPY ICAT.sql /
COPY --chmod=755 keep_alive.sh /keep_alive.sh
ENTRYPOINT ["/keep_alive.sh"]
