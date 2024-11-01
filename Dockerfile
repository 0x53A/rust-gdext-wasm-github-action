# https://github.com/GameDrivenDesign/docker-godot-export/blob/master/Dockerfile
# https://chucklindblom.com/2021/04/05/working-godot-docker-container/
# https://stackoverflow.com/a/49676568

# https://docs.github.com/en/actions/sharing-automations/creating-actions/creating-a-docker-container-action


FROM ubuntu
# https://hub.docker.com/_/ubuntu/

# Update default packages
RUN apt-get update

# Get Ubuntu packages
RUN apt-get install -y \
    build-essential \
    curl \
    wget \
    unzip

# Update new packages
RUN apt-get update

# ------------------------------------------------------------------

# Get Rust
RUN curl https://sh.rustup.rs -sSf | bash -s -- -y

ENV PATH="/root/.cargo/bin:${PATH}"

# ------------------------------------------------------------------

# Variables
ENV GODOT_VERSION "4.3"

# Get Godot
RUN wget https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip
RUN wget https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_export_templates.tpz

RUN mkdir ~/.cache \
    && mkdir -p ~/.config/godot \
    && mkdir -p ~/.local/share/godot/templates/${GODOT_VERSION}.stable \
    && unzip Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip \
    && mv Godot_v${GODOT_VERSION}-stable_linux.x86_64 /usr/local/bin/godot \
    && unzip Godot_v${GODOT_VERSION}-stable_export_templates.tpz \
    && mv templates/* ~/.local/share/godot/templates/${GODOT_VERSION}.stable \
    && rm -f Godot_v${GODOT_VERSION}-stable_export_templates.tpz Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip

# ------------------------------------------------------------------

# Variables
ENV EMSDK_VERSION_TO_INSTALL "latest"

RUN apt-get install -y \
    git \
    python3

RUN git clone https://github.com/emscripten-core/emsdk.git
RUN ./emsdk/emsdk install ${EMSDK_VERSION_TO_INSTALL}
RUN ./emsdk/emsdk activate ${EMSDK_VERSION_TO_INSTALL}
#RUN source ./emsdk/emsdk.sh
RUN echo 'source ./emsdk/emsdk.sh' >> $HOME/.bashrc

# ------------------------------------------------------------------


RUN rustup toolchain add nightly
RUN rustup target add wasm32-unknown-emscripten

# https://bevy-cheatbook.github.io/setup/cross/linux-windows.html
RUN rustup target add x86_64-pc-windows-msvc
RUN cargo install xwin
RUN xwin --accept-license splat --output /home/me/.xwin

RUN printf '[target.x86_64-pc-windows-msvc]\nlinker = "lld"\nrustflags = [\n  "-Lnative=/home/me/.xwin/crt/lib/x86_64",\n  "-Lnative=/home/me/.xwin/sdk/lib/um/x86_64",\n  "-Lnative=/home/me/.xwin/sdk/lib/ucrt/x86_64"\n]\n' >> $HOME/.cargo/config.toml


#cargo +nightly build -Zbuild-std --target wasm32-unknown-emscripten --release
#cargo build --target=x86_64-pc-windows-msvc --release
# --------------------------------- 

LABEL org.opencontainers.image.source https://github.com/0x53A/rust-gdext-wasm-github-action

