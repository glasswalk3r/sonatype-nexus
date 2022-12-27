#!/bin/bash

set -e -o pipefail

# TODO: those functions were copied from backup.sh, they should be properly
# shared
function validate_bucket() {
    local current_value=$1

    if [ -z "$current_value" ]
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
${me} download a tarball with important directories from Sonatype Nexus and
restore this tarball to the appropriate file tree in the file system.

The Nexus systemd unit is first stopped, the backup is generated and uploaded
and then the unit is put back to work.

The latest tarball is selected by default.

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

function cleanup() {
    if [ -d backup ]
    then
        rm -rf backup
    fi

    rm -f *.tar.xz
}

validate_bucket $b 

# TODO: make those values configurable by command line options
nexus_base_dir=/opt/sonatype/sonatype-work/nexus3
data_dir="${nexus_base_dir}/db"
blobs_dir="${nexus_base_dir}/blobs/default"
bucket_name=$b
cli_output=$(mktemp)

cd -v "${HOME}"
cleanup
aws s3 ls "${bucket_name}" > $cli_output
latest_backup=$(head -1 $cli_output | awk '{print $4}')
aws s3 cp "${bucket_name}/${latest_backup}" .
tar -xJf "${latest_backup}"
systemctl stop nexus

echo 'Removing original files...'

for dir in component config security
do
    rm -rf "${data_dir}/${dir}"
done

echo -e 'Done\nAfter cleanup:'
ls -l ${data_dir}

restore_dir="${nexus_base_dir}/restore-from-backup"
ls -l "${restore_dir}"
read stop

echo 'Restoring the Nexus database...'
cd "${HOME}/backup/nexus"
cp -v *.bak "${restore_dir}"
echo 'Done'

echo 'Restoring Nexus blobs...'
cd "${HOME}/backup/blobs/default"
rm -rf "${blobs_dir}/*"
cp -a * "${blobs_dir}"
echo 'Done'

systemctl start nexus
