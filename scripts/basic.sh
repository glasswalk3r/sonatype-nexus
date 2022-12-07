#!/bin/bash

set -uo pipefail

function debug_info() {
  echo "Debugging info:"
  which java
  java -version
  journalctl _SYSTEMD_UNIT=nexus.service
  local nexus_log=/opt/sonatype/sonatype-work/nexus3/log/nexus.log

  if [ -f "${nexus_log}" ]
  then
      cat "${nexus_log}"
  fi
}

yum clean all
rm -rfv /var/cache/yum

SONATYPE_DIR=/opt/sonatype
LATEST=latest-unix.tar.gz

if [ -d "${SONATYPE_DIR}" ]
then
    echo "Nexus already installed"
else
    mkdir "${SONATYPE_DIR}"
    cd "${SONATYPE_DIR}"
    echo "Downloading latest version of Nexus 3..."
    wget -q -c "https://download.sonatype.com/nexus/3/${LATEST}"

    if [ $? -ne 0 -o  ! -f "${LATEST}" ]
    then
        echo 'Missing Nexus tarball' >&2
        exit 1
    fi

    tar -xzf "${LATEST}"
    rm -v "${LATEST}"
    NEXUS_VERSION=$(ls -d nexus*)

    if [ -z ${NEXUS_VERSION} ]
    then
        echo "Failed to fetch version to create symlink"
        exit 1
    else
        ln -s ${NEXUS_VERSION} nexus
    fi

    echo "Unpacked Nexus ${NEXUS_VERSION} successfully."
    useradd -d "${SONATYPE_DIR}" -r -s /sbin/nologin nexus
    echo "Added nexus user"
    chown -R nexus.nexus /opt/sonatype
fi

NEXUS_UNIT=/etc/systemd/system/nexus.service

if ! [ -f "${NEXUS_UNIT}" ]
then
    echo "Missing ${NEXUS_UNIT} file!" >&2
    exit 1
else
    chown root.root "${NEXUS_UNIT}"
fi

echo 'Installing Nexus Systemd unit...'
systemctl daemon-reload
systemctl enable nexus.service
systemctl start nexus.service
exit_code=$?

if [ ! ${exit_code} -eq 0 ]
then
    echo "Failed to start the service" >&2
    debug_info
    exit 1
fi

sleep 10
systemctl status nexus.service

if [ $? -eq 0 ]
then
    echo 'Nexus status is OK'
else
    echo 'Failed to start Nexus' >&2
    debug_info
    exit 1
fi

sleep_time=10
retries=3
counter=0

echo "Waiting for Nexus to initialize (${retries} retries)..."

sleep ${sleep_time}

while [ ${counter} -le ${retries} ]
do
    curl -sS http://0.0.0.0:8081 -o /dev/null

    if [ $? -eq 0 ]
    then
        echo "Nexus initialized"
        break
    false
        echo 'Failed to initialize Nexus'
    fi
    sleep_time=$((sleep_time*2))
    echo "Waiting for ${sleep_time} seconds..."
    sleep ${sleep_time}
    counter=$((counter+1))
done

admin_file=/opt/sonatype/sonatype-work/nexus3/admin.password

if [ -f "${admin_file}" ]
then
    echo 'Credentials to start configuring Nexus:'
    echo 'user = admin'
    pass=$(cat "${admin_file}")
    echo "initial password = ${pass}"
else
    echo 'Cannot read credentials because Nexus service is not up, you should start looking for errors'
fi

# must disable or it won't work with EC2/public IP
echo 'nexus.security.anticsrftoken.enabled=false' >> /opt/sonatype/sonatype-work/nexus3/etc/nexus.properties
