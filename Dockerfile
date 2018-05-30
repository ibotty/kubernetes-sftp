FROM centos:7
MAINTAINER Tobias Florek tob@butter.sh

EXPOSE 22/tcp
ENV SSHD_USER 1000
ENV SSHDIR /var/lib/sshd-container

RUN rpmkeys --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7 \
 && yum --setopt=tsflags=nodocs -y install \
        openssh-server openssh-clients rsync lsof epel-release \
 && rpmkeys --import /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7 \
 && yum install --setopt=tsflags=nodocs -y nss_wrapper \
 && yum clean all \
 && useradd sshd_user -mu $SSHD_USER -g 0 -d $SSHDIR \
 && chmod -R g+rwx $SSHDIR

ADD start.sh /usr/libexec/container/

VOLUME ["/etc/host-credentials/", "/home"]
CMD ["/usr/libexec/container/start.sh"]

USER 1000
