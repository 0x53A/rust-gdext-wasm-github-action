FROM ubuntu
# https://hub.docker.com/_/ubuntu/



# ------------------------------------------------------------------
# Variables
ENV GODOT_VERSION "4.3"
ENV EMSDK_VERSION_TO_INSTALL "latest"

# ------------------------------------------------------------------


# Update default packages
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

# ------------------------------------------------------------------
# Get Godot

RUN wget https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip \
    && wget https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_export_templates.tpz \
    && mkdir ~/.cache \
    && mkdir -p ~/.config/godot \
    && mkdir -p ~/.local/share/godot/templates/${GODOT_VERSION}.stable \
    && unzip Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip \
    && mv Godot_v${GODOT_VERSION}-stable_linux.x86_64 /usr/local/bin/godot \
    && unzip Godot_v${GODOT_VERSION}-stable_export_templates.tpz \
    && mv templates/* ~/.local/share/godot/templates/${GODOT_VERSION}.stable \
    && rm -f Godot_v${GODOT_VERSION}-stable_export_templates.tpz Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip

# ------------------------------------------------------------------
# Get EMSDK

RUN git clone https://github.com/emscripten-core/emsdk.git
RUN ./emsdk/emsdk install ${EMSDK_VERSION_TO_INSTALL}
RUN ./emsdk/emsdk activate ${EMSDK_VERSION_TO_INSTALL}
#RUN source ./emsdk/emsdk.sh
RUN echo 'source ./emsdk/emsdk.sh' >> $HOME/.bashrc

# ------------------------------------------------------------------

# Get Rust
RUN curl https://sh.rustup.rs -sSf | bash -s -- -y

ENV PATH="/root/.cargo/bin:${PATH}"

RUN rustup toolchain add nightly
RUN rustup target add wasm32-unknown-emscripten --toolchain nightly
RUN rustup target add x86_64-unknown-linux-gnu --toolchain nightly
RUN rustup target add x86_64-pc-windows-msvc --toolchain nightly
RUN cargo install xwin
RUN xwin --accept-license splat --output /home/me/.xwin

RUN printf '[target.x86_64-pc-windows-msvc]\nlinker = "lld"\nrustflags = [\n  "-Lnative=/home/me/.xwin/crt/lib/x86_64",\n  "-Lnative=/home/me/.xwin/sdk/lib/um/x86_64",\n  "-Lnative=/home/me/.xwin/sdk/lib/ucrt/x86_64"\n]\n' >> $HOME/.cargo/config.toml


# ------------------------------------------------------------------

LABEL org.opencontainers.image.source https://github.com/0x53A/rust-gdext-wasm-github-action

