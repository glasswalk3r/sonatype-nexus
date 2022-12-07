# Nexus OSS

This project automates the setup of Sonatype Nexus OSS repository.

## Nexus OSS download

You can download the latest version 3 of Nexus OSS from
[here](https://download.sonatype.com/nexus/3/latest-unix.tar.gz).

This download is done automatically. After the setup is finished, a systemd unit
is created to manage the service and it is started. It is important to follow
the process through because the automation will tried to connect to the Nexus
HTTP port and retrieve the initial password for the admin account, credentials
required to start the manual configuration process. See an example below:

```
default: ● nexus.service - nexus service
default:    Loaded: loaded (/etc/systemd/system/nexus.service; enabled; vendor preset: disabled)
default:    Active: active (running) since Wed 2022-12-07 04:38:02 UTC; 10s ago
default:   Process: 22523 ExecStart=/opt/sonatype/nexus/bin/nexus start (code=exited, status=0/SUCCESS)
default:  Main PID: 22729 (java)
default:     Tasks: 43 (limit: 23646)
default:    Memory: 990.3M
default:    CGroup: /system.slice/nexus.service
default:            └─22729 /usr/lib/jvm/java-1.8.0-openjdk-1.8.0.352.b08-2.el8_7.x86_64/jre/bin/java -server -Dinstall4j.jvmDir=/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.352.b08-2.el8_7.x86_64/jre -Dexe4j.moduleName=/opt/sonatype/nexus/bin/nexus -XX:+UnlockDiagnosticVMOptions -Dinstall4j.launcherId=245 -Dinstall4j.swt=false -Di4jv=0 -Di4jv=0 -Di4jv=0 -Di4jv=0 -Di4jv=0 -Xms2703m -Xmx2703m -XX:MaxDirectMemorySize=2703m -XX:+UnlockDiagnosticVMOptions -XX:+LogVMOutput -XX:LogFile=../sonatype-work/nexus3/log/jvm.log -XX:-OmitStackTraceInFastThrow -Djava.net.preferIPv4Stack=true -Dkaraf.home=. -Dkaraf.base=. -Dkaraf.etc=etc/karaf -Djava.util.logging.config.file=etc/karaf/java.util.logging.properties -Dkaraf.data=../sonatype-work/nexus3 -Dkaraf.log=../sonatype-work/nexus3/log -Djava.io.tmpdir=../sonatype-work/nexus3/tmp -Dkaraf.startLocalConsole=false -Djdk.tls.ephemeralDHKeySize=2048 -Djava.endorsed.dirs=lib/endorsed -Di4j.vpt=true -classpath /opt/sonatype/nexus/.install4j/i4jruntime.jar:/opt/sonatype/nexus/lib/boot/nexus-main.jar:/opt/sonatype/nexus/lib/boot/activation-1.1.1.jar:/opt/sonatype/nexus/lib/boot/jakarta.xml.bind-api-2.3.3.jar:/opt/sonatype/nexus/lib/boot/jaxb-runtime-2.3.3.jar:/opt/sonatype/nexus/lib/boot/txw2-2.3.3.jar:/opt/sonatype/nexus/lib/boot/istack-commons-runtime-3.0.10.jar:/opt/sonatype/nexus/lib/boot/org.apache.karaf.main-4.3.6.jar:/opt/sonatype/nexus/lib/boot/osgi.core-7.0.0.jar:/opt/sonatype/nexus/lib/boot/org.apache.karaf.specs.activator-4.3.6.jar:/opt/sonatype/nexus/lib/boot/org.apache.karaf.diagnostic.boot-4.3.6.jar:/opt/sonatype/nexus/lib/boot/org.apache.karaf.jaas.boot-4.3.6.jar com.install4j.runtime.launcher.UnixLauncher start 9d17dc87 0 0 org.sonatype.nexus.karaf.NexusMain
default: 
default: Dec 07 04:38:02 rocky8.localdomain systemd[1]: Starting nexus service...
default: Dec 07 04:38:02 rocky8.localdomain systemd[1]: Started nexus service.
default: Nexus status is OK
default: Waiting for Nexus to initialize (3 retries)...
default: Waiting for 20 seconds...
default: curl: (7) Failed to connect to 0.0.0.0 port 8081: Connection refused
default: curl: (7) Failed to connect to 0.0.0.0 port 8081: Connection refused
default: Waiting for 40 seconds...
default: Nexus initialized
default: Credentials to start configuring Nexus:
default: user = admin
default: initial password = 2cd7c001-e390-4d6c-aa69-1ef4d49c4f01
```

## Vagrant

There is Vagrant automation for local testing before creating the resource on
AWS.

In order to use that, you will need to install:

- [Vagrant](https://developer.hashicorp.com/vagrant/downloads).
- [Virtualbox](https://www.virtualbox.org/wiki/Downloads).
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html#installing-and-upgrading-ansible).

After that, it is just a matter to hit `vagrant up` and wait for the VM come up.

## AWS

The automation for AWS is based on Hashicorp's Packer and Terraform.

See the `terraform/README.md` for more details.

## Backup and restore

Please check the [official documentation](https://help.sonatype.com/repomanager3/backup-and-restore) about it.

Also check the shell scripts `backup.sh` and `restore.sh` under the `scripts` directory.

The `backup.sh` script must be scheduled **after** the respective schedule task at Nexus.
