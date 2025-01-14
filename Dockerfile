FROM ubuntu:24.04

ARG USERNAME=hluser
ARG USER_UID=10000
ARG USER_GID=$USER_UID

# create custom user, install dependencies, create data directory
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && apt-get update -y && apt-get install gpg curl -y \
    && mkdir -p /home/$USERNAME/hl/data \
    && mkdir -p /home/$USERNAME/hl/hyperliquid_data \
    && chown -R $USERNAME:$USERNAME /home/$USERNAME/hl

USER $USERNAME

WORKDIR /home/$USERNAME

# configure chain to testnet
RUN echo '{"chain": "Testnet"}' > /home/$USERNAME/visor.json

# add custom peer
RUN curl https://meria-hyperliquid-service.s3.eu-west-3.amazonaws.com/testnet/override_gossip_config.json -o /home/$USERNAME/override_gossip_config.json

# add validator key
COPY --chown=$USER_UID:$USER_GID node_config.json /home/$USERNAME/hl/hyperliquid_data/node_config.json

# add gpg key
COPY --chown=$USER_UID:$USER_GID pub_key.asc /home/$USERNAME/pub_key.asc
RUN gpg --import /home/$USERNAME/pub_key.asc

# save the public list of peers to connect to
ADD --chown=$USER_UID:$USER_GID https://binaries.hyperliquid.xyz/Testnet/initial_peers.json /home/$USERNAME/initial_peers.json

# temporary configuration file (will not be required in future update)
ADD --chown=$USER_UID:$USER_GID https://binaries.hyperliquid.xyz/Testnet/non_validator_config.json /home/$USERNAME/non_validator_config.json

# add the binary
ADD --chown=$USER_UID:$USER_GID --chmod=700 https://binaries.hyperliquid-testnet.xyz/Testnet/hl-visor /home/$USERNAME/hl-visor

# add binary signature
ADD --chown=$USER_UID:$USER_GID https://binaries.hyperliquid-testnet.xyz/Testnet/hl-visor.asc /home/$USERNAME/hl-visor.asc

# verify binary
RUN gpg --verify hl-visor.asc hl-visor

# run a non-validating node
ENTRYPOINT $HOME/hl-visor run-non-validator
