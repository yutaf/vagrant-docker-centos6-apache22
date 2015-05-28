FROM centos:centos6
MAINTAINER yutaf <fujishiro@amaneku.co.jp>

#
# yum repos
#
# epel
# need for libcurl-devel
RUN yum localinstall http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm -y
# mysql
RUN yum localinstall https://dev.mysql.com/get/mysql-community-release-el6-5.noarch.rpm -y
# ius
RUN yum localinstall -y http://dl.iuscommunity.org/pub/ius/stable/CentOS/6/x86_64/ius-release-1.0-13.ius.centos6.noarch.rpm


RUN yum update -y
RUN yum install --enablerepo=epel,ius -y \
# binaries for login shell usage (not essential)
  which \
  git \
# Apache
  tar \
  gcc \
  zlib \
  zlib-devel \
  openssl-devel \
  pcre-devel \
# supervisor
  supervisor \
# cron
  crontabs.noarch

# COPY src
COPY src /usr/local/src/

#
# Apache
#

RUN cd /usr/local/src && \
  tar xzvf httpd-2.2.29.tar.gz && \
  cd httpd-2.2.29 && \
    ./configure \
      --prefix=/opt/apache2.2.29 \
      --enable-mods-shared=all \
      --enable-proxy \
      --enable-ssl \
      --with-ssl \
      --with-mpm=prefork \
      --with-pcre

# install
RUN cd /usr/local/src/httpd-2.2.29 && \
  make && make install


#
# Edit config files
#

# Apache config
RUN sed -i "s/^Listen 80/#&/" /opt/apache2.2.29/conf/httpd.conf && \
  sed -i "s/^DocumentRoot/#&/" /opt/apache2.2.29/conf/httpd.conf && \
  sed -i "/^<Directory/,/^<\/Directory/s/^/#/" /opt/apache2.2.29/conf/httpd.conf && \
  sed -i "s;ScriptAlias /cgi-bin;#&;" /opt/apache2.2.29/conf/httpd.conf && \
  sed -i "s;#\(Include conf/extra/httpd-mpm.conf\);\1;" /opt/apache2.2.29/conf/httpd.conf && \
  sed -i "s;#\(Include conf/extra/httpd-default.conf\);\1;" /opt/apache2.2.29/conf/httpd.conf && \
  sed -i "s/\(ServerTokens \)Full/\1Prod/" /opt/apache2.2.29/conf/extra/httpd-default.conf && \
  echo "Include /srv/apache/apache.conf" >> /opt/apache2.2.29/conf/httpd.conf
COPY templates/apache.conf /srv/apache/apache.conf
# synced folder が rsync の場合 log を pull 出来ないので無効
RUN echo 'CustomLog "|/opt/apache2.2.29/bin/rotatelogs /srv/www/logs/access/access.%Y%m%d.log 86400 540" combined' >> /srv/apache/apache.conf && \
  echo 'ErrorLog "|/opt/apache2.2.29/bin/rotatelogs /srv/www/logs/error/error.%Y%m%d.log 86400 540"' >> /srv/apache/apache.conf

# supervisor
COPY templates/supervisord.conf /etc/supervisord.conf
RUN echo '[program:apache2]' >> /etc/supervisord.conf && \
  echo 'command=/opt/apache2.2.29/bin/httpd -DFOREGROUND' >> /etc/supervisord.conf

# Set up web source
RUN mkdir -p /srv/www/htdocs && \
  echo Hello, apache > /srv/www/htdocs/index.html

# COPY script for running container
COPY scripts/run.sh /usr/local/bin/run.sh
RUN chmod +x /usr/local/bin/run.sh

EXPOSE 80 3306
CMD ["/usr/local/bin/run.sh"]
