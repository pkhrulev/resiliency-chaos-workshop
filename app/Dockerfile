FROM python:3.9-slim

COPY ./app.py ./requirements.txt ./

RUN pip install -r requirements.txt 

ENTRYPOINT ["python", "./app.py"]