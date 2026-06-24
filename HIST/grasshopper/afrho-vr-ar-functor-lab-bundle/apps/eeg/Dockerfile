FROM python:3.12-slim
WORKDIR /app
COPY apps/eeg/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY apps/eeg ./apps/eeg
CMD ["python", "-m", "apps.eeg.bridge"]
