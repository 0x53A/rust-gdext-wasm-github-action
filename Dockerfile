FROM alpine
# https://hub.docker.com/_/ubuntu/



# ------------------------------------------------------------------
# Variables
ENV _THIS_DOCKER_GODOT_VERSION "4.3"
ENV _THIS_DOCKER_EMSDK_VERSION_TO_INSTALL "3.1.70"
ENV _THIS_DOCKER_EMSDK_NODE_VERSION = "20.18.0"
# ------------------------------------------------------------------


RUN apk upgrade --no-cache

# Get Ubuntu packages
RUN apk add --no-cache \
#    build-essential \
    curl \
    wget \
    unzip \
    git \
    python3

# ------------------------------------------------------------------
# Get Godot

RUN wget https://github.com/godotengine/godot/releases/download/${_THIS_DOCKER_GODOT_VERSION}-stable/Godot_v${_THIS_DOCKER_GODOT_VERSION}-stable_linux.x86_64.zip \
    && wget https://github.com/godotengine/godot/releases/download/${_THIS_DOCKER_GODOT_VERSION}-stable/Godot_v${_THIS_DOCKER_GODOT_VERSION}-stable_export_templates.tpz \
    && mkdir ~/.cache \
    && mkdir -p ~/.config/godot \
    && mkdir -p ~/.local/share/godot/templates/${_THIS_DOCKER_GODOT_VERSION}.stable \
    && unzip Godot_v${_THIS_DOCKER_GODOT_VERSION}-stable_linux.x86_64.zip \
    && mv Godot_v${_THIS_DOCKER_GODOT_VERSION}-stable_linux.x86_64 /usr/local/bin/godot \
    && unzip Godot_v${_THIS_DOCKER_GODOT_VERSION}-stable_export_templates.tpz \
    && mv templates/* ~/.local/share/godot/templates/${_THIS_DOCKER_GODOT_VERSION}.stable \
    && rm -f Godot_v${_THIS_DOCKER_GODOT_VERSION}-stable_export_templates.tpz Godot_v${_THIS_DOCKER_GODOT_VERSION}-stable_linux.x86_64.zip

# ------------------------------------------------------------------
# Get EMSDK

RUN git clone https://github.com/emscripten-core/emsdk.git
RUN ./emsdk/emsdk install ${_THIS_DOCKER_EMSDK_VERSION_TO_INSTALL}
RUN ./emsdk/emsdk activate ${_THIS_DOCKER_EMSDK_VERSION_TO_INSTALL}

#note: github actions doesn't run .bashrc

ENV PATH="/emsdk:${PATH}"
ENV PATH="/emsdk/upstream/emscripten:${PATH}"
ENV PATH="/emsdk/node/${_THIS_DOCKER_EMSDK_NODE_VERSION}_64bit/bin:${PATH}"

ENV EMSDK="/emsdk"
ENV EMSDK_NODE="/emsdk/node/${_THIS_DOCKER_EMSDK_NODE_VERSION}_64bit/bin/node"

# ------------------------------------------------------------------

# Get Rust
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y

ENV PATH="/root/.cargo/bin:${PATH}"

RUN apk add --no-cache build-base

RUN rustup update
RUN rustup toolchain add nightly
RUN rustup default nightly
#RUN rustup update nightly
RUN rustup target add wasm32-unknown-emscripten --toolchain nightly
RUN rustup component add rust-src
#RUN rustup target add x86_64-unknown-linux-gnu --toolchain nightly
#RUN rustup target add x86_64-pc-windows-msvc --toolchain nightly
#RUN cargo install xwin
#RUN xwin --accept-license splat --output $HOME/.xwin

# I have no idea why this might be neccessary
#RUN rustup default nightly
RUN rustup target add x86_64-unknown-linux-musl --toolchain nightly
#RUN rustup show && rustup component add rust-src --toolchain nightly-x86_64-unknown-linux-gnu
#RUN rustup update
#RUN rustup update nightly

RUN printf '\n\n[target.x86_64-pc-windows-msvc]\nlinker = "lld"\nrustflags = [\n  "-Lnative=$HOME/.xwin/crt/lib/x86_64",\n  "-Lnative=$HOME/.xwin/sdk/lib/um/x86_64",\n  "-Lnative=$HOME/.xwin/sdk/lib/ucrt/x86_64"\n]\n' > $HOME/.cargo/config.toml

RUN echo "----------------------------------------"
RUN rustup show
RUN echo "----------------------------------------"

# ------------------------------------------------------------------

LABEL org.opencontainers.image.source https://github.com/0x53A/rust-gdext-wasm-github-action

#ENTRYPOINT ["/bin/bash"]