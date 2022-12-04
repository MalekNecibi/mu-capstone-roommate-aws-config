# Called when NOIP DDNS has update the dynamic dns record : bunkiez.ddns.net

log_file="/home/ec2-user/logs/ddns_updates.log"

logger () {
	local log_phrase=$1
	
	local datetime=$(TZ=America/Chicago date +%F_%T_%Z)
	echo "$datetime : $log_phrase" >> $log_file
}

logChangeDDNS () { 
	# update Dynamic DNS
	public_ip=$(dig +short myip.opendns.com @resolver1.opendns.com)
	logger "DDNS updated to $public_ip"
}

logChangeDDNS
