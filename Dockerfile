#FROM registry.fedoraproject.org/fedora
#registry.access.redhat.com/ubi8/ubi:8.6-943
FROM registry.access.redhat.com/ubi9:9.0.0-1640
RUN dnf install fio util-linux python-pip wget plotutils -y && dnf clean all -y

WORKDIR /
COPY . /usr/local/bin/

RUN chmod +x /usr/local/bin/fio_suite.sh
RUN chmod +x /usr/local/bin/etcd-mg.sh
RUN chmod +x /usr/local/bin/runner.sh
RUN chmod +x /usr/local/bin/must-gather-log_merger.sh
CMD ["/usr/local/bin/runner.sh"]
ENTRYPOINT ["/usr/local/bin/runner.sh"]