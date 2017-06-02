#! /bin/bash

# Variables
DOCKER_TAG=$1
DOCKERRUN_FILE="Dockerrun.aws.json"
DOCKERCFG=".dockercfg"
DOCKER_CONFIG="/home/travis/.docker/config.json"
EB_BUCKET=$2
EB_ENV=$3
PREFIX="deploy/$DOCKER_TAG"
APP_NAME=$4
DEPLOYMENT_REGION=$5
IMAGE_NAME=$6
DEPLOYMENT_ENV_NAME=$7
DOCKER_USERNAME=$8
DOCKER_REPOSITORY=$9
DOCKER_PASSWORD=${10}
DOCKER_EMAIL=${11}
DOCKER_IMAGE="$DOCKER_USERNAME/$DOCKER_REPOSITORY"

# List files
ls ~/
ls ~/.docker/
ls ~/.docker/config.json

# Generate dockercfg
echo "::::: Creating .dockercfg file :::::"

DOCKER_AUTH=($(sudo jq -r '.auths["https://index.docker.io/v1/"].auth' $DOCKER_CONFIG))

echo "//Auth value"
echo $DOCKER_AUTH
printf "\n"

echo "//Actual .docker/config.json"
sudo cat $DOCKER_CONFIG
printf "\n"

cat "$DOCKERCFG" \
  | sed 's|<DOCKER_AUTH>|'$DOCKER_AUTH'|g' \
  | sed 's|<DOCKER_USERNAME>|'$DOCKER_USERNAME'|g' \
  | sed 's|<DOCKER_PASSWORD>|'$DOCKER_PASSWORD'|g' \
  | sed 's|<DOCKER_EMAIL>|'$DOCKER_EMAIL'|g' \
  > $DOCKERCFG

sleep 30

echo "//Generated .dockerckfg"
cat $DOCKERCFG
printf "\n"

aws s3 cp $DOCKERCFG s3://$EB_BUCKET/.dockercfg
sleep 30

echo "::::: Creating Dockerrun.aws.json file :::::"

# Replace vars in the DOCKERRUN_FILE 
cat "$DOCKERRUN_FILE" \
  | sed 's|<BUCKET>|'$EB_BUCKET'|g' \
  | sed 's|<IMAGE>|'$DOCKER_IMAGE'|g' \
  | sed 's|<TAG>|'$DOCKER_TAG'|g' \
  > $DOCKERRUN_FILE

sleep 30

echo "//Generated Dockerrun.aws.json"
cat $DOCKERRUN_FILE
printf "\n"

aws s3 cp $DOCKERRUN_FILE s3://$EB_BUCKET/$PREFIX/$DOCKERRUN_FILE
sleep 30

echo "::::: Creating new Elastic Beanstalk version :::::"

# Run aws command to create a new EB application with label
aws elasticbeanstalk create-application-version \
	--region=$DEPLOYMENT_REGION \
	--application-name $APP_NAME \
  --version-label $DOCKER_TAG \
	--source-bundle S3Bucket=$EB_BUCKET,S3Key=$PREFIX/$DOCKERRUN_FILE
  
sleep 30  

echo "::::: Updating Elastic Beanstalk environment :::::"

aws elasticbeanstalk update-environment \
  --environment-id $EB_ENV \
  --environment-name $DEPLOYMENT_ENV_NAME \
  --application-name $APP_NAME \
  --version-label $DOCKER_TAG

echo "::::: Removing file :::::"

sleep 30  
rm $DOCKERCFG
rm $DOCKERRUN_FILE

echo "::::: Describing application :::::"

aws elasticbeanstalk describe-application-versions 
  --application-name $APP_NAME
  --version-label $DOCKER_TAG

# Display info

echo "::::: Describing environment :::::"

aws elasticbeanstalk describe-environments 
  --environment-names $DEPLOYMENT_ENV_NAME

echo "::::: Describing application :::::"

aws elasticbeanstalk describe-applications \
  --application-names $APP_NAME

echo "::::: Describing environment events :::::"

aws elasticbeanstalk describe-events
  --environment-name $DEPLOYMENT_ENV_NAME \