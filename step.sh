#!/bin/bash
trusted_certs=$(echo -ne $ftg_trusted_certs | sed 's/^\([[:alnum:]]\)/--trusted-cert \1/g' | tr '\n' ' ')

echo "Connecting to remote gateway $ftg_host:$ftg_port..."
sudo nohup openfortivpn "$ftg_host:$ftg_port" \
    --username $ftg_username \
    --password $ftg_password \
    $trusted_certs \
    --no-routes 2>&1 > "$ftg_logfile" &
retry_count=0
until fgrep -q "Tunnel is up" "$ftg_logfile" || [ $retry_count -eq 10 ]; do
    ((retry_count++))
    sleep 5
done

if [ ! -z "$ip_routes" ]; then
    echo "Setting routes..."
    cmd=
    options=
    if [ "$(uname)" == "Linux" ]; then
        cmd="ip route add"
        options="dev"
    else
        cmd="sudo route add"
        options="-interface"
    fi
    echo $ip_routes | while IFS= read -r ip; do
        eval "$cmd $ip $options ppp0"
    done
fi

echo "Appending entries to hosts file..."
echo -e "\n$ip_hosts" | sudo tee -a /etc/hosts