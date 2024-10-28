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
    curl

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
RUN wget https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip \
    && wget https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_export_templates.tpz \
    && mkdir ~/.cache \
    && mkdir -p ~/.config/godot \
    && mkdir -p ~/.local/share/godot/templates/${GODOT_VERSION}.stable \
    && unzip Godot_v${GODOT_VERSION}-stable_linux_headless.64.zip \
    && mv Godot_v${GODOT_VERSION}-stable_linux_headless.64 /usr/local/bin/godot \
    && unzip Godot_v${GODOT_VERSION}-stable_export_templates.tpz \
    && mv templates/* ~/.local/share/godot/templates/${GODOT_VERSION}.stable \
    && rm -f Godot_v${GODOT_VERSION}-stable_export_templates.tpz Godot_v${GODOT_VERSION}-stable_linux_headless.64.zip

# ------------------------------------------------------------------

# Variables
ENV EMSDK_VERSION_TO_INSTALL "latest"

RUN git clone https://github.com/emscripten-core/emsdk.git
RUN ./emsdk/emsdk install ${EMSDK_VERSION_TO_INSTALL}
RUN ./emsdk/emsdk activate ${EMSDK_VERSION_TO_INSTALL}
#RUN source ./emsdk/emsdk.sh
RUN echo 'source ./emsdk/emsdk.sh' >> $HOME/.bashrc

# ------------------------------------------------------------------

