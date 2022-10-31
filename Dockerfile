#FROM registry.fedoraproject.org/fedora
#FROM registry.access.redhat.com/ubi8:8.6-990
FROM registry.access.redhat.com/ubi9:9.0.0-1640
RUN dnf install fio util-linux python-pip wget plotutils -y && dnf clean all -y
#RUN dnf install fio util-linux python-pip wget plotutils pandoc -y && dnf clean all -y

WORKDIR /
COPY . /usr/local/bin/

RUN chmod +x /usr/local/bin/fio_suite.sh
RUN chmod +x /usr/local/bin/etcd-mg.sh
RUN chmod +x /usr/local/bin/etcd-analyzer.sh
RUN chmod +x /usr/local/bin/runner.sh
RUN chmod +x /usr/local/bin/must-gather-log_merger.sh
CMD ["/usr/local/bin/runner.sh"]
ENTRYPOINT ["/usr/local/bin/runner.sh"]