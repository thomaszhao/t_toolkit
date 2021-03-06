#!/bin/bash


export PATH='/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin'
SHELLDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


function show_retran_rate()
{

	netstat -s -t > /tmp/netstat_s 2>/dev/null

	s_r=`cat /tmp/netstat_s | grep 'segments send out' | awk '{print $1}'`
	s_re=`cat /tmp/netstat_s  | grep 'segments retransmited' | awk '{print $1}'`

	[ -e ${SHELLDIR}/s_r ] || touch ${SHELLDIR}/s_r
	[ -e ${SHELLDIR}/s_re ] || touch ${SHELLDIR}/s_re

	l_s_r=`cat ${SHELLDIR}/s_r`
	l_s_re=`cat ${SHELLDIR}/s_re`

	echo $s_r > ${SHELLDIR}/s_r
	echo $s_re > ${SHELLDIR}/s_re

	tcp_re_rate=`echo "$s_r $s_re $l_s_r $l_s_re" | awk '{printf("%.3f",($2-$4)/($1-$3)*100)}'`
	echo -n `date -Isec` "	"
	echo -n `expr $s_r - $l_s_r`  "	"
	echo -n `expr $s_re - $l_s_re` "	"

	echo $tcp_re_rate "%"

}

echo `date -Isec` "	" "send	" "retran	" "rate"

while [ 1 ] ; do
	show_retran_rate
	sleep 5
done
