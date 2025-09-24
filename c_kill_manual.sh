#!/bin/bash
# c_kill_manual.sh
# Переменная $* содержит все параметры, введённые в командной строке, в виде единого «слова».
# В переменной $@ параметры разбиты на отдельные «слова». Эти параметры можно перебирать в циклах.

procs=$*;
premsg='kill manual';

PGPASSWORD=${PASSWORD} psql -h ${HOST} -p ${PORT} -U ${USERNAME} -d pglogger -At -c " \
        INSERT INTO public.log_kills( \
                kill ,killer ,typekill ,ok \
                ,datid ,datname ,pid ,usesysid ,usename ,application_name ,client_addr ,client_hostname ,client_port \
                ,backend_start ,xact_start ,query_start ,state_change ,wait_event_type ,wait_event ,state ,backend_xid ,backend_xmin ,backend_type ,query) \
        SELECT clock_timestamp() as kill \
                ,session_user as killer \
                ,'terminate' as typekill \
                ,pg_terminate_backend(pid) as ok \
                ,datid ,datname ,pid ,usesysid ,usename ,application_name ,client_addr ,client_hostname ,client_port \
                ,backend_start ,xact_start ,query_start ,state_change ,wait_event_type ,wait_event ,state ,backend_xid ,backend_xmin ,backend_type ,query \
        FROM pg_catalog.pg_stat_activity \
        WHERE pid in ( ${procs} ) \
			AND backend_type = 'client backend' \
			AND pid <> pg_backend_pid() \
        ;" &>&1 | ts "[${premsg}] " ;
