# syntax=docker/dockerfile:1
FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /srv/app

RUN pip install --no-cache-dir fastapi==0.115.8 uvicorn==0.30.6 numpy==2.1.3 pydantic==2.10.6

COPY app ./app
COPY schemas ./schemas

EXPOSE 8899
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8899"]
