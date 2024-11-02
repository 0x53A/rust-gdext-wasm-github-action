# --------------------------------------------------------------------------------------------------------------------------
# --------------------------------------------------------------------------------------------------------------------------
# Godot build image

FROM alpine as stage_build_godot

ENV _THIS_DOCKER_GODOT_VERSION "4.3"

RUN apk upgrade --no-cache
RUN apk add --no-cache \
    wget \
    unzip

# since this is just a build container anyway, we can split the command into multiple lines

RUN wget https://github.com/godotengine/godot/releases/download/${_THIS_DOCKER_GODOT_VERSION}-stable/Godot_v${_THIS_DOCKER_GODOT_VERSION}-stable_linux.x86_64.zip \
    && wget https://github.com/godotengine/godot/releases/download/${_THIS_DOCKER_GODOT_VERSION}-stable/Godot_v${_THIS_DOCKER_GODOT_VERSION}-stable_export_templates.tpz

RUN unzip Godot_v${_THIS_DOCKER_GODOT_VERSION}-stable_linux.x86_64.zip
RUn unzip Godot_v${_THIS_DOCKER_GODOT_VERSION}-stable_export_templates.tpz

RUN mkdir -p /godot_bin/editor_data/templates/${_THIS_DOCKER_GODOT_VERSION}.stable

RUN mv Godot_v${_THIS_DOCKER_GODOT_VERSION}-stable_linux.x86_64 /godot_bin/godot
RUN mv templates/* /godot_bin/editor_data/templates/${_THIS_DOCKER_GODOT_VERSION}.stable

# https://docs.godotengine.org/en/stable/tutorials/io/data_paths.html#self-contained-mode
RUN echo "1" >> /godot_bin/_sc_


# --------------------------------------------------------------------------------------------------------------------------
# --------------------------------------------------------------------------------------------------------------------------
# emsdk build image

FROM emscripten/emsdk:3.1.70 as stage_build_emsdk
# https://github.com/emscripten-core/emsdk/tree/main/docker

# --------------------------------------------------------------------------------------------------------------------------
# --------------------------------------------------------------------------------------------------------------------------
# Alpine up to date and with dependencies

FROM alpine as stage_prebuild_alpine

RUN apk upgrade --no-cache

RUN apk add --no-cache \
    curl \
    wget \
    unzip \
    git \
    python3 \
    gcompat \
    build-base

# --------------------------------------------------------------------------------------------------------------------------
# --------------------------------------------------------------------------------------------------------------------------
# Ubuntu up to date and with dependencies

FROM ubuntu as stage_prebuild_ubuntu

RUN apt-get update

# Get Ubuntu packages
RUN apt-get install -y \
    build-essential \
    curl \
    wget \
    unzip \
    git \
    python3

# Update new packages
RUN apt-get update


# --------------------------------------------------------------------------------------------------------------------------
# --------------------------------------------------------------------------------------------------------------------------
# rust build image

FROM stage_prebuild_ubuntu as stage_build_rust

ENV CARGO_HOME="/rust/.cargo"
ENV RUSTUP_HOME="/rust/.rustup"

RUN curl https://sh.rustup.rs -sSf | sh -s -- -y

ENV PATH="/rust/.cargo/bin:${PATH}"

RUN rustup toolchain add nightly
RUN rustup default nightly

RUN rustup target add wasm32-unknown-emscripten --toolchain nightly
RUN rustup component add rust-src

#RUN rustup target add x86_64-pc-windows-msvc --toolchain nightly
#RUN cargo install xwin
#RUN xwin --accept-license splat --output $HOME/.xwin
#RUN printf '\n\n[target.x86_64-pc-windows-msvc]\nlinker = "lld"\nrustflags = [\n  "-Lnative=$HOME/.xwin/crt/lib/x86_64",\n  "-Lnative=$HOME/.xwin/sdk/lib/um/x86_64",\n  "-Lnative=$HOME/.xwin/sdk/lib/ucrt/x86_64"\n]\n' > $HOME/.cargo/config.toml

#RUN rustup target add x86_64-unknown-linux-gnu --toolchain nightly
#RUN rustup target add x86_64-unknown-linux-musl --toolchain nightly

RUN echo "----------------------------------------"
RUN rustup show
RUN echo "----------------------------------------"

# --------------------------------------------------------------------------------------------------------------------------
# --------------------------------------------------------------------------------------------------------------------------
# main image

FROM stage_prebuild_ubuntu

# ------------------------------------------------------------------
# Variables
ENV _THIS_DOCKER_GODOT_VERSION "4.3"
ENV _THIS_DOCKER_EMSDK_VERSION_TO_INSTALL "3.1.70"
ENV _THIS_DOCKER_EMSDK_NODE_VERSION = "20.18.0"
# ------------------------------------------------------------------

# ------------------------------------------------------------------
# Get Godot

COPY --from=stage_build_godot /godot_bin /godot_bin

ENV PATH="/godot_bin:${PATH}"

RUN echo "----------------------------------------" && godot --version && echo "----------------------------------------"

# ------------------------------------------------------------------
# Get EMSDK

COPY --from=stage_build_emsdk /emsdk /emsdk

ENV PATH="/emsdk:${PATH}"
ENV PATH="/emsdk/upstream/emscripten:${PATH}"
ENV PATH="/emsdk/node/${_THIS_DOCKER_EMSDK_NODE_VERSION}_64bit/bin:${PATH}"

ENV EMSDK="/emsdk"
ENV EMSDK_NODE="/emsdk/node/${_THIS_DOCKER_EMSDK_NODE_VERSION}_64bit/bin/node"

RUN echo "----------------------------------------" && emcc --version && echo "----------------------------------------"

# ------------------------------------------------------------------

COPY --from=stage_build_rust /rust/.rustup /rust/.rustup
COPY --from=stage_build_rust /rust/.cargo /rust/.cargo

ENV CARGO_HOME="/rust/.cargo"
ENV RUSTUP_HOME="/rust/.rustup"

ENV PATH="/rust/.cargo/bin:${PATH}"

RUN echo "----------------------------------------" && rustup show && echo "----------------------------------------"

# ------------------------------------------------------------------

LABEL org.opencontainers.image.source https://github.com/0x53A/rust-gdext-wasm-github-action

#ENTRYPOINT ["/bin/bash"]