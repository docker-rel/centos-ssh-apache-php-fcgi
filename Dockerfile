# =============================================================================
# jdeathe/centos-ssh-apache-php-fcgi
#
# CentOS-6, Apache 2.2, PHP 5.3, PHP memcached 1.0, PHP APC 3.1, Composer
# 
# =============================================================================
FROM jdeathe/centos-ssh-apache-php:centos-6

MAINTAINER James Deathe <james.deathe@gmail.com>

# -----------------------------------------------------------------------------
# FastCGI support
# -----------------------------------------------------------------------------
RUN yum --setopt=tsflags=nodocs -y install \
	fcgi \
	mod_fcgid \
	&& rm -rf /var/cache/yum/* \
	&& yum clean all

# -----------------------------------------------------------------------------
# Apache mime_magic module should be disabled with FastCGI
# -----------------------------------------------------------------------------
RUN sed -i \
	-e 's~^LoadModule mime_magic_module modules/mod_mime_magic.so~#LoadModule mime_magic_module modules/mod_mime_magic.so~g' \
	/etc/httpd/conf/httpd.conf

# -----------------------------------------------------------------------------
# Enable the pathinfo fix
# -----------------------------------------------------------------------------
RUN sed -i \
	-e 's~^;cgi.fix_pathinfo=1~cgi.fix_pathinfo = 1~g' \
	/etc/php.ini

# -----------------------------------------------------------------------------
# Enable Apache MPM worker
# -----------------------------------------------------------------------------
RUN sed -i \
	-e 's~#HTTPD=/usr/sbin/httpd.worker~HTTPD=/usr/sbin/httpd.worker~g' \
	/etc/sysconfig/httpd

# -----------------------------------------------------------------------------
# Disable mod_php
# -----------------------------------------------------------------------------
RUN mv /etc/httpd/conf.d/php.conf /etc/httpd/conf.d/php.conf.off \
	&& touch /etc/httpd/conf.d/php.conf \
	&& chmod 444 /etc/httpd/conf.d/php.conf

# -----------------------------------------------------------------------------
# Add the PHP Wrapper script
# -----------------------------------------------------------------------------
RUN mkdir -p /var/www/app/bin
ADD var/www/app/bin/php-wrapper /var/www/app/bin/

# -----------------------------------------------------------------------------
# Set permissions & add to the template directory
# -----------------------------------------------------------------------------
RUN chmod -R 750 /var/www/app/bin \
	&& cp -rpf /var/www/app/bin /var/www/.app-skel/bin

# -----------------------------------------------------------------------------
# Copy files into place
# -----------------------------------------------------------------------------
ADD etc/apache-bootstrap /etc/
ADD etc/services-config/httpd/apache-bootstrap.conf /etc/services-config/httpd/
ADD etc/services-config/httpd/conf.d/fcgid.conf /etc/services-config/httpd/conf.d/
RUN ln -sf /etc/services-config/httpd/apache-bootstrap.conf /etc/apache-bootstrap.conf \
	&& ln -sf /etc/services-config/httpd/conf.d/fcgid.conf /etc/httpd/conf.d/fcgid.conf \
	&& chmod +x /etc/apache-bootstrap

EXPOSE 80 8443 443

CMD ["/usr/bin/supervisord", "--configuration=/etc/supervisord.conf"]