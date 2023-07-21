# Required env vars
export API_KEY=OPEN_WEATHER_API_KEY
export API_ENDPOINT="https://api.openweathermap.org"
export CITY_ID=293397
export RDS_SECRET_NAME="/aws_ce/rds_secret"

# DB preparation
CREATE DATABASE weather_db;

CREATE TABLE weatherstatistics (
	time TIMESTAMP PRIMARY KEY,
	temp VARCHAR ( 50 ) NOT NULL,
	humidity VARCHAR ( 50 ) NOT NULL
);


# Run psql locally 
docker run  -e POSTGRES_PASSWORD=UberSecretPassword -e POSTGRES_USER=replica_postgresql postgres
docker run -it --rm  postgres psql -h 172.18.0.1 -U replica_postgresql


# Available endpoints
* / - resond with current weather, commits this data to DB
* /statistics - provides weather statistics from DB
* /ping - Just returns "pong" with code 200
* /health - Just returns "ok" with code 200

# How to deploy 
* Scale esagirov-ce-self-ondemand-a AG to 3 nodes
* Run kubectl apply -f deployment.yaml

# Build a container and push to ecr
Go to ./app directory

```
export ECR_REPO=<AWS_ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/aws-ce/app
aws ecr get-login-password --region <REGION> | docker login --username AWS --password-stdin $ECR_REPO

docker build . -t $ECR_REPO:<version>
docker push $ECR_REPO:<version>
```

# Create Openweather API account
1. Go to https://home.openweathermap.org/users/sign_up and register
2. Click on your username in the right top corner
3. Chose "My API Keys"
4. Create a key

