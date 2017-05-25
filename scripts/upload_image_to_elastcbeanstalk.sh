#! /bin/bash

# Variables
DOCKER_TAG=$1
DOCKERRUN_FILE="Dockerrun.aws.json"
DOCKERCFG=".dockercfg"

EB_BUCKET=$2
EB_ENV=$3
PREFIX="deploy/$DOCKER_TAG"

APP_NAME=$4
DEPLOYMENT_REGION=$5

IMAGE_NAME=$6

DEPLOYMENT_ENV_NAME=$7

# List files

ls ~/
ls ~/.docker/

# Generate dockercfg
DOCKER_AUTH=$( sed -n 's/.*"auth": "\(.*\)",/\1/p' /.docker/config.json)
DOCKER_EMAIL=$( sed -n 's/.*"email": "\(.*\)",/\1/p' /.docker/config.json)

cat "$DOCKERCFG" \
  | sed 's|<DOCKER_AUTH>|'$DOCKER_AUTH'|g' \
  | sed 's|<DOCKER_EMAIL>|'$DOCKER_EMAIL'|g' \
  > $DOCKERCFG

aws s3 cp $DOCKERCFG s3://$EB_BUCKET/$DOCKERCFG
rm $DOCKERCFG

echo "Creating Dockerrun.aws.json file"

# Replace vars in the DOCKERRUN_FILE 
cat "$DOCKERRUN_FILE" \
  | sed 's|<BUCKET>|'$EB_BUCKET'|g' \
  | sed 's|<IMAGE>|'$IMAGE_NAME'|g' \
  | sed 's|<TAG>|'$DOCKER_TAG'|g' \
  > $DOCKERRUN_FILE

aws s3 cp $DOCKERRUN_FILE s3://$EB_BUCKET/$PREFIX/$DOCKERRUN_FILE
rm $DOCKERRUN_FILE

echo "Creating new Elastic Beanstalk version"

# Run aws command to create a new EB application with label
aws elasticbeanstalk create-application-version \
	--region=$DEPLOYMENT_REGION \
	--application-name $APP_NAME \
  --version-label $DOCKER_TAG \
	--source-bundle S3Bucket=$EB_BUCKET,S3Key=$PREFIX/$DOCKERRUN_FILE

echo "Updating Elastic Beanstalk environment"

aws elasticbeanstalk update-environment \
  --environment-id $EB_ENV \
  --environment-name $DEPLOYMENT_ENV_NAME \
  --application-name $APP_NAME \
  --version-label $DOCKER_TAG