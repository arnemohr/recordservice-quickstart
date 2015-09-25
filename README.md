# RSQuickstart

## Prerequisites
1. Install VirtualBox. The vm has been tested to work with VirtualBox version 4.3 on Ubuntu 14.04 and VirtualBox version 5 on OSX 10.9. Download VirtualBox for free at https://www.virtualbox.org/wiki/Downloads. VirtualBox is also included in most package managers: apt-get, brew, etc.
2. Download or build the RecordServiceClient code. You can checkout and build the client code here. Building the code is quick and simple.

## Install RecordService VM
Naviagte to the root of the RSQuickstart git repository and run

    install.sh

This script downloads an ova file and loads it into VirtualBox. The script might ask you for your password because it adds a line to your /etc/hosts file to give the vm a stable ip address, quickstart.cloudera. To test that the vm is running and that ip forwarding has been successfully configured, try ssh-ing to the machine with the command

    ssh cloudera@quickstart.cloudera
    # The password is cloudera
    logout
    # We're just checking to make sure that we can login. Feel free to play around on the
    # vm but the instructions below should all be executed on your host machine

If you are unable to ssh to the vm, refer to the section below Troubleshooting the VM Configuration.
Run

    source vm_env.sh

This script configures a few enviroment variables that need to be set to allow the tests to run

    cd $RECORD_SERVICE_HOME
    source config.sh
    cd java/
    mvn test -DargLine="-Duser.name=recordservice"

This executes our tests. The vm has been preconfigured with the data needed to execute the tests. The recordservice user has been granted access to the necessary data with sentry.

The vm is not secured with LDAP or kerberos in order to make getting started playing around with RecordService simpler. If you want to play with security configurations you can add roles in sentry through the impala-shell. If you have the impala-shell on your host machine you can connect to the vm by issuing the command

    impala-shell -i quickstart.cloudera:21000 -u impala
    # or from within the impala-shell
    CONNECT quickstart.cloudera:21000;


## Troubleshooting the VM Configuration
#### Unable to Ssh to the VM
1. Ensure that the ssh daemon is running on your machine
2. Ensure that the RecordService vm is running. Run the command below. You should see "rs-demo" listed as a running virtual machine.
```
    VBoxManage list runningvms
```
3. Verify that the vm's ip address is properly listed in your /etc/hosts file. In /etc/hosts you should see a line that lists an ip followed by quickstart.cloudera. You can check the vm's ip with the following command
```
    VBoxManage guestproperty get rs-demo /VirtualBox/GuestInfo/Net/0/V4/IP
```
4. If you've used a Cloudera quickstart vm before, it's possible that your known hosts file already has an entry for quickstart.cloudera registered to a different key. Delete any reference to quickstart.cloudera from your known hosts file, usually found in ~/.ssh/known_hosts.