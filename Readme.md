# Openssh-based SFTP server

This is a centos-7-based Openssh container, that is configured to run with
as non-root uid (thanks to nss\_wrapper).


## Host keys

Host keys need to be mounted in `/etc/host-credentials`, and be named
`ssh-host-*-key`. The moduli should be named `moduli`.

See the script `gen-host-secret.sh` that will create a secret using openshift
tools and openssh.


## Client keys

Client config should be in a subdirectory in `/etc/credentials` and contain the
public-key as `ssh-publickey` and optionally the username in `username`.

See the script `gen_client-secrets.sh` to generate such a secret.
