FROM python:3.11-slim

WORKDIR /workspace

RUN apt-get update && apt-get install -y --no-install-recommends \
    openssh-client \
    git \
    && rm -rf /var/lib/apt/lists/*

COPY local/bin/ /root/.local/bin/
COPY config/yadm/tests/ /root/.config/yadm/tests/

RUN chmod +x /root/.local/bin/*
ENV PATH="/root/.local/bin:${PATH}"

CMD ["python3", "-m", "unittest", "discover", "-s", "/root/.config/yadm/tests"]
