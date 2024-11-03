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
    zip \
    unzip \
    git \
    python3 \
    lld

# Update new packages
RUN apt-get update


# --------------------------------------------------------------------------------------------------------------------------
# --------------------------------------------------------------------------------------------------------------------------
# Godot binary build image (download it)

FROM stage_prebuild_ubuntu as stage_build_godot_bin

ENV _THIS_DOCKER_GODOT_VERSION "4.3"

RUN wget https://github.com/godotengine/godot/releases/download/${_THIS_DOCKER_GODOT_VERSION}-stable/Godot_v${_THIS_DOCKER_GODOT_VERSION}-stable_linux.x86_64.zip
RUN unzip Godot_v${_THIS_DOCKER_GODOT_VERSION}-stable_linux.x86_64.zip
RUN mkdir /godot_bin
RUN mv Godot_v${_THIS_DOCKER_GODOT_VERSION}-stable_linux.x86_64 /godot_bin/godot


# --------------------------------------------------------------------------------------------------------------------------
# --------------------------------------------------------------------------------------------------------------------------
# Godot export templates build image (download it)

FROM stage_prebuild_ubuntu as stage_build_godot_templates

ENV _THIS_DOCKER_GODOT_VERSION "4.3"

# RUN wget https://github.com/godotengine/godot/releases/download/${_THIS_DOCKER_GODOT_VERSION}-stable/Godot_v${_THIS_DOCKER_GODOT_VERSION}-stable_export_templates.tpz
# RUN unzip Godot_v${_THIS_DOCKER_GODOT_VERSION}-stable_export_templates.tpz


RUN wget https://github.com/0x53A/godot-export-templates/releases/download/4-3-stable/export_templates_4.3.stable_win_and_web_release_only.zip
RUN unzip export_templates_4.3.stable_win_and_web_release_only.zip

RUN mkdir -p /godot_bin/editor_data/export_templates/${_THIS_DOCKER_GODOT_VERSION}.stable
RUN mv export_templates_4.3.stable_win_and_web_release_only/* /godot_bin/editor_data/export_templates/${_THIS_DOCKER_GODOT_VERSION}.stable


# --------------------------------------------------------------------------------------------------------------------------
# --------------------------------------------------------------------------------------------------------------------------
# emsdk build image

FROM emscripten/emsdk:3.1.70 as stage_build_emsdk
# https://github.com/emscripten-core/emsdk/tree/main/docker


# --------------------------------------------------------------------------------------------------------------------------
# --------------------------------------------------------------------------------------------------------------------------
# Alpine up to date and with dependencies

# FROM alpine as stage_prebuild_alpine

# RUN apk upgrade --no-cache

# RUN apk add --no-cache \
#     curl \
#     wget \
#     unzip \
#     git \
#     python3 \
#     gcompat \
#     build-base



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
RUN rustup target add x86_64-pc-windows-msvc --toolchain nightly
RUN rustup component add rust-src

RUN cargo install xwin

ENV XWIN_HOME="/rust/.xwin"

RUN xwin --accept-license splat --output $XWIN_HOME
RUN printf '\n\n[target.x86_64-pc-windows-msvc]\nlinker = "lld"\nrustflags = [\n  "-Lnative=$XWIN_HOME/crt/lib/x86_64",\n  "-Lnative=$XWIN_HOME/sdk/lib/um/x86_64",\n  "-Lnative=$XWIN_HOME/sdk/lib/ucrt/x86_64"\n]\n' > $CARGO_HOME/config.toml

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

COPY --from=stage_build_godot_bin /godot_bin /godot_bin
COPY --from=stage_build_godot_templates /godot_bin/editor_data/export_templates /godot_bin/editor_data/export_templates

ENV PATH="/godot_bin:${PATH}"

# https://docs.godotengine.org/en/stable/tutorials/io/data_paths.html#self-contained-mode
RUN echo "1" >> /godot_bin/_sc_

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

COPY --from=stage_build_rust /rust /rust

ENV CARGO_HOME="/rust/.cargo"
ENV RUSTUP_HOME="/rust/.rustup"
ENV XWIN_HOME="/rust/.xwin"

ENV PATH="/rust/.cargo/bin:${PATH}"

RUN echo "----------------------------------------" && rustup show && echo "----------------------------------------"

# ------------------------------------------------------------------

LABEL org.opencontainers.image.source https://github.com/0x53A/rust-gdext-wasm-github-action

#ENTRYPOINT ["/bin/bash"]