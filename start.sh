#!/bin/bash -ex

SSH_PORT="${SSH_PORT-2222}"
CHROOT_USERS="${CHROOT_USERS-yes}"
USE_SEPARATE_AUTHORIZED_KEYS="${USE_SEPARATE_AUTHORIZED_KEYS-yes}"
LOG_LEVEL="${LOG_LEVEL-INFO}"

main() {
    generate_setup_passwd_sshkeys
    sshd_config > $SSHDIR/sshd_config.conf
    exec /usr/sbin/sshd -Def $SSHDIR/sshd_config.conf
}

is_true() {
    case "$1" in
        yes|y|true|t)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

authorized_keys_file() {
    [ $# -eq 0 ] && token="%u" || token="$1"
    if is_true "$USE_SEPARATE_AUTHORIZED_KEYS"; then
        echo "$SSHDIR/authorized_keys/$token"
    else
        [ $# -eq 0 ] && echo -n "/home/$1/"
        echo ".ssh/authorized_keys"
    fi
}

sshd_config() {
    cat <<EOF
Port ${SSH_PORT}
AddressFamily any
ListenAddress 0.0.0.0
ListenAddress ::
Protocol 2
LogLevel ${LOG_LEVEL}
PermitRootLogin no
AuthorizedKeysFile $(authorized_keys_file)
PasswordAuthentication no
# switch when openssh-server is >= 6.9
#PidFile none
PidFile /tmp/sshd.pid
Subsystem sftp internal-sftp
EOF

    if ! run_as_root; then
        echo UsePrivilegeSeparation no
        echo StrictModes no
    fi

    for entry in /etc/host-credentials/ssh-host*-key; do
        echo "HostKey $entry"
    done
}

generate_setup_passwd_sshkeys() {
    if run_as_root ; then
        running_uid="$SSHD_USER"
    else
        running_uid=$(id -u)
        sed -i "/^sshd_user:/s/:$SSHD_USER:/:$running_uid:/" /etc/passwd
    fi

    if is_true "$USE_SEPARATE_AUTHORIZED_KEYS"; then
        mkdir -p $SSHDIR/authorized_keys
        chmod 700 $SSHDIR/authorized_keys
    fi

    for entry in /etc/credentials/*; do
        if [ -f $entry/username ] ; then
            username="$(<$entry/username)"
        else
            username="$(basename $entry)"
        fi

        if [ -f "$entry/ssh-publickey" ]; then
            if [ -f "$entry/homedir" ]; then
                homedir="$(<$entry/homedir)"
            else
                homedir=/home/$username
            fi

            if run_as_root ; then
                running_uid=$(($running_uid + 1))
                if is_true "$CHROOT_USERS"; then
                    chown root $homedir
                else
                    chown $running_uid $homedir
                fi
            fi
            echo "$username:x:$running_uid:$(id -g):generated user:$homedir:/bin/bash" \
                >> /etc/passwd


            authorized_keys_filename=$(authorized_keys_file $username)
            if ! is_true "$USE_SEPARATE_AUTHORIZED_KEYS"; then
                mkdir -p $homedir/.ssh
                chmod 0700 $homedir/.ssh
            fi

            pubkey="$(<$entry/ssh-publickey)"
            if [ -f $entry/ssh-keyoptions ]; then
                pubkey="$(<$entry/ssh-keyoptions) ${pubkey}"
            fi
            printf "%s\n" "$pubkey" >> $authorized_keys_filename
        else
            log "ignoring credentials $username"
        fi
    done

    # enable nss_wrapper
    export LD_PRELOAD=libnss_wrapper.so
}

log() {
    echo "$@" >&2
}

run_as_root() {
    [ $(id -u) -eq 0 ]
}

main
