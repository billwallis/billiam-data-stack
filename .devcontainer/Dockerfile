FROM ubuntu:latest

RUN : \
  && apt-get update \
  && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    unzip \
    procps \
    git \
  && curl -LsSf https://astral.sh/uv/install.sh | sh \
  && /root/.local/bin/uv tool install poethepoet \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \

CMD ["/usr/bin/env bash"]
