#!/bin/sh -e

usage() {
    cat <<EOF
$0 [-t KEY_TYPE] [-b KEY_BITS] [-c KEY_COMMENT] [-u SSH_USERNAME] [-p SSH_PUBKEY] SECRET_NAME

This script generates a ssh key and two secrets SECRET_NAME and 
SECRET_NAME-pub. The latter only includes the public key.

OPTIONS:
 * KEY_TYPE is one of ed25519, rsa, rsa1, dsa or ecdsa
 * KEY_BITS is usually one of 2048, 3072, 4096
 * KEY_COMMENT is the comment of the key
 * SSH_PUBKEY is the key to use
 * SSH_USERNAME is the username to use
 * SECRET_NAME is the secret name to generate
EOF
}

log() {
    echo $@ >&2
}

gen_sshkey() {
    keybits=""
    [ -n "$KEY_BITS" ] && keybits="-t $KEY_BITS"
    ssh-keygen -t $KEY_TYPE $keybits -f $keydir/ssh-privatekey \
        -C "$KEY_COMMENT" -P ""
    mv $keydir/ssh-privatekey.pub $keydir/ssh-publickey
}


while getopts "t:b:u:c:p:" flag; do
    case "$flag" in
        t)
            if [ -z ${OPTARG} ]; then
                log "Missing argument SSH_TYPE for -t"
                exit 1
            fi
            KEY_TYPE=$OPTARG
            ;;
        b)
            if [ -z ${OPTARG} ]; then
                log "Missing argument KEY_BITS for -b"
                exit 1
            fi
            KEY_BITS=$OPTARG
            ;;
        c)
            if [ -z ${OPTARG} ]; then
                log "Missing argument KEY_COMMENT for -c"
                exit 1
            fi
            KEY_COMMENT=$OPTARG
            ;;
        u)
            if [ -z ${OPTARG} ]; then
                log "Missing argument SSH_USERNAME for -u"
                exit 1
            fi
            SSH_USERNAME=$OPTARG
            ;;
        p)
            if [ -z ${OPTARG} ]; then
                log "Missing argument SSH_PUBKEY for -p"
                exit 1
            fi
            SSH_PUBKEY=$OPTARG
            ;;
    esac
done
shift $(( OPTIND - 1 ))

if [ $# -eq 1 ]; then
    SECRET_NAME="$1"
fi

if [ -z ${SECRET_NAME} ]; then
    log "No SECRET_NAME given."
    usage
    exit 1
fi

SSH_USERNAME=${SSH_USERNAME-${SECRET_NAME}}
KEY_TYPE=${KEY_TYPE-ed25519}
KEY_BITS=${KEY_BITS-}
KEY_COMMENTS=${KEY_COMMENTS-}

keydir=$(mktemp -d)

echo -n $SSH_USERNAME > $keydir/username

if [ -z $SSH_PUBKEY ]; then
    gen_sshkey

    # generate private key secret
    oc secrets new $SECRET_NAME $keydir
    rm $keydir/ssh-privatekey
else
    cp "$SSH_PUBKEY" $keydir/ssh-publickey
fi

oc secrets new ${SECRET_NAME}-pub $keydir

rm -r $keydir
