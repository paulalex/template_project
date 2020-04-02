az=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
region=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r .region)
ebsvolume=$(aws ec2 describe-volumes --filters Name=tag-value,Values="${volume_tag}" Name=availability-zone,Values=$${az} --query 'Volumes[*].[VolumeId, State==`available`]' --output text --region $${region} | grep True | awk '{print $1}' | head -n 1)

echo "[INFO] Retrieved following instance metadata from AWS meta-data API's"
echo "AZ: $${az}"
echo "Region: $${region}"
echo "EBS Volume: $${ebsvolume}"

if [ -n "$ebsvolume" ]; then

instanceid=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)

aws ec2 attach-volume --volume-id $(echo $ebsvolume) --instance-id $(echo $instanceid) --device ${device_path} --region $${region}

sleep 10

fi

vgchange -ay

DEVICE_FS=$(blkid -o value -s TYPE "${device_path}" || echo "")

if [ "$(echo -n "$${DEVICE_FS}")" == "" ] ; then
  # wait for the device to be attached
  DEVICENAME=$(echo "$${DEVICE}" | awk -F '/' '{print $3}')
  DEVICEEXISTS=''
  while [[ -z $${DEVICEEXISTS} ]]; do
    echo "checking $${DEVICENAME}"
    DEVICEEXISTS=$(lsblk | grep -c "$${DEVICENAME}")
    if [[ $${DEVICEEXISTS} != "1" ]]; then
      sleep 15
    fi
  done
  pvcreate "${device_path}"
  vgcreate data "${device_path}"
  lvcreate --name volume1 -l 100%FREE data
  mkfs.ext4 /dev/data/volume1
fi

mkdir -p /data
echo '/dev/data/volume1 /data ext4 defaults 0 0' >> /etc/fstab
mount /data