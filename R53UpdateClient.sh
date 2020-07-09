#!/bin/bash
# Bash script will curl ifconfig.me for public ip, check against current dns record 
# and if WAN IPs are different, update .json config with the latest WAN IP
# and push route53 change via AWS CLI

echo "---***STARTING ROUTE53 UPDATE DDNS SCRIPT---***"

#VARIABLES
DOMAIN="<URL>"
ZONEID="<ZID>"
EXT_IP=$(curl http://ifconfig.me)
DNS_WAN_IP=$(dig +short $DOMAIN)

echo -e "\nToday is $(date)\n" #>> mywanip.txt
echo "QPI CURRENT WAN IP = ${EXT_IP}"
echo -e "$DOMAIN CURRENT WAN IP = ${DNS_WAN_IP}\n"

#if else statement to check if DNS WAN IP have changed

if [ "$EXT_IP" = "$DNS_WAN_IP" ]
#if [ 1 -eq 1 ]
then
 echo "QPI IP HAS NOT CHANGED, IT IS: $EXT_IP"
 echo "$DOMAIN IP HAS NOT CHANGED, IT IS: $DNS_WAN_IP"
 exit 1
else
 echo -e "--**IPS HAVE CHANGE**--D\nUPDATING AWS..."
 echo "cd too /home/pi/ddns/"
  cd /home/pi/ddns
cat > /home/pi/ddns/r53-update.json << __EOF__
  {
    "Changes": [
      {
        "Action": "UPSERT",
        "ResourceRecordSet": {
          "Name": "<URL>",
          "Type": "A",
          "TTL": 300,
          "ResourceRecords": [
            {
              "Value": "${EXT_IP}"
            }
          ]
        }
      }
    ]
  }
__EOF__
aws route53 change-resource-record-sets --hosted-zone-id $ZONEID --change-batch file://r53-update.json
fi


echo "DONE SCRIPT...exit"
exit 1
