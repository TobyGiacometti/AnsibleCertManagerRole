#!/bin/sh

log() {
	printenv >>"$log_file" || return
	echo "$cmd" >>"$log_file"
	echo "---" >>"$log_file"
}

cmd="$0 $*"
log_file=/tmp/acme.sh.log

if [ "$1" = --register-account ]; then
	log || exit
	mkdir -p "$(dirname "$0")/ca"
elif [ "$1" = --update-account ] && [ "$2" = --accountemail ]; then
	log || exit
	echo "$3" >"$(dirname "$0")/ca/acme-v02.api.letsencrypt.org/email.txt"
elif [ "$1" = --revoke ] && [ "$2" = --domain ]; then
	log || exit
	rm "$(dirname "$0")/$3/$3.cer"
elif [ "$1" = --issue ] && [ "$6" = --domain ]; then
	log || exit
	lock_file=/tmp/cert-$(printf "%s" "$*" | cksum | cut -d " " -f 1).lock
	[ -e "$lock_file" ] && return 2
	mkdir -p "$(dirname "$0")/$7" || exit
	touch "$(dirname "$0")/$7/$7.conf" || exit
	touch "$(dirname "$0")/$7/$7.csr" || exit
	touch "$(dirname "$0")/$7/$7.csr.conf" || exit
	touch "$(dirname "$0")/$7/$7.key" || exit
	touch "$(dirname "$0")/$7/$7.cer" || exit
	touch "$(dirname "$0")/$7/ca.cer" || exit
	touch "$(dirname "$0")/$7/fullchain.cer" || exit
	touch "$lock_file"
else
	sh "$(dirname "$0")/acme.sh.orig" "$@"
fi
