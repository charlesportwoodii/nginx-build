FROM centos:7
ENV DEBIAN_FRONTEND noninteractive

# Install Dependencies
RUN yum install wget -y 
RUN wget http://pkgs.repoforge.org/rpmforge-release/rpmforge-release-0.5.3-1.el7.rf.x86_64.rpm
RUN wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
RUN yum install rpmforge-release-0.5.3-1.el7.rf.x86_64.rpm -y
RUN yum install epel-release-latest-7.noarch.rpm -y
RUN yum update -y
RUN yum upgrade -y

# Install Postgres
RUN wget https://download.postgresql.org/pub/repos/yum/9.5/redhat/rhel-7-x86_64/pgdg-centos95-9.5-2.noarch.rpm
RUN yum install pgdg-centos95-9.5-2.noarch.rpm -y

# Install build tools
RUN yum install make automake autoconf g++ build-essential glib2-devel glibc-devel git libmcrypt-devel libmcrypt gcc libtool libxml2-devel libicu-devel gcc-c++ bison libpng12-devel libjpeg-turbo readline-devel postgresql95-devel freetype-devel libjpeg-turbo-devel postgresql-devel ruby ruby-devel -y
RUN yum group install "Development Tools" -y

# Install FPM
RUN gem install fpm


