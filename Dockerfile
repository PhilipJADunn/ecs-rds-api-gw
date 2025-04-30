FROM python:3.10-slim

WORKDIR /app

COPY /app/requirements.txt /app/

RUN pip install --no-cache-dir -r requirements.txt

COPY ./app /app/

RUN useradd -m appuser
USER appuser

EXPOSE 5000

CMD ["python", "app.py"]
