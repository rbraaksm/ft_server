# install debian:buster
FROM debian:buster

# install upgrade, update and wget
RUN apt-get update && apt-get upgrade -y

# RUN apt-get -y install wget sendmail
RUN apt-get -y install wget sendmail

# install nginx
RUN apt-get -y install nginx
COPY ./srcs/nginx.config /etc/nginx/sites-available/localhost

# ssl
WORKDIR /var/cert
RUN openssl genrsa -out localhost.key 2048
RUN openssl req -new -x509 -key localhost.key -out localhost.cert -days 3650 -subj /CN=localhost

# menu website
RUN 	mkdir -p /var/www/localhost/wordpress/menu_website
# COPY 	/srcs/index.html /var/www/localhost/wordpress/menu_website
RUN 	chmod -R 755 /var/www/localhost/wordpress/menu_website

# symlink
RUN ln -s /etc/nginx/sites-available/localhost /etc/nginx/sites-enabled/localhost

# setup mysgl
RUN 	apt-get -y install mariadb-server
RUN 	service mysql start; \
    	echo "CREATE DATABASE wordpress;" | mysql -u root; \
    	echo "GRANT ALL PRIVILEGES ON *.* TO 'rbraaksm'@'localhost' IDENTIFIED BY 'ft_server';" | mysql -u root; \
    	echo "FLUSH PRIVILEGES" | mysql -u root

# phpmyadmin
WORKDIR /var/www/localhost/wordpress
RUN		apt-get -y install php7.3-fpm php-common php-mysql php-mbstring php-cli
RUN 	wget https://files.phpmyadmin.net/phpMyAdmin/5.0.2/phpMyAdmin-5.0.2-all-languages.tar.gz
RUN 	tar zxvf phpMyAdmin-5.0.2-all-languages.tar.gz
RUN 	rm phpMyAdmin-5.0.2-all-languages.tar.gz &&\
	 	mv phpMyAdmin-5.0.2-all-languages phpmyadmin
COPY	./srcs/config.inc.php /var/www/localhost/wordpress/phpmyadmin
RUN 	chmod -R 755 ./phpmyadmin

# wordpress
RUN		wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
RUN 	chmod +x wp-cli.phar
RUN 	mv wp-cli.phar /usr/local/bin/wp
WORKDIR /var/www/localhost/wordpress
RUN		service mysql start &&\
		wp core download --allow-root &&\
		wp config create --dbhost=localhost --dbname=wordpress --dbuser=rbraaksm --dbpass=ft_server --allow-root &&\
		wp core install --url=localhost --title="ft_server" --admin_name=rbraaksm --admin_password=ft_server --admin_email=rbraaksm@codam.student.nl --allow-root &&\
		chmod 644 wp-config.php &&\
		chown -R www-data:www-data /var/www/localhost &&\
		wp theme activate twentyseventeen --allow-root
		# wp theme install https://downloads.wordpress.org/theme/twentyseventeen.2.3.zip --allow-root

RUN rm /var/www/localhost/wordpress/wp-config.php
COPY ./srcs/wp-config.php /var/www/localhost/wordpress/

RUN chown -R www-data /var/www/localhost/wordpress/wp-content/uploads &&\
    chmod 777 /var/www/localhost/wordpress/wp-content/plugins &&\
    chmod 777 /var/www/localhost/wordpress/wp-content/themes &&\
    chmod 777 /var/www/localhost/wordpress
    # chmod 777 /var/www/localhost/wordpress/wp-content/upgrade &&\

RUN chmod 777 /var/www/localhost/wordpress/phpmyadmin

# SET MAX SIZES
RUN cd /etc/php/7.3/fpm && sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 10M/g' php.ini && \
	sed -i 's/post_max_size = 8M/post_max_size = 20M/g' php.ini

#RUN PROGRAM
COPY ./srcs/start.sh /root/
CMD bash /root/start.sh

EXPOSE 80 443 110