#!/bin/bash

# given a string as parameter, log it along with the date/time
# $1 : string to add to log file
logger () {
	local log_phrase=$1
	
	local datetime=$(TZ=America/Chicago date +%F_%T_%Z)
	echo "$datetime : $log_phrase" >> $log_file
}


# search stdout from command for the provided substring
# $1 : name of return variable
# $2 : command to run that prints to stdout
# $3 : substring we're searching for
stdoutSubstring () {
	local __resultvar=$1
	local command=$2
	local substring=$3

	# count number of substring instances in stdout
	local match_count=$($command | grep -o "$substring" | wc -l )
	
	# if at least 1 match found, set return variable to true
	if [ $match_count -gt 0 ] ; then
		eval $__resultvar="true"
	else
		eval $__resultvar="false"
	fi
}

setupDockerAuth () {
	# check if Docker already authenticated
	
	local auth_uri_phrase_0=$account_id
	
	stdoutSubstring authenticated "cat /home/ec2-user/.docker/config.json" "$auth_uri_phrase_0"
	
	if ! $authenticated; then
		# share ECR creds with Docker
		logger "Authenticating Docker with AWS ECR Creds"
		aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $docker_ecr_uri
		#aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 618832047066.dkr.ecr.us-east-1.amazonaws.com
	fi
}

# TODO: choose process more selectively
stopDockerImage () {
	# choose 1 docker process to stop
	local process=$(docker ps -q -n -1)
	logger "   Stopping docker process $process"
	docker stop $process
}

# Start up docker image based on uri
# arg $1 : docker image uri we want to start
startDockerImage () {
	local image_uri=$1
	logger "   Starting docker image $image_uri"
	docker run -dp 80:15400 $image_uri
}

# Test if a new update was released, then download and install it
# arg $1 = uri we want to test for updates
updateDockerImage () {
	local image_uri=$1
	local no_updates_phrase="Image is up to date"
	
	stdoutSubstring status_quo "docker pull $image_uri" "$no_updates_phrase"
	
	# if latest tag has been updated in AWS EC2 Container Registry
	if ! $status_quo ; then
		logger "Updated image found"
		stopDockerImage
		startDockerImage "$image_uri"
		#startImageIfStopped "$image_uri"
	fi
}

# arg $1 : docker image uri of process to start
startImageIfStopped () {
	local image_uri=$1
	stdoutSubstring already_running "docker ps" "$image_uri"
	
	if ! $already_running ; then
		logger "Docker image wasn't running..."
		startDockerImage "$image_uri"
		/home/ec2-user/server_config/cron/update_ddns.sh
		# . ${BASH_SOURCE%/*}/update_ddn.sh
	fi
}

# ************************************* #
# ********** END OF FUNCTIONS **********#
# ************************************* #




account_id="618832047066"
image_name="bunkiez_server_docker"

docker_ecr_uri="$account_id.dkr.ecr.us-east-1.amazonaws.com"
docker_image_latest_uri="$docker_ecr_uri/$image_name:latest"

log_file="/home/ec2-user/server_config/logs/docker_image_updates.log"
# log_file="/home/ec2-user/logs/docker_image_updates.log"

#startDockerService
setupDockerAuth
startImageIfStopped "$docker_image_latest_uri"
updateDockerImage "$docker_image_latest_uri"

