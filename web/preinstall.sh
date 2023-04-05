#!/bin/sh


getent group sensu > /dev/null
missing_group=$?

if [ $missing_group != "0" ]; then
  groupadd -r sensu
fi

getent passwd sensu > /dev/null
missing_user=$?

if [ $missing_user != "0" ]; then
  useradd -r -g sensu -d /opt/sensu -s /bin/false -c "Sensu Monitoring Framework" sensu
fi
