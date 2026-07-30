FROM almalinux:9

RUN dnf -y install httpd \
    && dnf clean all \
    && printf '%s\n' 'ServerName localhost' > /etc/httpd/conf.d/server-name.conf

EXPOSE 80

CMD ["/usr/sbin/httpd", "-DFOREGROUND"]

