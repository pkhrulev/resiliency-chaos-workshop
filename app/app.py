import flask
import requests
from flask import jsonify
import logging
import sys
import os
import psycopg2
import boto3
import json
from datetime import datetime
from json2html import *





# Instantiate flask
app = flask.Flask(__name__)

# Init basic logger. Output - stdout
logging.basicConfig(stream=sys.stdout, level=logging.INFO)

# Init PSQL connection
def init_sql_connection():
    connection_data = get_aws_secret(os.getenv('RDS_SECRET_NAME'))

    conn =  psycopg2.connect("postgresql://{}:{}@{}:{}/weather_db".format(connection_data['user'], connection_data['password'], connection_data['host'], connection_data['port']))
    # conn =  psycopg2.connect("postgresql://{}:{}@{}:{}/weather_db".format("replica_postgresql", "UberSecretPassword", "172.18.0.1", "5432"))

    return conn


def get_aws_secret(secret_id):
    session = boto3.session.Session(region_name="eu-west-1" )
    client = session.client('secretsmanager')

    response = client.get_secret_value(
        SecretId=secret_id
    )

    return json.loads(response['SecretString'])

def get_current_time():
    # datetime object containing current date and time
    now = datetime.now()
    
    # dd/mm/YY H:M:S
    # dt_string = now.strftime("%m/%d/%Y %H:%M:%S")
    return now

def commit_data(temp, humidity):
    cur = psql_conn.cursor()

    cur.execute("INSERT INTO weatherstatistics (time, temp, humidity) VALUES (%s, %s, %s)",  (get_current_time(), temp, humidity))
    
    psql_conn.commit()
    cur.close()


"""
Routes definition
"""
@app.route('/ping', methods=['GET'])
def pong():
    """
    Returns HTML "PONG" response
    """
    return "PONg"

# Home resource. 
@app.route('/', methods=['GET'])
def get_current_weather():
    """
    Returns current weather information in HTML format.
    """
    # Get required params from env
    api_key = os.getenv('API_KEY')
    api_endpoint = os.getenv('API_ENDPOINT')
    city_id = os.getenv('CITY_ID')

    """
    Gather parameters required for an api call.
    :param id: City identifier 
    :param appid: API key  
    :param units: Units identifier(metrics - returns temperature in celsius) 
    """
    params={
        'id': city_id,
        'appid': api_key,
        'units': 'metrics' 
        }

    # Make request to weather info source
    r = requests.get(f"{api_endpoint}/data/2.5/weather?id={city_id}&appid={api_key}&units=metric")

    # Basic error handling. Returns standard response to a client in case if weather information source response code isn't equal 200 
    if r.status_code == 200:
        response=r.json()
        data = f"""
        <!DOCTYPE html>
        <html>
          <body>
            <h1>Current weather in Tel Aviv, Israel</h1>
            <ul>
              <li><b>General description:</b> {response["weather"][0]["main"]}</li>
              <li><b>Temperature:</b> {response["main"]["temp"]} °C</li>
              <li><b>Feels like:</b> {response["main"]["feels_like"]} °C</li>
              <li><b>Humidity:</b> {response["main"]["humidity"]}%</li>
            </ul>
          </body>
        </html>
        """
        commit_data(response["main"]["temp"], response["main"]["humidity"])

        return data
    else:
        logging.warning(f"Response code - {r.status_code}, Error message: {r.reason}")
        return """
        <!DOCTYPE html>
        <html>
          <body>
            <h1>Sorry, current weather is unavailable. Please try again later.</h1>
          </body>
        </html>
        """

@app.route('/statistics', methods=['GET'])
def get_statistics():
    """
    Returns "Ok" 200 in JSON format
    """
    cur = psql_conn.cursor() 

    cur.execute("SELECT * FROM weatherstatistics;")
    data = cur.fetchall()
    
    return jsonify(data)

@app.route('/health', methods=['GET'])
def get_health():
    """
    Returns "Ok" 200 in JSON format
    """
    return jsonify("Ok")


if __name__ == '__main__':
    try:
        psql_conn = init_sql_connection()
        app.run(debug=True, host='0.0.0.0', port="8080")
    except Exception as err:
        print(err)



