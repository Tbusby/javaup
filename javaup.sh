#!/bin/bash
# 
# Upgrade java from 7 to 8 

# Check if running as root
if [[ $EUID -ne 0 ]]; then 
    echo "##### This script needs to run as root"
    exit
fi


# Check current java version 
echo "##### Checking Java verison"
if [[ $(java -version 2>&1 | grep "1.7") ]]; then
    echo "You are running java 1.7."
    echo "You will be upgraded to 1.8"
else
    echo "You are not running java 1.7"
    echo "Closing"
    exit
fi


# Download java 8 jdk
echo "##### Downloading Java"
cd /tmp/
wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/8u45-b14/jdk-8u45-linux-x64.tar.gz


# Unpack and install to correct location
echo "##### Unpacking java"
tar -zxvf jdk-8u45-linux-x64.tar.gz

echo "##### Moving java 8 to /usr/lib/jvm"
mv -v jdk1.8.0_45 /usr/lib/jvm/


# Install on upgrade-alternatives
echo "#####Installing java 8 on upgrade-alternatives"
update-alternatives --install /usr/bin/java java /usr/lib/jvm/jdk1.8.0_45/bin/java 1


# Stop running apps 
echo "##### Shutting down services"
for SERVICE in $(ls -l /etc/init | grep "avst-app.*.debian" | awk '{print $9}' | sed 's/.conf//g'); do 
    echo Shutting down service = $SERVICE
    service $SERVICE stop 
done

echo "##### All Services stopped"


# Change java used by upgrade-alternatives
echo "##### Changing in use java to java 8"
update-alternatives --set java /usr/lib/jvm/jdk1.8.0_45/bin/java


# Check new java version is taking
echo "##### Your current java is"
java -version
if [[ $(java -version 2>&1 | grep "1.8") ]]; then
    echo "Java is on 1.8"
else 
    echo "Something went wrong setting java to 1.8"
    exit 1
fi

# Edit apps java settings for 8 compatibility 
echo "##### Changing java settings in apps"
# need to set bash to posix mode to disable shell expansion 
set -o posix    

for SERVICE in $(ls -l /etc/init | grep "avst-app.*.debian" | awk '{print $9}' | sed 's/.conf//g'); do 
    cd /opt/$SERVICE/

    # Start of java args replacements (Add to this as new ones are found)
    sed -i "s/'\$( date '+%Y%m%d-%T' )'/%t/g" avst-app.cfg.sh
    sed -i 's/-XX:InitialTenuringThreshold=[.0-9][.0-9]/-XX:InitialTenuringThreshold=15/g' avst-app.cfg.sh
    sed -i 's/-XX:MaxTenuringThreshold=[.0-9][.0-9]/-XX:MaxTenuringThreshold=15/g' avst-app.cfg.sh
    sed -i 's/-XX:+UseCompressedStrings//g' avst-app.cfg.sh

done

    
# Avst-app modify 
echo "##### Avst-app modify"
for SERVICE in $(ls -l /etc/init | grep "avst-app.*.debian" | awk '{print $9}' | sed 's/.conf//g'); do 
    echo Shutting down service = $SERVICE
    avst-app $SERVICE modify; 
done


# Restart apps 
echo "##### Restart apps"
for SERVICE in $(ls -l /etc/init | grep "avst-app.*.debian" | awk '{print $9}' | sed 's/.conf//g'); do 
    echo Restarting service = $SERVICE
    service $SERVICE start; 
done




