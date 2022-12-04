reauthDockerCreds () {
	docker logout 618832047066.dkr.ecr.us-east-1.amazonaws.com
	aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 618832047066.dkr.ecr.us-east-1.amazonaws.com
}

reauthDockerCreds
