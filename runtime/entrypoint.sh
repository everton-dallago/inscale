#!/bin/bash
set -e

if [ -n "$INIT_TOKUDB" ]; then
	export LD_PRELOAD=/lib64/libjemalloc.so.1
fi
# Get config
DATADIR="$("mysqld" --verbose --help 2>/dev/null | awk '$1 == "datadir" { print $2; exit }')"

if [ ! -e "$DATADIR/init.ok" ]; then
	if [ -z "$MYSQL_ROOT_PASSWORD" -a -z "$MYSQL_ALLOW_EMPTY_PASSWORD" -a -z "$MYSQL_RANDOM_ROOT_PASSWORD" ]; then
        echo >&2 'error: database is uninitialized and password option is not specified '
        echo >&2 '  You need to specify one of MYSQL_ROOT_PASSWORD, MYSQL_ALLOW_EMPTY_PASSWORD and MYSQL_RANDOM_ROOT_PASSWORD'
        exit 1
    fi

    rm -rf "$DATADIR"
	mkdir -p "$DATADIR"

	echo 'Running --initialize-insecure'
	mysqld --initialize-insecure
	chown -R mysql:mysql "$DATADIR"
	# chown mysql:mysql /var/log/mysqld.log
	echo 'Finished --initialize-insecure'

	mysqld --user=mysql --datadir="$DATADIR" --skip-networking &
	pid="$!"

	mysql=( mysql --protocol=socket -uroot )

	for i in {30..0}; do
		if echo 'SELECT 1' | "${mysql[@]}" &> /dev/null; then
			break
		fi
		echo 'MySQL init process in progress...'
		sleep 1
	done
	if [ "$i" = 0 ]; then
		echo >&2 'MySQL init process failed.'
		exit 1
	fi

	# sed is for https://bugs.mysql.com/bug.php?id=20545
	mysql_tzinfo_to_sql /usr/share/zoneinfo | sed 's/Local time zone must be set--see zic manual page/FCTY/' | "${mysql[@]}" mysql
	# install TokuDB engine
	if [ -n "$INIT_TOKUDB" ]; then
		ps_tokudb_admin --enable
	fi

	if [ ! -z "$MYSQL_RANDOM_ROOT_PASSWORD" ]; then
		MYSQL_ROOT_PASSWORD="$(pwmake 128)"
		echo "GENERATED ROOT PASSWORD: $MYSQL_ROOT_PASSWORD"
	fi
	"${mysql[@]}" <<-EOSQL
		-- What's done in this file shouldn't be replicated
		--  or products like mysql-fabric won't work
		SET @@SESSION.SQL_LOG_BIN=0;
		DELETE FROM mysql.user ;
		CREATE USER 'root'@'%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}' ;
		GRANT ALL ON *.* TO 'root'@'%' WITH GRANT OPTION ;
		DROP DATABASE IF EXISTS test ;
		FLUSH PRIVILEGES ;
	EOSQL
	if [ ! -z "$MYSQL_ROOT_PASSWORD" ]; then
		mysql+=( -p"${MYSQL_ROOT_PASSWORD}" )
	fi

	if [ "$MYSQL_DATABASE" ]; then
		echo "CREATE DATABASE IF NOT EXISTS \`$MYSQL_DATABASE\` ;" | "${mysql[@]}"
		mysql+=( "$MYSQL_DATABASE" )
	fi

	if [ "$MYSQL_USER" -a "$MYSQL_PASSWORD" ]; then
		echo "CREATE USER '"$MYSQL_USER"'@'%' IDENTIFIED BY '"$MYSQL_PASSWORD"' ;" | "${mysql[@]}"

		if [ "$MYSQL_DATABASE" ]; then
			echo "GRANT ALL ON \`"$MYSQL_DATABASE"\`.* TO '"$MYSQL_USER"'@'%' ;" | "${mysql[@]}"
		fi

		echo 'FLUSH PRIVILEGES ;' | "${mysql[@]}"
	fi

	if [ ! -z "$MYSQL_ONETIME_PASSWORD" ]; then
		"${mysql[@]}" <<-EOSQL
			ALTER USER 'root'@'%' PASSWORD EXPIRE;
		EOSQL
	fi
	if ! kill -s TERM "$pid" || ! wait "$pid"; then
		echo >&2 'MySQL init process failed.'
		exit 1
	fi

	echo
	echo 'MySQL init process done. Ready for start up.'
	echo
	#mv /etc/my.cnf $DATADIR
