#!/bin/bash
echo "# 0. Install prerequests"
sudo yum install -y wget

# echo "# 1. Configure Cloudera Repo"
sudo wget https://archive.cloudera.com/cm6/6.3.0/redhat7/yum/cloudera-manager.repo -P /etc/yum.repos.d/
sudo rpm --import https://archive.cloudera.com/cm6/6.3.0/redhat7/yum/RPM-GPG-KEY-cloudera

# echo "# 2. Install JDK"
sudo yum install -y oracle-j2sdk1.8

echo "# 3. Install Cloudera Manager Packages"
sudo yum install -y cloudera-manager-daemons cloudera-manager-agent cloudera-manager-server

echo "# 4. Install DB (already done in different instance)"

echo "# 5. Install mysql connector"
sudo yum -y install mysql-connector-java

if [ $1 = "master" ]; then
   echo " 5.1 Setup the cloudera manager Database"
   sudo /opt/cloudera/cm/schema/scm_prepare_database.sh mysql -h $2 $3 $4 $5
   
   echo "# 6. Step 6: Install CDH and Other Software"
   sudo systemctl start cloudera-scm-server
fi
