#!/bin/sh
#
# $Id: dhcp3-server.init.d,v 1.4 2003/07/13 19:12:41 mdz Exp $
#

### BEGIN INIT INFO
# Provides:          dhcp3-server
# Required-Start:    $network
# Required-Stop:     $network
# Should-Start:      $local_fs
# Should-Stop:       $local_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: DHCP server
# Description:       Dynamic Host Configuration Protocol Server
### END INIT INFO

PATH=/sbin:/bin:/usr/sbin:/usr/bin

test -f /usr/sbin/dhcpd3 || exit 0

# It is not safe to start if we don't have a default configuration...
if [ ! -f /etc/default/dhcp3-server ]; then
	echo "/etc/default/dhcp3-server does not exist! - Aborting..."
	echo "Run 'dpkg-reconfigure dhcp3-server' to fix the problem."
	exit 0
fi

# Read init script configuration (so far only interfaces the daemon
# should listen on.)
. /etc/default/dhcp3-server

NAME=dhcpd3
DESC="DHCP server"
DHCPDPID=/var/run/dhcpd.pid

test_config()
{
	if ! /usr/sbin/dhcpd3 -t > /dev/null 2>&1; then
		echo "dhcpd self-test failed. Please fix the config file."
		echo "The error was: "
		/usr/sbin/dhcpd3 -t
		exit 1
	fi
}

# single arg is -v for messages, -q for none
check_status()
{
    if [ ! -r "$DHCPDPID" ]; then
	test "$1" != -v || echo "$NAME is not running."
	return 3
    fi
    if read pid < "$DHCPDPID" && ps -p "$pid" > /dev/null 2>&1; then
	test "$1" != -v || echo "$NAME is running."
	return 0
    else
	test "$1" != -v || echo "$NAME is not running but $DHCPDPID exists."
	return 1
    fi
}

case "$1" in
	start)
		test_config
		echo -n "Starting $DESC: "
		start-stop-daemon --start --quiet --pidfile $DHCPDPID \
			--exec /usr/sbin/dhcpd3 -- -q $INTERFACES
		sleep 2

		if check_status -q; then
			echo "$NAME."
		else
			echo "$NAME failed to start - check syslog for diagnostics."
			exit 1
		fi
		;;
	stop)
		echo -n "Stopping $DESC: $NAME"
		start-stop-daemon --stop --quiet --pidfile $DHCPDPID
		rm -f "$DHCPDPID"
		echo "."
		;;
	restart | force-reload)
		test_config
		$0 stop
		sleep 2
		$0 start
		if [ "$?" != "0" ]; then
			exit 1
		fi
		;;
	status)
		echo -n "Status of $DESC: "
		check_status -v
		exit "$?"
		;;
	*)
		echo "Usage: $0 {start|stop|restart|force-reload|status}"
		exit 1 
esac

exit 0
