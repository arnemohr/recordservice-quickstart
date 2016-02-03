# Copyright 2015 Cloudera Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#!/bin/bash
set -eu

# http://stackoverflow.com/questions/7126580/expand-a-possible-relative-path-in-bash
dir_resolve()
{
  cd "$1" 2>/dev/null || return $?
  echo "`pwd -P`"
}

: ${VIRTUALBOX_URL:=https://s3-us-west-1.amazonaws.com/recordservice-vm/rs-demo.ova}
: ${VIRTUALBOX_NAME:=rs-demo}

# VM Settings default.
: ${VM_NAME:=rs-demo}
: ${VM_NUM_CPUS:=2}
: ${VM_MEM_MB:=6144}

if ! which VBoxManage >/dev/null ; then
  echo "It appears that virtualbox is not installed. VBoxManage is not"
  echo "on the path. If running on Ubuntu, run apt-get -y install virtualbox"
  exit 1
fi

# echo "Downloading the VM"
# scp vd0230.halxg.cloudera.com:/tmp/rs-demo.ova .

# Download quickstart VM
if [ -f ${VIRTUALBOX_NAME}.ova ]; then
  echo Using previously downloaded image
else
  echo "Downloading Virtualbox Image file: ${VIRTUALBOX_URL}"
  curl -O ${VIRTUALBOX_URL}
fi

OVF=${VIRTUALBOX_NAME}.ova

# Create a host only network interface
VBoxManage hostonlyif create

# Find the last one created
last_if=`VBoxManage list -l hostonlyifs | grep "^Name:" | tail -n 1 | tr " " "\n" | tail -n 1`
host_ip=`VBoxManage list -l hostonlyifs | grep "^IPAddress:" | tail -n 1 | tr " " "\n" | tail -n 1`

lower_ip=`echo $host_ip | sed 's/\([0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\)\.[0-9]\{1,3\}/\1/g'`

VBoxManage hostonlyif ipconfig $last_if --ip $host_ip
VBoxManage dhcpserver add --ifname $last_if --ip $host_ip --netmask 255.255.255.0 --lowerip $lower_ip.100 --upperip $lower_ip.200 || :
VBoxManage dhcpserver modify --ifname $last_if --enable

# Import the ovf
VBoxManage import ${OVF} --vsys 0 --cpus ${VM_NUM_CPUS} --memory ${VM_MEM_MB} --vmname ${VM_NAME} --options keepallmacs
VBoxManage modifyvm ${VM_NAME} --nic1 hostonly
VBoxManage modifyvm ${VM_NAME} --hostonlyadapter1 $last_if
VBoxManage modifyvm ${VM_NAME} --nic2 nat

# Start the VM
VBoxManage startvm ${VM_NAME}

echo "Waiting until services are up and running"
# Wait until we can access the DFS
sleep 100
while true; do
    val=`VBoxManage guestproperty get $VM_NAME "/VirtualBox/GuestInfo/Net/0/V4/IP"`
    if [[ $val != "No value set!" ]]; then
	ip=`echo $val | awk '{ print $2 }'`
	curl http://$ip:50070/ &> /dev/null || :
	if [[ $? -eq 0 ]]; then
	    break
	fi
    fi
    sleep 5
done

if ! grep -q quickstart.cloudera /etc/hosts ; then
echo "Updating the /etc/hosts file requires sudo rights."
sudo bash -e -c 'echo "#Cloudera Quickstart VM" >> /etc/hosts'
sudo bash -c "echo $ip quickstart.cloudera >> /etc/hosts"
else
echo "Hostname setup already done, check if the IP address of the VM"
echo "matches the hosts entry."
echo "IP VM: $ip"
cat /etc/hosts
fi

export RECORD_SERVICE_QUICKSTART_VM=True
export MAVEN_OPTS="-Xmx2g -XX:MaxPermSize=512M -XX:ReservedCodeCacheSize=512m "
export RECORD_SERVICE_PLANNER_HOST=quickstart.cloudera

echo "========================================================================="
echo "Cloudera Quickstart RecordService VM installed successfully"
echo ""
echo "If you sourced this script, the VM should be running and the"
echo "RECORD_SERVICE_PLANNER_HOST variable has been set to quickstart.cloudera"
echo "which points your client to the VM."
echo ""
echo "To ssh to the VM, ssh cloudera@quickstart.cloudera password is cloudera"
echo ""
