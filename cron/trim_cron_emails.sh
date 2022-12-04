LINE_COUNT=1000000

trim_cron_emails () {
	cat cron/update_ddns.sh | tail -n $LINE_COUNT > /var/spool/mail/ec2-user
}

trim_cron_emails

