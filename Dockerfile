FROM python:3.11-slim-bookworm AS build

WORKDIR /opt/CTFd

# hadolint ignore=DL3008
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        libffi-dev \
        libssl-dev \
        git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && python -m venv /opt/venv

ENV PATH="/opt/venv/bin:$PATH"

COPY . /opt/CTFd

RUN pip install --no-cache-dir -r requirements.txt \
    && for d in CTFd/plugins/*; do \
        if [ -f "$d/requirements.txt" ]; then \
            pip install --no-cache-dir -r "$d/requirements.txt";\
        fi; \
    done;


FROM python:3.11-slim-bookworm AS release
WORKDIR /opt/CTFd

# hadolint ignore=DL3008
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libffi8 \
        libssl3 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY --chown=1001:1001 . /opt/CTFd

RUN useradd \
    --no-log-init \
    --shell /bin/bash \
    -u 1001 \
    ctfd \
    && mkdir -p /var/log/CTFd /var/uploads \
    && chown -R 1001:1001 /var/log/CTFd /var/uploads /opt/CTFd \
    && chmod +x /opt/CTFd/docker-entrypoint.sh

COPY --chown=1001:1001 --from=build /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

USER 1001
EXPOSE 8000
ENTRYPOINT ["/opt/CTFd/docker-entrypoint.sh"]
# Added by CVE Remediator: security updates for packages the image ships
USER root
RUN for init in $(find / -xdev -path '*/site-packages/setuptools/__init__.py' 2>/dev/null); do root="${init%/lib/python*}"; py=$(ls "$root"/bin/python3* 2>/dev/null | head -n 1); if [ -n "$py" ] && "$py" -m pip --version >/dev/null 2>&1; then "$py" -m pip install --no-cache-dir --upgrade setuptools; fi; done
RUN for init in $(find / -xdev -path '*/site-packages/wheel/__init__.py' 2>/dev/null); do root="${init%/lib/python*}"; py=$(ls "$root"/bin/python3* 2>/dev/null | head -n 1); if [ -n "$py" ] && "$py" -m pip --version >/dev/null 2>&1; then "$py" -m pip install --no-cache-dir --upgrade wheel; fi; done
USER 1001