fi
touch $DATADIR/init.ok
chown -R mysql:mysql "$DATADIR"

# ###
# # Wordpress setup
# ###

# cd /usr/share/nginx/html

# # TODO handle WordPress upgrades magically in the same way, but only if wp-includes/version.php's $wp_version is less than /usr/src/wordpress/wp-includes/version.php's $wp_version
# # version 4.4.1 decided to switch to windows line endings, that breaks our seds and awks
# # https://github.com/docker-library/wordpress/issues/116
# # https://github.com/WordPress/WordPress/commit/1acedc542fba2482bab88ec70d4bea4b997a92e4
# sed -ri 's/\r\n|\r/\n/g' wp-config*

# if [ ! -e wp-config.php ]; then
# 	awk '/^\/\*.*stop editing.*\*\/$/ && c == 0 { c = 1; system("cat") } { print }' wp-config-sample.php > wp-config.php <<'EOPHP'
# // If we're behind a proxy server and using HTTPS, we need to alert Wordpress of that fact
# // see also http://codex.wordpress.org/Administration_Over_SSL#Using_a_Reverse_Proxy
# if (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && $_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {
# $_SERVER['HTTPS'] = 'on';
# }

# EOPHP
# 	chown www-data:www-data wp-config.php
# fi

# # see http://stackoverflow.com/a/2705678/433558
# sed_escape_lhs() {
# 	echo "$@" | sed 's/[]\/$*.^|[]/\\&/g'
# }
# sed_escape_rhs() {
# 	echo "$@" | sed 's/[\/&]/\\&/g'
# }
# php_escape() {
# 	php -r 'var_export(('$2') $argv[1]);' "$1"
# }
# set_config() {
# 	key="$1"
# 	value="$2"
# 	var_type="${3:-string}"
# 	start="(['\"])$(sed_escape_lhs "$key")\2\s*,"
# 	end="\);"
# 	if [ "${key:0:1}" = '$' ]; then
# 		start="^(\s*)$(sed_escape_lhs "$key")\s*="
# 		end=";"
# 	fi
# 	sed -ri "s/($start\s*).*($end)$/\1$(sed_escape_rhs "$(php_escape "$value" "$var_type")")\3/" wp-config.php
# }

# set_config 'DB_HOST' "localhost"
# set_config 'DB_USER' "$MYSQL_USER"
# set_config 'DB_PASSWORD' "$MYSQL_PASSWORD"
# set_config 'DB_NAME' "$MYSQL_DATABASE"

# # allow any of these "Authentication Unique Keys and Salts." to be specified via
# # environment variables with a "WORDPRESS_" prefix (ie, "WORDPRESS_AUTH_KEY")
# UNIQUES=(
# 	AUTH_KEY
# 	SECURE_AUTH_KEY
# 	LOGGED_IN_KEY
# 	NONCE_KEY
# 	AUTH_SALT
# 	SECURE_AUTH_SALT
# 	LOGGED_IN_SALT
# 	NONCE_SALT
# )
# for unique in "${UNIQUES[@]}"; do
# 	eval unique_value=\$WORDPRESS_$unique
# 	if [ "$unique_value" ]; then
# 		set_config "$unique" "$unique_value"
# 	else
# 		# if not specified, let's generate a random value
# 		current_set="$(sed -rn "s/define\((([\'\"])$unique\2\s*,\s*)(['\"])(.*)\3\);/\4/p" wp-config.php)"
# 		if [ "$current_set" = 'put your unique phrase here' ]; then
# 			set_config "$unique" "$(head -c1M /dev/urandom | sha1sum | cut -d' ' -f1)"
# 		fi
# 	fi
# done

# if [ "$WORDPRESS_TABLE_PREFIX" ]; then
# 	set_config '$table_prefix' "$WORDPRESS_TABLE_PREFIX"
# fi

# if [ "$WORDPRESS_DEBUG" ]; then
# 	set_config 'WP_DEBUG' 1 boolean
# fi

exec "$@"
