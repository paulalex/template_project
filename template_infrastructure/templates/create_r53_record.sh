# Route 53 setup
FQDN_NAME="${fqdn_name}"
R53_ZONE_ID="${r53_zone_id}"
PRIVATE_IP_ADDR=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

cat <<EOF | tee /tmp/route53.json
{"Changes":[{"Action": "UPSERT","ResourceRecordSet": {"Name": "$FQDN_NAME" ,"Type": "A","TTL": 60,"ResourceRecords": [{"Value": "$PRIVATE_IP_ADDR"}]}}]}
EOF
aws route53 change-resource-record-sets --hosted-zone-id $R53_ZONE_ID --change-batch file:///tmp/route53.json