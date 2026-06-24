FROM python:3.12-slim
WORKDIR /app
COPY apps/mcp/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY apps/mcp ./apps/mcp
CMD ["python", "-m", "apps.mcp.server"]
