#!/bin/bash

set -eo pipefail

function validate_bucket() {
    local current_value=$1

    if [[ -z "$current_value" ]]
    then
        usage
    fi

    if ! [[ $current_value =~ '^s3://' ]]
    then
        echo -e "The bucket URI must start with 's3://'\n" 2>&1
        usage
    fi

    echo $current_value
}

function my_name() {
    local old_name=$1
    me=$(echo $old_name | sed -e 's/^\.\///')
    echo "$me"
}

function help() {
    local me=$(my_name $0)
    cat <<EOF
${me} generates a tarball from important directories from Sonatype Nexus and
uploads this tarball to a AWS S3 bucket.

The tarball filename is created based on the current timestamp. The Nexus
systemd unit is first stopped, the backup is generated and uploaded and
then the unit is put back to work.

You probably will want to schedule this backup for period that Nexus is not
in use.

The expected parameters are:

-b: the AWS S3 bucket URI to upload the backup. This is required.
-h: prints this help message and exits.
EOF
    exit 0
}

function usage() {
    local me=$(my_name $0)
    echo -e "Usage: ${me} -b <S3 bucket URI>\n" 2>&1
    echo "Run '${me} -h' to get more details" 2>&1
    exit 1
}

while getopts "b:h" option; do
    case "${option}" in
        b)
            b=${OPTARG}
            ;;
        h)
            help
            ;;
        *)
            usage
            ;;
    esac
done

validate_bucket $b 
echo 'Starting backup'

BLOBS='/opt/sonatype/sonatype-work/nexus3/blobs'
AWS_S3=$b
# the location setup in the task to backup database on Nexus
SCHEDULED_BACKUP_DIR='/tmp/nexus/'
BACKUP_DIR="${HOME}/backup"

echo 'Stopping the Nexus daemon for copying files...'
systemctl stop nexus
echo 'Done'

mkdir -p "${BACKUP_DIR}"
cd "${BACKUP_DIR}"
cp -a "${BLOBS}" .
cp -a "${SCHEDULED_BACKUP_DIR}" .

backup_filename=nexus-$(date +%d-%m-%Y_%H.%M.%S).tar.xz

echo "Creating backup in file ${backup_filename} ..."
cd ..
tar -c -J -f "${backup_filename}" backup
echo "Copying '${backup_filename}' to ${AWS_S3} ..."
aws s3 cp "${backup_filename}" "${AWS_S3}"
echo 'Finished, cleaning up...'
rm -f "${backup_filename}"
rm -rfv "${SCHEDULED_BACKUP_DIR}"
rm -rf "${BACKUP_DIR}"

echo 'Starting again the Nexus daemon...'
systemctl start nexus
echo 'Done'
