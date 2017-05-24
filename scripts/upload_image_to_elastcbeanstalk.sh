#! /bin/bash
DOCKER_TAG=$1
DOCKERRUN_FILE="Dockerrun.aws.json"
BUILD=$DOCKER_USERNAME/
EB_BUCKET=$DEPLOYMENT_BUCKET/$BUCKET_DIRECTORY

# Replace vars in the DOCKERRUN_FILE 
cat "$DOCKERRUN_FILE.template" \
  | sed 's|<BUCKET>|'$EB_BUCKET'|g' \
  | sed 's|<IMAGE>|'$IMAGE_NAME'|g' \
  | sed 's|<TAG>|'$DOCKER_TAG'|g' \
  > $DOCKERRUN_FILE

echo "creating new Elastic Beanstalk version"

# Run aws command to create a new EB application with label
aws elasticbeanstalk create-application-version \
	--region=$DEPLOYMENT_REGION \
	--application-name $APP_NAME \
    --version-label $DOCKER_TAG \
	--source-bundle S3Bucket=$DEPLOYMENT_BUCKET,S3Key=$BUCKET_DIRECTORY/$DOCKERRUN_FILE

echo "updating Elastic Beanstalk environment"

aws elasticbeanstalk update-environment \
  --environment-name $DEPLOYMENT_ENV \
  --version-label $DOCKER_TAG