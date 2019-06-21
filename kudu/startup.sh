#!/bin/bash

#!/usr/bin/env bash

cat >/etc/motd <<EOL
    __ __          __      __    _ __     
   / //_/_  _ ____/ /_  __/ /   (_) /____ 
  / ,< / / / / __  / / / / /   / / __/ _ \
 
 / /| / /_/ / /_/ / /_/ / /___/ / /_/  __/
/_/ |_\__,_/\__,_/\__,_/_____/_/\__/\___/ 

                                          
DEBUG CONSOLE | AZURE APP SERVICE ON LINUX

Documentation: http://aka.ms/webapp-linux
Kudu Version : 1.0.0.6

EOL
cat /etc/motd

if [ $# -ne 5 ]; then
	echo "Missing parameters; exiting"
	exit 1
fi

if [ -z "${PORT}" ]; then
        export PORT=8181
fi

GROUP_ID=$1
GROUP_NAME=$2
USER_ID=$3
USER_NAME=$4
SITE_NAME=$5

groupadd -g $GROUP_ID $GROUP_NAME
useradd -u $USER_ID -g $GROUP_NAME $USER_NAME
chown -R $USER_NAME:$GROUP_NAME /tmp
mkdir -p /home/LogFiles/webssh

# Starting WebSSH on the port $KUDU_WEBSSH_PORT
sed -i -- "s/webssh-port-placeholder/$KUDU_WEBSSH_PORT/g" /opt/webssh/config.json
/bin/bash -c "benv node=9 npm=6 pm2 start /opt/webssh/index.js -o /home/LogFiles/webssh/pm2.log -e /home/LogFiles/webssh/pm2.err &"

export KUDU_RUN_USER="$USER_NAME"
export HOME=/home
export WEBSITE_SITE_NAME=$SITE_NAME
export APPSETTING_SCM_USE_LIBGIT2SHARP_REPOSITORY=0
export KUDU_APPPATH=/opt/Kudu
export APPDATA=/opt/Kudu/local

# Get environment variables to show up in SSH session
eval $(printenv | awk -F= '{print "export " $1"="$2 }' >> /etc/profile)

service ssh restart

cd /opt/Kudu

echo $(date) running .net core
ASPNETCORE_URLS=http://0.0.0.0:"$PORT" runuser -p -u "$USER_NAME" -- dotnet Kudu.Services.Web.dll
