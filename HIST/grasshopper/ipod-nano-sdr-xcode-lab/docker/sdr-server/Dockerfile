FROM python:3.12-slim
RUN apt-get update && apt-get install -y --no-install-recommends \
    rtl-sdr librtlsdr0 libusb-1.0-0 ca-certificates \
  && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY docker/sdr-server/requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt
COPY docker/sdr-server/server.py /app/server.py
EXPOSE 8090
CMD ["python", "/app/server.py"]
