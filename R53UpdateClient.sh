#!/bin/bash
# Bash script will curl ifconfig.me for public ip, check against current dns record 
# and if WAN IPs are different, update .json config with the latest WAN IP
# and push route53 change via AWS CLI


#VARIABLES
DOMAIN="qpitor.saadqazi.com" #my.domain.com
ZONEID="<ZID>" #L6M2KA4YKHWS 
EXT_IP=$(dig +short myip.opendns.com @resolver1.opendns.com)
DOMAIN_IP=$(dig +short $DOMAIN)
LOG=awsndslogs.txt
DIR=$(pwd)


echo "---*** STARTING ROUTE53 DNS UPDATE SCRIPT ---***" >>$LOG
echo -e " Today is: $(date) " >> $LOG
echo " RPI CURRENT WAN IP = ${EXT_IP} " >> $LOG
echo -e " $DOMAIN CURRENT WAN IP = ${DOMAIN_IP} " >> $LOG

#if else statement to check if DNS WAN IP have changed

if [ "1.1.1.1" = "$DOMAIN_IP" ]
#if [ 1 -eq 1 ]
then
 echo "NO CHANGE IN IP ADDR...EXITING SCRIPT!" >> $LOG
 echo "RPI IP HAS NOT CHANGED, IT IS: $EXT_IP" | 
 echo "$DOMAIN IP HAS NOT CHANGED, IT IS: $DOMAIN_IP"
 exit 1
else
 echo "YES CHANGE IN IP ADDR!"
 echo -e "IPS HAVE CHANGED! UPDATING AWS..." >> $LOG
 echo "cd $DIR"
 cd $DIR
cat > $DIR/r53-update.json << __EOF__
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
echo "aws cmd ran!"
fi
echo "DONE SCRIPT...exit"
exit 1
