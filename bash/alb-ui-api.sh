#!/bin/bash
#
alb_api () {
  # $1 is the amount of retry
  # $2 is the time to pause between each retry
  # $3 type of HTTP method (GET, POST, PUT, PATCH, DELETE)
  # $4 cookie file
  # $5 http header X-CSRFToken:
  # $6 http header X-Avi-Tenant:
  # $7 http header X-Avi-Version:
  # $8 http data
  # $9 ALB Controller IP
  # $10 API endpoint
  retry=$1
  pause=$2
  attempt=0
  echo "  HTTP ${3} API call to https://${9}/${10}"
  while true ; do
    response=$(curl -k -s -X "${3}" --write-out "\n\n%{http_code}" -b "${4}" -H "X-CSRFToken: ${5}" -H "X-Avi-Tenant: ${6}" -H "X-Avi-Version: ${7}" -H "Content-Type: application/json" -H "Referer: https://${9}" -d "${8}" https://${9}/${10})
#    sleep 2
    response_body=$(sed '$ d' <<< "$response")
    response_code=$(tail -n1 <<< "$response")
#    echo $response_body
#    echo $response_code
    if [[ $response_code == 2[0-9][0-9] ]] ; then
      echo "    API call was successful"
      break
    else
      echo "    API call, http response code: $response_code, attempt: $attempt"
    fi
    if [ $attempt -eq $retry ]; then
      echo "    FAILED HTTP ${3} API call to https://${9}/${10}, response code was: $response_code"
      echo "$response_body"
      exit 255
    fi
    sleep $pause
    ((attempt++))
  done
}
#
git clone https://github.com/tacobayle/alb-ui-api
jsonFile="/home/ubuntu/alb-ui-api/json/data.json"
# updating API IP in alb-ui-api/html/lbaas/script.js
ifPrimary=$(ip route | grep default | sed -e "s/^.*dev.//" -e "s/.proto.*//")
ip=$(ip address show dev $ifPrimary | grep -v inet6 | grep inet | awk '{print $2}' | cut -d"/" -f1)
sed -e "s/\${ip_api}/${ip}/" alb-ui-api/html/lbaas/script.js.template | tee alb-ui-api/html/lbaas/script.js > /dev/null
# moving gslb_geo_db to the apache directory
sudo mkdir /var/www/html/gslb-db
sudo cp /home/ubuntu/geo.txt /var/www/html/gslb-db/geo.txt
sudo cp /home/ubuntu/geo.txt.gz /var/www/html/gslb-db/geo.txt.gz
#
controller_dc1=$(yq -c -r '.controllerPrivateIps' /home/ubuntu/avi_vcenter_yaml_values.yml | jq -c -r .[0])
version_dc1=$(yq -c -r '.avi_version' /home/ubuntu/avi_vcenter_yaml_values.yml)
password_dc1=$(yq -c -r '.avi_password' /home/ubuntu/avi_vcenter_yaml_values.yml)
controller_dc2=$(yq -c -r '.controllerPrivateIps' /home/ubuntu/dc2.yml | jq -c -r .[0])
version_dc2=$(yq -c -r '.avi_version' /home/ubuntu/dc2.yml)
password_dc2=$(yq -c -r '.avi_password' /home/ubuntu/dc2.yml)
mv $jsonFile /home/ubuntu/alb-ui-api/json/data.json.old
new_json=$(jq '.datacenters[0] += {"controller_ip": "'${controller_dc1}'"}' /home/ubuntu/alb-ui-api/json/data.json.old)
new_json=$(echo $new_json | jq '.gslb += {"gslb_leader": "'${controller_dc1}'"}')
new_json=$(echo $new_json | jq '.datacenters[0] += {"version": "'${version_dc1}'"}')
#
new_json=$(echo $new_json | jq '.datacenters[1] += {"controller_ip": "'${controller_dc2}'"}')
new_json=$(echo $new_json | jq '.datacenters[1] += {"version": "'${version_dc2}'"}')

#
# update token for dc1
#
rm -f avi_cookie.txt
curl_login=$(curl -s -k -X POST -H "Content-Type: application/json" \
                                -d "{\"username\": \"automation\", \"password\": \"${password_dc1}\"}" \
                                -c avi_cookie.txt https://${controller_dc1}/login)
csrftoken=$(cat avi_cookie.txt | grep csrftoken | awk '{print $7}')
alb_api 2 1 "POST" "avi_cookie.txt" "${csrftoken}" "admin" "" "{\"hours\": 360}" "${controller_dc1}" "api/user-token"
if [[ $response_code == 2[0-9][0-9] ]] ; then
  token=$(echo $response_body | jq -c -r .token)
  new_json=$(echo $new_json | jq '.datacenters[0] += {"password": "'${token}'"}')
fi
#
# update token for dc2
#
rm -f avi_cookie.txt
curl_login=$(curl -s -k -X POST -H "Content-Type: application/json" \
                                -d "{\"username\": \"automation\", \"password\": \"${password_dc2}\"}" \
                                -c avi_cookie.txt https://${controller_dc2}/login)
csrftoken=$(cat avi_cookie.txt | grep csrftoken | awk '{print $7}')
alb_api 2 1 "POST" "avi_cookie.txt" "${csrftoken}" "admin" "" "{\"hours\": 360}" "${controller_dc2}" "api/user-token"
if [[ $response_code == 2[0-9][0-9] ]] ; then
  token=$(echo $response_body | jq -c -r .token)
  new_json=$(echo $new_json | jq '.datacenters[1] += {"password": "'${token}'"}')
fi
#
echo $new_json | jq . | tee $jsonFile
#
#
#
echo '
#!/bin/bash
#
python3 /home/ubuntu/alb-ui-api/main_lbaas.py
' | sudo tee /usr/bin/alb-ui-api.sh
#
echo '
[Unit]
Description=alb-ui-api

[Service]
Type=simple
ExecStart=/bin/bash /usr/bin/alb-ui-api.sh

[Install]
WantedBy=multi-user.target
' | sudo tee /etc/systemd/system/alb-ui-api.service
#
sudo chmod 644 /etc/systemd/system/alb-ui-api.service
#
sudo systemctl start alb-ui-api
sudo systemctl enable alb-ui-api
sudo mv /var/www/html/index.html /var/www/html/index.html.old
sudo cp -R /home/ubuntu/alb-ui-api/html /var/www/