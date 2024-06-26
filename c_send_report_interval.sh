#!/bin/bash
# c_send_report_interval.sh

FILEREPORT='/cronwork/pg_profile_interval.html'
REPORTNAME="Interval Report"
SUBJTEXT="PostgreSQL [${HOST}] pg_profile ${REPORTNAME}"
SNAPS=$1	# например, 3 получасовых снапшота
SHIFT=$2	# например, со смещением в 3 снапшота

DTS=$(date -d "-$(( 10#$(date +%M) % 30 )) minutes - $(($SNAPS*30)) minutes - $(($SHIFT*30)) minutes" +%Y-%m-%dT%H:%M:00%z)
DTF=$(date -d "-$(( 10#$(date +%M) % 30 )) minutes - $(($SHIFT*30)) minutes + 1 minute" +%Y-%m-%dT%H:%M:00%z)

MSGTEXT="<html>PostgreSQL <b>[${HOST}]</b> pg_profile ${REPORTNAME}<BR>
<p>Report interval: ${DTS} - ${DTF}</p>
<p><a href=\"https://postgrespro.ru/docs/postgrespro/16/pgpro-pwr#PGPRO-PWR-SECTIONS-OF-A-REPORT\">Описание разделов отчёта</a>
<BR><a href=\"https://github.com/zubkov-andrei/pg_profile/blob/master/doc/pg_profile.md#sections-of-a-report\">Description of report sections</a></p>
<p>Supported versions<BR>PostgreSQL:<BR>
- 16 supported since version 4.3<BR>- 15 supported since version 4.1<BR>- 14 supported since version 0.3.4<BR>- 13 supported since version 0.1.3<BR>
- 12 supported since version 0.1.0<BR>- 10 supported until version 4.1<BR><BR>pg_stat_statements extension:<BR>- 1.10 supported since version 4.1<BR>
- 1.9 supported since version 4.0<BR>- 1.8 supported since version 0.1.2</p><BR>See Attachment</html>"

echo "[pg_profile]  Generate ${REPORTNAME} Started."
PGPASSWORD=${PASSWORD} psql -h ${HOST} -p ${PORT} -U ${USERNAME} -d ${DBNAME} -qAt -c "SELECT profile.report_interval(${SNAPS},${SHIFT});" --output="${FILEREPORT}"
RC=$?
echo "[pg_profile]  Generate ${REPORTNAME} Finished. RC=${RC}"

#PGPASSWORD=${PASSWORD} psql -h ${HOST} -p ${PORT} -U ${USERNAME} -d ${DBNAME} -xtA -c "SELECT pg_stat_statements_reset();" 2>&1 | sed -n '1p' | ts '[pg_profile]   '
#RC=$?
#echo "[pg_profile]  Reset Statements Stats. RC=${RC}"

#PGPASSWORD=${PASSWORD} psql -h ${HOST} -p ${PORT} -U ${USERNAME} -d ${DBNAME} -xtA -c "SELECT pg_stat_reset_shared('bgwriter');" 2>&1 | sed -n '1p' | ts '[pg_profile]   '
#RC=$?
#echo "[pg_profile]  Reset bgWriter Stats. RC=${RC}"

if [[ -v MAILSMTP ]]; then

# MAILSMTP='smtp.inbox.ru:465'
cmdsend=$(echo "mutt -e \"set content_type=text/html\" -e \"set send_charset=utf-8\" -e \"set allow_8bit=yes\" -e \"set move=no\" -e \"set use_ipv6=no\" \
  -e \"set from=\\\"${MAILLOGIN}\\\"\"  -e \"set realname=\\\"${MAILFROM}\\\"\" -e \"set smtp_authenticators=\\\"login\\\"\" \
  -e \"set smtp_url=smtps://\\\"${MAILLOGIN}\\\"@\\\"${MAILSMTP}\\\"\" 
  -e \"set smtp_pass=\\\"${MAILPWD}\\\"\" -e \"set ssl_starttls=yes\" -e \"set ssl_force_tls=yes\" -e \"set ssl_verify_dates=no\" -e \"set ssl_verify_host=no\" \
  -s \"${SUBJTEXT}\" -a ${FILEREPORT} -- ${MAILTO}")
#echo ${cmdsend}

echo "${MSGTEXT}" | \
mutt -e "set content_type=text/html" -e "set send_charset=utf-8" -e "set allow_8bit=yes" -e "set move=no" -e "set copy=no" -e "set use_ipv6=no" \
  -e "set from=\"${MAILLOGIN}\"" -e "set realname=\"${MAILFROM}\"" -e "set smtp_authenticators=\"login\"" \
  -e "set smtp_url=smtps://\"${MAILLOGIN}\"@\"${MAILSMTP}\"" \
  -e "set smtp_pass=\"${MAILPWD}\"" -e "set ssl_starttls=yes" -e "set ssl_force_tls=yes" -e "set ssl_verify_dates=no" -e "set ssl_verify_host=no" \
  -s "${SUBJTEXT}" -a ${FILEREPORT} -- ${MAILTO} 2>&1 | ts '[pg_profile]   '
RC=$?
echo "[pg_profile]  Send ${REPORTNAME}. RC=${RC}"

fi

if [[ -v MAILSMTPURL ]]; then

# MAILSMTPURL='smtp://10.42.161.197:25'
cmdsend=$(echo "mutt -e \"set ssl_starttls=no\" -e \"set ssl_force_tls=no\" -e \"set content_type=text/html\" -e \"set send_charset=utf-8\" \
  -e \"set allow_8bit=yes\" -e \"set use_ipv6=no\" \
  -e \"set from=\\\"${MAILLOGIN}\\\"\" -e \"set realname=\\\"${MAILFROM}\\\"\" -e \"set smtp_url=\\\"${MAILSMTPURL}\\\"\" \
  -s \"${SUBJTEXT}\" -a ${FILEREPORT} -- ${MAILTO}")
#echo ${cmdsend}

echo "${MSGTEXT}" | \
mutt -e "set ssl_starttls=no" -e "set ssl_force_tls=no" -e "set content_type=text/html" -e "set send_charset=utf-8" \
  -e "set allow_8bit=yes" -e "set use_ipv6=no" -e "set move=no" -e "set copy=no" \
  -e "set from=\"${MAILLOGIN}\"" -e "set realname=\"${MAILFROM}\"" -e "set smtp_url=\"${MAILSMTPURL}\"" \
  -s "${SUBJTEXT}" -a ${FILEREPORT} -- ${MAILTO} 2>&1 | ts '[pg_profile]   '
RC=$?
echo "[pg_profile]  Send ${REPORTNAME}. RC=${RC}"

fi
