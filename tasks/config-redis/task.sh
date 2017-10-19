#!/bin/bash -e

set -x

#mv tool-om/om-linux-* tool-om/om-linux
chmod +x tool-om/om-linux
CMD=./tool-om/om-linux

RELEASE=`$CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k available-products | grep p-redis`

PRODUCT_NAME=`echo $RELEASE | cut -d"|" -f2 | tr -d " "`
PRODUCT_VERSION=`echo $RELEASE | cut -d"|" -f3 | tr -d " "`

$CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k stage-product -p $PRODUCT_NAME -v $PRODUCT_VERSION

function fn_other_azs {
  local azs_csv=$1
  echo $azs_csv | awk -F "," -v braceopen='{' -v braceclose='}' -v name='"name":' -v quote='"' -v OFS='"},{"name":"' '$1=$1 {print braceopen name quote $0 quote braceclose}'
}

OTHER_AZS=$(fn_other_azs $OTHER_JOB_AZS)

NETWORK=$(cat <<-EOF
{
  "singleton_availability_zone": {
    "name": "$SINGLETON_JOB_AZ"
  },
  "other_availability_zones": [
    "$OTHER_AZS"
  ],
  "network": {
    "name": "$NETWORK_NAME"
  },
  "service_network": {
    "name": "$SERVICE_NETWORK"
  }
}
EOF
)

PROPERTIES=$(cat <<-EOF
{
    ".redis-on-demand-broker.service_instance_limit": {
      "value": 0
    },
    ".properties.syslog_selector.active.syslog_address": {
      "value": "$SYSLOG_HOST"
    },
    ".properties.syslog_selector.active.syslog_port": {
      "value": "$SYSLOG_PORT"
    },
    ".properties.metrics_polling_interval": {
      "value": 30
    },
    ".properties.syslog_selector.active.syslog_transport": {
      "value": "tcp"
    },
    ".properties.backups_selector": {
      "value": "No Backups"
    },
    ".properties.small_plan_selector": {
       "value": "$SMALL_PLAN_STATUS"
    },
    ".properties.medium_plan_selector": {
      "value": "$MEDIUM_PLAN_STATUS"
    },
    ".properties.large_plan_selector": {
      "value": "$LARGE_PLAN_STATUS"
    }
}
EOF
)

RESOURCES=$(cat <<-EOF
{
}
EOF
)

$CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k configure-product -n $PRODUCT_NAME -p "$PROPERTIES" -pn "$NETWORK" -pr "$RESOURCES"
