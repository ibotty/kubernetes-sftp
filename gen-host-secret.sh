#!/bin/sh -e

gen_sshkey() {
    keytype=""
    keybits=""
    keyname=""
    if [ $# -ge 1 ] ; then
        keyname="-$1"
        keytype="-t $1"
        if [ $# -ge 2 ]; then
            keybits="-b $2"
        fi
    fi
    ssh-keygen $keytype $keybits -f $keydir/ssh-host${keyname}-key -P ""
}

keydir=$(mktemp -d)

if [ $# -eq 1 ]; then
    secret_name="$1"
else
    secret_name="sftp"
fi

gen_sshkey rsa 4096
gen_sshkey ed25519

oc secrets new $secret_name $keydir

rm -r $keydir
