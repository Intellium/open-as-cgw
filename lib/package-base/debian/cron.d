#
#  limesas-lib maintenance
#
# m	h	dom	mon	dow	user	command
2	*	*	*	*	limes	/usr/local/bin/mail_logacc.pl >/dev/null 2>&1
0	0	*	*	*	limes	/usr/local/bin/daily_spam_report.pl >/dev/null 2>&1
10	0	*	*	*	root	/usr/local/bin/mysql_cron.sh >>/var/log/limes/syslog 2>&1
5   */3 *   *   *   root    /usr/bin/sa-update --channelfile /etc/limes/conf/sa-update/channelfile --gpgkeyfile /etc/limes/conf/sa-update/keyfile --gpghomedir /etc/limes/conf/sa-update --updatedir /var/lib/spamassassin && /etc/init.d/amavis restart  >/dev/null 2>&1
10  *   *   *   *   root    /usr/local/bin/clamav-u8-sig-rsync.sh >/dev/null 2>&1
*/5	*	*	*	*	limes	/usr/local/bin/mqsize.pl 2>&1
20	*	*	*	*	root    /etc/init.d/as-ldap-sync start > /dev/null 2>&1 
37	3	*	*	*	root    /etc/init.d/quarantine-cron restart > /dev/null 2>&1 
*/10	*	*	*	*	root	/usr/local/bin/check_amavis_phail.sh
*/10	*	*	*	*   root    /usr/local/bin/virtual_swap_controller.sh >> /var/log/limes/swap_control.log
