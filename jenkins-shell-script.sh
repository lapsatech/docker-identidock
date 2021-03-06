#DOCKER_CMD="docker"
DOCKER_CMD="sudo docker"

#COMPOSE_CMD="docker-compose"
COMPOSE_CMD="sudo docker-compose"

COMPOSE_ARGS=" -f jenkins.yml -p jenkins "

#Make sure old containers are gone
$COMPOSE_CMD $COMPOSE_ARGS stop
$COMPOSE_CMD $COMPOSE_ARGS rm --force -v

#build the system
$COMPOSE_CMD $COMPOSE_ARGS build --no-cache
$COMPOSE_CMD $COMPOSE_ARGS up -d

#Run unit tests
$COMPOSE_CMD $COMPOSE_ARGS run --no-deps --rm -e ENV=UNIT webapp
ERR=$?

#Run system test if unit tests passed
if [ $ERR -eq 0 ]; then
	IP=$($DOCKER_CMD inspect -f {{.NetworkSettings.IPAddress}} jenkins_webapp_1)
#	IP="localhost"
	CODE=$(curl -sL -w "%{http_code}" $IP:5000/monster/bla -o /dev/null) || true
	if [ $CODE -eq 200 ]; then
		HASH=$(git rev-parse --short HEAD)
		$DOCKER_CMD tag jenkins_webapp lapsatech/identidock-webapp:$HASH
		$DOCKER_CMD tag jenkins_webapp lapsatech/identidock-webapp:newest
		echo "Pushing"
		$DOCKER_CMD login -u lapsatech -p oreiily2018
		$DOCKER_CMD push lapsatech/identidock-webapp:$HASH
		$DOCKER_CMD push lapsatech/identidock-webapp:newest
	else
        echo "Site returned " $CODE
		ERR=1
	fi
fi

#Pull down the system
$COMPOSE_CMD $COMPOSE_ARGS stop
$COMPOSE_CMD $COMPOSE_ARGS rm --force -v

return $ERR