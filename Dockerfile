#FROM registry.fedoraproject.org/fedora
#registry.access.redhat.com/ubi8/ubi:8.6-943
FROM registry.access.redhat.com/ubi9:9.0.0-1640
RUN dnf install fio util-linux python-pip wget -y && dnf clean all -y

WORKDIR /
COPY etcd.sh /
COPY fio_suite.sh /
COPY fio_suite2.sh /
COPY runner.sh /usr/local/bin/
RUN chmod +x /fio_suite.sh
RUN chmod +x /fio_suite2.sh
RUN chmod +x /etcd.sh
RUN chmod +x /usr/local/bin/runner.sh
CMD ["/usr/local/bin/runner.sh"]
ENTRYPOINT ["/usr/local/bin/runner.sh"]