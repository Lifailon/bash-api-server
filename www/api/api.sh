#!/bin/bash
function list-units {
    service_name=$1
    service_list=$(systemctl list-units --all --type=service --plain --no-legend --no-pager --output=json | jq --arg service_name "$service_name" '
        .[] | select(.unit | test($service_name))
    ')
    for unit in $(echo $service_list | jq -r .unit); do
        uptime=$(systemctl status $unit 2>/dev/null | grep -P "Active:.+;" | sed -r "s/.+; | ago//g")
        startup=$(systemctl status $unit 2>/dev/null } | grep -oP "enabled|disabled" | head -n 1)
        echo $service_list | jq --arg unit "$unit" --arg uptime "$uptime" --arg startup "$startup" '
            . | select (.unit == $unit) + {uptime: $uptime, startup: $startup}
        '
    done
}

if [ "$REQUEST_METHOD" == "GET" -a "$REQUEST_URI" == "/api/info" ]; then
    echo "Content-type: application/json"
    echo
    read -n $CONTENT_LENGTH POST_DATA
    request=$(
        echo {\"method\": \"$REQUEST_METHOD\", \"url\": \"$REQUEST_URI\"}
    )
    client=$(
        echo {\"address\": \"$REMOTE_ADDR\", \"port\": \"$REMOTE_PORT\", \"agent\": \"$HTTP_USER_AGENT\", \"type_auth\": \"$AUTH_TYPE\", \"user\": \"$REMOTE_USER\"}
    )
    server=$(
        echo {\"address\": \"$SERVER_NAME\", \"port\": \"$SERVER_PORT\", \"version\": \"$SERVER_SOFTWARE\", \"protocol\": \"$SERVER_PROTOCOL\"}
    )
    content=$(
        echo {\"type\": \"$CONTENT_TYPE\", \"length\": \"$CONTENT_LENGTH\", \"body\": \"$POST_DATA\", \"status\": \"$HTTP_STATUS\"}
    )
    response=$(
        echo {\"request\": [$request], \"client\": [$client], \"server\": [$server], \"content\": [$content]}
    )
    echo $response | jq .
elif [ "$REQUEST_METHOD" == "GET" -a "$REQUEST_URI" == "/api/uptime" ]; then
    echo "Content-type: text/plain"
    echo
    uptime -p | sed "s/up //" | awk -F "," '{print $1,$2,$3}'
elif [ "$REQUEST_METHOD" == "GET" -a "$REQUEST_URI" == "/api/disk" ]; then
    echo "Content-type: application/json"
    echo
    lsblk -e7 -f --json | jq .
elif [ "$REQUEST_METHOD" == "GET" ] && [ "$REQUEST_URI" == "/api/service" ] && echo "$HTTP_USER_AGENT" | grep -q "Chrome"; then
    response=$(systemctl list-units --all --type=service --plain --no-legend --no-pager --output=json)
    echo "Content-type: text/html"
    echo
    echo "<html>"
    echo "<head>"
    echo "<title>Service list</title>"
    echo "</head>"
    echo "<body>"
    echo "<table border=\"1\">"
    echo "<tr>"
    echo "<th>Unit</th>"
    echo "<th>Load</th>"
    echo "<th>Active</th>"
    echo "<th>Sub</th>"
    echo "<th>Description</th>"
    echo "</tr>"
    echo "$response" | jq -r '.[] | "<tr><td>\(.unit)</td><td>\(.load)</td><td>\(.active)</td><td>\(.sub)</td><td>\(.description)</td></tr>"'
    echo "</table>"
    echo "</body>"
    echo "</html>"
elif [ "$REQUEST_METHOD" == "GET" -a "$REQUEST_URI" == "/api/service" ]; then
    response=$(systemctl list-units --all --type=service --plain --no-legend --no-pager --output=json)
    echo "Content-type: application/json"
    echo
    echo $response | jq .
elif [ "$REQUEST_METHOD" == "GET" ] && echo "$REQUEST_URI" | grep -qP "/api/service/.+"; then
    echo "Content-type: application/json"
    echo
    service_name=$(echo $REQUEST_URI | sed -r "s/.+\///g")
    service_list=$(list-units "$service_name")
    if [ $(echo $service_list | wc -w) -eq 0 ]; then
        echo Service $service_name not found
    else
        echo $service_list | jq .
    fi
elif [ "$REQUEST_METHOD" == "POST" ] && echo "$REQUEST_URI" | grep -qP "/api/service/.+"; then
    # echo "www-data ALL=(ALL) NOPASSWD: /bin/systemctl start *, /bin/systemctl stop *, /bin/systemctl restart *" >> /etc/sudoers
    echo "Content-type: application/json"
    echo
    service_name=$(echo $REQUEST_URI | sed -r "s/.+\///g")
    service_list=$(list-units "$service_name")
    if [ $(echo $service_list | jq .unit | wc -l) -ne 1 ]; then
        echo "Bad request. Only one service can be transferred."
    else
        if [ "$HTTP_STATUS" = "stop" ] || [ "$HTTP_STATUS" = "start" ] || [ "$HTTP_STATUS" = "restart" ]; then
            sudo systemctl $HTTP_STATUS $(echo $service_list | jq -r .unit)
            list-units "$service_name"
        else
            echo "Bad request. You need to pass the service Status in the request header: stop, start or restart."
        fi
    fi
elif [ "$REQUEST_METHOD" != "GET" ]; then
    echo "Content-type: text/plain"
    echo
    echo "Method not supported"
else
    echo "Content-type: text/plain"
    echo
    echo "Endpoint $REQUEST_URI not found"
fi