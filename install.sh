#!/bin/bash
# Roon as root. It installs and configures wordpress and wp-cli from scratch in ubuntu

echo "what is your linux user?: "
read user;

while [ $(grep -c "^$user:" /etc/passwd) -eq 0 ]
do
        echo "that user does not exist. Please enter a valid one: "
        read user
done

apt update;
apt install -y apache2 curl mysql-server php libapache2-mod-php php-mysql php-curl php-gd php-mbstring php-xml php-xmlrpc php-zip php-soap php-intl git unzip;

service mysql start

echo "configuring mysql server"
echo "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'root'; FLUSH PRIVILEGES; CREATE DATABASE wordpress" |  mysql;

service mysql restart

read -r -d '' allow_override << EOM
<Directory /var/www/html/>
    AllowOverride All
</Directory>
EOM

echo "$allow_override" >> /etc/apache2/apache2.conf &&
a2enmod rewrite &&
service apache2 restart;

echo "downloading and setting up wordpress"

wordpress='/var/www/html/wordpress'

cd /tmp &&
curl -O https://wordpress.org/latest.tar.gz &&
tar xzvf latest.tar.gz &&
touch /tmp/wordpress/.htaccess &&
chmod 660 /tmp/wordpress/.htaccess &&
cp /tmp/wordpress/wp-config-sample.php /tmp/wordpress/wp-config.php &&
mkdir /tmp/wordpress/wp-content/upgrade &&
echo "creating the wordpress folder $wordpress"
mkdir "$wordpress" &&
cp -a /tmp/wordpress/. "$wordpress";

chown -R "$user:www-data" "$wordpress"
find "$wordpress" -type d -exec chmod g+s {} \;
chmod g+w "$wordpress/wp-content"
chmod g+w "$wordpress/wp-admin"

# install wp-cli

echo "installing wp-cli"

curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar &&
chmod +x wp-cli.phar &&
mv wp-cli.phar /usr/local/bin/wp;

# copy configurations to wp-config.php

table_prefix='$table_prefix = '"'wp_';"
read -r -d '' config << EOM
<?php
/**
 * The base configuration for WordPress
 *
 * The wp-config.php creation script uses this file during the
 * installation. You don't have to use the web site, you can
 * copy this file to "wp-config.php" and fill in the values.
 *
 * This file contains the following configurations:
 *
 * * MySQL settings
 * * Secret keys
 * * Database table prefix
 * * ABSPATH
 *
 * @link https://codex.wordpress.org/Editing_wp-config.php
 *
 * @package WordPress
 */

// ** MySQL settings - You can get this info from your web host ** //
/** The name of the database for WordPress */
define( 'DB_NAME', 'wordpress' );

/** MySQL database username */
define( 'DB_USER', 'root' );

/** MySQL database password */
define( 'DB_PASSWORD', 'root' );

/** MySQL hostname */
define( 'DB_HOST', 'localhost' );
/** Database Charset to use in creating database tables. */
define( 'DB_CHARSET', 'utf8' );

/** The Database Collate type. Don't change this if in doubt. */
define( 'DB_COLLATE', '' );

/**#@+
 * Authentication Unique Keys and Salts.
 *
 * Change these to different unique phrases!
 * You can generate these using the {@link https://api.wordpress.org/secret-key/1.1/salt/ WordPress.org secret-key service}
 * You can change these at any point in time to invalidate all existing cookies. This will force all users to have to log in again.
 *
 * @since 2.6.0
 */
define( 'AUTH_KEY',         'put your unique phrase here' );
define( 'SECURE_AUTH_KEY',  'put your unique phrase here' );
define( 'LOGGED_IN_KEY',    'put your unique phrase here' );
define( 'NONCE_KEY',        'put your unique phrase here' );
define( 'AUTH_SALT',        'put your unique phrase here' );
define( 'SECURE_AUTH_SALT', 'put your unique phrase here' );
define( 'LOGGED_IN_SALT',   'put your unique phrase here' );
define( 'NONCE_SALT',       'put your unique phrase here' );

/**#@-*/

/**
 * WordPress Database Table prefix.
 *
 * You can have multiple installations in one database if you give each
 * a unique prefix. Only numbers, letters, and underscores please!
 */
$table_prefix

/**
 * For developers: WordPress debugging mode.
 *
 * Change this to true to enable the display of notices during development.
 * It is strongly recommended that plugin and theme developers use WP_DEBUG
 * in their development environments.
 *
 * For information on other constants that can be used for debugging,
 * visit the Codex.
 *
 * @link https://codex.wordpress.org/Debugging_in_WordPress
 */

/* That's all, stop editing! Happy publishing. */

/** Absolute path to the WordPress directory. */
if ( ! defined( 'ABSPATH' ) ) {
        define( 'ABSPATH', dirname( __FILE__ ) . '/' );
}

/** Sets up WordPress vars and included files. */
require_once( ABSPATH . 'wp-settings.php' );
EOM

cd "$wordpress" &&
sudo -u $user echo "${config}"  > wp-config.php

echo "Wordpress was successfully installed. To configure your wordpress site, open http://localhost/wordpress in your web browser"
