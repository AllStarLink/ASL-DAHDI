ARG ARCH
ARG OS

FROM $ARCH/debian:$OS

ARG ARCH
ARG OS
ARG USER_ID
ARG GROUP_ID

RUN addgroup --gid $GROUP_ID user; exit 0
RUN adduser --disabled-password --gecos '' --uid $USER_ID --gid $GROUP_ID user; exit 0

# Install build dependencies
RUN apt-get update && apt-get -y install \
    build-essential \
    devscripts \
    fakeroot \
    debhelper \
    automake \
    autotools-dev \
    pkg-config \
    git \
    ca-certificates \
    wget \
    --no-install-recommends

# Bookworm/sid-specific build dependency - fail silently if package does not exist
RUN apt-get -y install dh-dkms; exit 0

# Install application dependencies
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -y install \
    debhelper bzip2 asciidoc-base dkms tar autoconf automake cpio pkg-config libnewt-dev bzip2 libusb-1.0-0-dev groff man-db \
    --no-install-recommends

# Import entrypoint script
COPY ./entrypoint.sh /entrypoint.sh

# Make Executable
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
