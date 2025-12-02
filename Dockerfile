FROM python:3.10-slim

# Create working directory
WORKDIR /app

# Environment to avoid .pyc and ensure straight output
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY app.py .

# Expose Flask port
EXPOSE 5000

# Environment for Flask
ENV FLASK_APP=app.py
ENV FLASK_ENV=production

# Default command
CMD ["python", "app.py"]
