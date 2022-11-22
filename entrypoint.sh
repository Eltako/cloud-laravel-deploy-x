
#!/bin/bash

SSH_USER=$1
SSH_HOST=$2
SSH_PORT=$3
PATH_TARGET=$4
PATH_SOURCE=$5
OWNER=$6
USE_ARTISAN=$7
COMMANDS=$8

mkdir -p /root/.ssh
ssh-keyscan -H "$SSH_HOST" >> /root/.ssh/known_hosts

if [ -z "$DEPLOY_KEY" ];
then
	echo $'\n' "------ DEPLOY KEY NOT SET YET! ----------------" $'\n'
	exit 1
else
	printf '%b\n' "$DEPLOY_KEY" > /root/.ssh/id_rsa
	chmod 400 /root/.ssh/id_rsa

	echo $'\n' "------ CONFIG SUCCESSFUL! ---------------------" $'\n'
fi

if [ ! -z "$SSH_PORT" ];
then
  printf "Host %b\n\tPort %b\n" "$SSH_HOST" "$SSH_PORT" > /root/.ssh/config
	ssh-keyscan -p $SSH_PORT -H "$SSH_HOST" >> /root/.ssh/known_hosts
fi

rsync --progress -avzh \
	--exclude='.git/' \
	--exclude='.git*' \
	--exclude='.editorconfig' \
	--exclude='.styleci.yml' \
	--exclude='.idea/' \
	--exclude='Dockerfile' \
	--exclude='readme.md' \
	--exclude='README.md' \
	-e "ssh -i /root/.ssh/id_rsa" $PATH_SOURCE \
	$SSH_USER@$SSH_HOST:$PATH_TARGET \
	--delete

if [ $? -eq 0 ]
then
	echo $'\n' "------ SYNC SUCCESSFUL! -----------------------" $'\n'
	echo $'\n' "------ RELOADING PERMISSION -------------------" $'\n'

	# ssh -i /root/.ssh/id_rsa -t $SSH_USER@$SSH_HOST "sudo chown -R $OWNER:$OWNER $PATH_TARGET"
	# ssh -i /root/.ssh/id_rsa -t $SSH_USER@$SSH_HOST "sudo chmod 775 -R $PATH_TARGET"
	# ssh -i /root/.ssh/id_rsa -t $SSH_USER@$SSH_HOST "sudo chmod 777 -R $PATH_TARGET/storage"
	# ssh -i /root/.ssh/id_rsa -t $SSH_USER@$SSH_HOST "sudo chmod 777 -R $PATH_TARGET/public"

	if [ "$USE_ARTISAN" -eq 1 ]
	then
		ssh -i /root/.ssh/id_rsa -t $SSH_USER@$SSH_HOST "cd $PATH_TARGET && php artisan migrate && php artisan cache:clear && php artisan route:cache && php artisan config:cache"
	fi

	if [ ! -z "$COMMANDS" ];
	then
		ssh -i /root/.ssh/id_rsa -t $SSH_USER@$SSH_HOST "cd $PATH_TARGET && $COMMANDS"
	fi

	echo $'\n' "------ CONGRATS! DEPLOY SUCCESSFUL!!! ---------" $'\n'
	exit 0
else
	echo $'\n' "------ DEPLOY FAILED! -------------------------" $'\n'
	exit 1
fi
