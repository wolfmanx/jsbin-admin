#!/bin/sh

# jsbin.sh - administrate jsbin database

# usage: jsbin.sh [OPTIONS] [ACTION [args]]

# OPTIONS
#   -q, --quiet                           do not show commands
#   -v, --verbose                         show commands
#   -d, --debug                           show commands only, do not execute
#
#   -h, --host            HOST            MySQL host
#                                         (config: DB_HOST, localhost)
#   -u, --user            USER            MySQL user for database access
#                                         ($MYSQL_USER, config: DB_USER, jsbin)
#   -p, --password        PASSWORD        MySQL password for database access
#                                         ($MYSQL_PASSWORD,
#                                         config: DB_PASSWORD, jsbin-000)
#   -d, --database        DATABASE        MySQL database
#                                         (config: DB_NAME, jsbin)
#
# If --user '' and/or --password '' are specified, the --user and/or
# --password option are not supplied to mysql command.
#
#
#   --admin-user          USER            admin user for install
#                                         ($DB_ADMIN_USER, $MYSQL_USER,
#                                         config: DB_USER, jsbin)
#   --admin-password      PASSWORD        admin user password for install
#                                         ($DB_ADMIN_PASSWORD, $MYSQL_PASSWORD,
#                                         config: DB_PASSWORD, jsbin-000)
#
# ACTIONS
#   <no action>                           list all urls
#   l[s], l[ist], s[how]  [url, ...]      list (all) urls
#
#   f[lush]               [url, ...]      remove old revisions of (all) url(s)
#   j[s]                  [url, ...]      dump JavaScript for (all) url(s)
#   ht[ml]                [url, ...]      dump HTML for (all) url(s)
#
#   m[v], ren[ame]        from to         rename url FROM to TO
#   c[p], c[opy]          from to         copy url FROM to TO
#   rm, del[ete]          url, ...        delete url(s)
#   rm, del[ete]          '*'             delete all url(s)
#
#   b[ackup]              [-d, --dir dir] [file]
#                                         dump database into FILE
#                                         (jsbin-NNNNN.sql) in DIR (.)
#   res[tore]             [-d, --dir dir] [file]
#                                         restore database from FILE
#                                         (jsbin-NNNNN.sql) in DIR (.)
#
#   install               [OPTIONS]       setup, configure and install everything
#                                         With -f, --force, drop database.
#                                         With -r, --random, generate random password.
#                                         With -d, --debug, force OFFLINE mode.
#
#   h[elp]                                show this help.
#
# INSTALLATION DETAILS
#   set-config            [OPTIONS]       copy configuration files
#                                         into jsbin tree.
#                                         With -q, --quiet, do not fail,
#                                         if jsbin-config is not
#                                         found.
#                                         With -f, --force, overwrite existing files.
#   configure                             configure jsbin according to .config.rc
#   make                                  make jsbin compressed script
#   installas                             install admin script
#   installa2                             install apache2 configuration
#   installdb             [-f, --force]   install database and create user.
#                                         With --force, drop database.
#
# DEVELOPER ACTIONS
#
#   get-config                            copy configuration files
#                                         from source tree to
#                                         configuration directory.

# Copyright (C) 2012, Wolfgang Scherer, <Wolfgang.Scherer at gmx.de>
# Sponsored by WIEDENMANN SEILE GMBH, http://www.wiedenmannseile.de
#
# This file is part of Wiedenmann Utilities.
#
# See MIT-LICENSE.TXT for conditions.
:  # script help

# --------------------------------------------------
# |||:sec:||| CONFIGURATION
# --------------------------------------------------

unset LANG
unset LANGUAGE
LC_CTYPE=C
export LC_CTYPE

prog_path="${0}"
prog_dir="$( dirname "${prog_path}" )"
prog_name="$( basename "${prog_path}" )"
case "${prog_dir}" in
/*) :;;
*)
    prog_dir="$( cd "${prog_dir}"; pwd )"
    prog_path="${prog_dir}/${prog_name}"
    ;;
esac

inst_path="$( readlink "${prog_path}" )"
if test -n "${inst_path}"
then
    inst_dir="$( dirname "${inst_path}" )"
    inst_name="$( basename "${inst_path}" )"
    case "${inst_dir}" in
    /*) :;;
    *)
        inst_dir="$( cd "${prog_dir}/${inst_dir}"; pwd )"
        inst_path="${inst_dir}/${inst_name}"
        ;;
    esac
else
    inst_path="${prog_path}"
    inst_dir="${prog_dir}"
    inst_name="${prog_name}"
fi

# printf >&2 "# |"":DBG:| %-${dbg_fwid-15}s: [%s]\n" "prog_path" "${prog_path}"
# printf >&2 "# |"":DBG:| %-${dbg_fwid-15}s: [%s]\n" "prog_dir" "${prog_dir}"
# printf >&2 "# |"":DBG:| %-${dbg_fwid-15}s: [%s]\n" "prog_name" "${prog_name}"
# printf >&2 "# |"":DBG:| %-${dbg_fwid-15}s: [%s]\n" "inst_path" "${inst_path}"
# printf >&2 "# |"":DBG:| %-${dbg_fwid-15}s: [%s]\n" "inst_dir" "${inst_dir}"
# printf >&2 "# |"":DBG:| %-${dbg_fwid-15}s: [%s]\n" "inst_name" "${inst_name}"
# exit

INST_DIR="${INST_DIR-${inst_dir}}"

test -r "${INST_DIR}/.config.rc-default" && . "${INST_DIR}/.config.rc-default"
test -r "${INST_DIR}/.config.rc" && . "${INST_DIR}/.config.rc"

# autoconf compatibility
DESTDIR="${DESTDIR-}"

A2ENMOD="${A2ENMOD-a2enmod}"
APACHE_CONF_D="${DESTDIR}${APACHE_CONF_D-/etc/apache2/conf.d}"
BIN_DIR="${DESTDIR}${BIN_DIR-/usr/local/bin}"

MYSQL="${MYSQL-mysql}"
MYSQL_DUMP="${MYSQL_DUMP-mysqldump}"
MYSQL_HEADER="${MYSQL_HEADER-
SET character_set_client = utf8;
SET NAMES utf8;
SET NAMES utf8;
SET foreign_key_checks = 0;
}"

DB_HOST="${DB_HOST-localhost}"
DB_USER="${DB_USER-jsbin-user}"
DB_PASSWORD="${DB_PASSWORD-jsbin-000}"
DB_NAME="${DB_NAME-jsbin}"

JSBIN_DIR="${JSBIN_DIR-${OFFLINE}}"
if test -z "${JSBIN_DIR}"
then
    JSBIN_DIR="${INST_DIR}"
    test -r "${JSBIN_DIR}/jsbin/index.php" && JSBIN_DIR="${JSBIN_DIR}/jsbin"
fi
JSBIN_CONFIG_DIR="${JSBIN_CONFIG_DIR-${INST_DIR}/jsbin-config}"

DEFAULT_CONFIG_VARIABLES='
DB_HOST=
DB_USER=
DB_PASSWORD=
DB_NAME=
HOST=
OFFLINE=
ROOT_=
ROOT=
'

# --------------------------------------------------
# |||:sec:||| FUNCTIONS
# --------------------------------------------------

usage ()
{
    script_help="script-help"
    ( "${script_help}" ${1+"$@"} "${0}" ) 2>/dev/null \
    || ${SED__PROG-sed} -n '3,/^[^#]/{;/^[^#]/d;p;}' "${0}";
}

# -*- sh -*-
## |:lst:| sed_script_sed_protect
# --------------------------------------------------
# Print sed script to protect a string against right side of sed(1)
# `s' command.

# sed_script_sed_protect [S-FIELD-DELIMITER]

# S-FIELD-DELIMITER defaults to comma `,'.

# 1. Replace all backslashes with double-backslashes
# 2. Replace delimiter with backslash + delimiter
# 3. Replace `&' with backslash + `&', if delimiter != `&'
sed_script_sed_protect ()
{
    __shf_ssqs_delim="${1-,}"
    __shf_ssqs_DELIM="/"
    test x"${__shf_ssqs_delim}" = x'/' && __shf_ssqs_DELIM=,
    __shf_ssqs_dlm_subst='s,&,\\\&,g'
    test x"${__shf_ssqs_delim}" = x'&' && __shf_ssqs_dlm_subst=
    cat <<FUNDAMENTAL
s,\\\\,\\\\\\\\,g
s${__shf_ssqs_DELIM}${__shf_ssqs_delim}${__shf_ssqs_DELIM}\\\\${__shf_ssqs_delim}${__shf_ssqs_DELIM}g
${__shf_ssqs_dlm_subst}
\$q
s,\$,\\\\,
FUNDAMENTAL
    unset __shf_ssqs_delim __shf_ssqs_DELIM
}
## |:lst:|

## |:lst:| sed_protect
# --------------------------------------------------
# Protect a string against right side of sed(1) `s' command.

# sed_protect STRING [S-FIELD-DELIMITER]

# S-FIELD-DELIMITER defaults to comma `,'.

# 1. Replace all backslashes with double-backslashes
# 2. Replace delimiter with backslash + delimiter
# 3. Replace `&' with backslash + `&', if delimiter != `&'
sed_protect ()
{
    __shf_sqs_string="${1}"
    __shf_sqs_delim="${2-,}"
    if test x"${__shf_sqs_delim}" = x,
    then
        __shf_sqs_script="${SED_SCRIPT_SED_PROTECT}"
    else
        __shf_sqs_script="`sed_script_sed_protect "${__shf_sqs_delim}"`"
    fi
    printf "%s\n" "${__shf_sqs_string}" | ${SED__PROG-sed} "${__shf_sqs_script}"
    unset __shf_sqs_string __shf_sqs_delim __shf_sqs_script
}

# Pre-fabricated sed(1) scripts
SED_SCRIPT_SED_PROTECT="`sed_script_sed_protect`"
SED_SCRIPT_SED_PROTECTA="`sed_script_sed_protect /`"
## |:lst:|

make_config_script ()
{

    configuration="$(
cat "${INST_DIR}/.config.rc-default" 2>/dev/null;
cat "${INST_DIR}/.config.rc" 2>/dev/null;
)"
    if test -z "${configuration}"
    then
        configuration="${DEFAULT_CONFIG_VARIABLES}"
    fi

    (
    printf "%s\n" 'JSBIN_DIR='
    printf "%s\n" 'INST_DIR='
    printf "%s\n" "${configuration}"
    ) \
    | ${SED_SCRIPT-sed} '
s,^\([0-9A-Za-z_][0-9A-Za-z_]*\)=.*,\1,p
d
' \
    | ${SORT_PROG-sort} \
    | ${UNIQ_PROG-uniq} \
    | (
    SUBST_AT=
    while read config_var
    do
        # skip blank lines and comments
        case "${config_var}" in
        ''|"${comm-#}"*) continue;;
        esac
        eval config_value=\"\${${config_var}}\"
        SUBST_AT="${SUBST_AT}
s,@${config_var}@,$( sed_protect "${config_value}" ),g"
    done
    printf "%s\n" "${SUBST_AT}"
    )
}

echon ()
{
    printf "%s" "${*}"
}

pecho ()
{
    printf "%s\n" "${*}"
}

vmsg ()
{
    ( test -z "${opt_verbose-}" || test ${opt_verbose} -gt 0 ) && pecho ${1+"$@"}
}

tmsg ()
{
    vmsg >&2 ${1+"$@"}
}

dmsg ()
{
    test -n "${ECHO}" && tmsg ${1+"$@"}
}

vexec ()
{
    test -z "${ECHO}" && vmsg ${1+"$@"}
    ${ECHO} ${1+"$@"}
}

vexec_no_error ()
{
    vmsg ${1+"$@"} '2>/dev/null'
    test -z "${ECHO}" && ${1+"$@"} 2>/dev/null
}

texec ()
{
    test -z "${ECHO}" && tmsg ${1+"$@"}
    ${ECHO} ${1+"$@"}
}

texec_no_error ()
{
    tmsg ${1+"$@"} '2>/dev/null'
    test -z "${ECHO}" && ${1+"$@"} 2>/dev/null
}

write_to ()
{
    (
    if test -z "${ECHO}"
    then
        cat - >"${1}"
    else
        vmsg "$( printf "%s >%s" "$( cat - )" "${1}" )"
    fi
    )
}

write_toto ()
{
    (
    if test -z "${ECHO}"
    then
        cat - >>"${1}"
    else
        vmsg "$( printf "%s >>%s" "$( cat - )" "${1}" )"
    fi
    )
}

join_strings ()
{
    sep="${1-}"
    test x"${1+set}" = xset && shift
    result=
    csep=
    for str in ${1+"$@"}
    do
        result="${result}${csep}${str}"
        csep="${sep}"
    done
    printf "%s\n" "${result}"
}

join_input ()
{
    sep="${1-}"
    test x"${1+set}" = xset && shift
    result=
    csep=
    while read str
    do
        result="${result}${csep}${str}"
        csep="${sep}"
    done
    printf "%s\n" "${result}"
}

mysql_set_credentials ()
{
    db_host="${DB_HOST}"
    test x"${MYSQL_HOST+set}" = xset && db_host="${MYSQL_HOST}"
    db_user="${DB_USER}"
    test x"${MYSQL_USER+set}" = xset && db_user="${MYSQL_USER}"
    db_password="${DB_PASSWORD}"
    test x"${MYSQL_PASSWORD+set}" = xset && db_password="${MYSQL_PASSWORD}"
}

mysql_set_options ()
{
    host_opt=
    user_opt=
    password_opt=
    test -n "${db_host}" && host_opt=--host
    test -n "${db_user}" && user_opt=--user
    test -n "${db_password}" && password_opt=--password=
}

mysql_cmd ()
{
    script="$( cat - )"
    mysql_set_credentials
    mysql_set_options
    printf "%s\n" "${script}" \
    | texec ${MYSQL} ${host_opt} ${db_host} ${user_opt} ${db_user} ${password_opt}${db_password} "${CONN_DB_NAME-${DB_NAME}}" ${1+"$@"}
    test -n "${script}" && tmsg "${script}"
}

mysql_admin_cmd ()
{
    script="$( cat - )"

    mysql_set_credentials
    test x"${DB_ADMIN_USER+set}" = xset && db_user="${DB_ADMIN_USER}"
    test x"${DB_ADMIN_PASSWORD+set}" = xset && db_password="${DB_ADMIN_PASSWORD}"
    mysql_set_options

    printf "%s\n" "${script}" \
    | texec ${MYSQL} ${host_opt} ${db_host} ${user_opt} ${db_user} ${password_opt}${db_password} "${CONN_DB_NAME-${DB_NAME}}" ${1+"$@"}
    test -n "${script}" && tmsg "${script}"
}

mysql_cmd_table ()
{
    mysql_cmd --table ${1+"$@"}
}

mysql_cmd_value ()
{
    mysql_cmd --skip-column-names ${1+"$@"}
}

# |:here:|

show_bins ()
{
    urls="$( join_strings "', '" ${1+"$@"} )"
    WHERE=
    test -n "${urls}" && WHERE=' WHERE url in ('"'${urls}'"')'
    mysql_cmd_table <<EOF
-- show available bins
SELECT
  url, name, MAX(revision) AS revision
 FROM owners
${WHERE}
 GROUP BY url
 ORDER BY url
 ;
EOF
}

show_field ()
{
    field="${1-}"
    url="${2-}"
    WHERE=
    test -n "${url}" && WHERE="WHERE url = '${url}'"
    mysql_cmd_value --raw <<EOF | ${TR__PROG-tr} -d '\r'
SELECT
  ${field}
 FROM sandbox
${WHERE}
 ORDER BY revision DESC
 LIMIT 1
 ;
EOF
}

show_js ()
{
    url="${1-}"
    printf >&2 "// |"":JS:| %-${dbg_fwid-15}s: [%s]\n" "url" "${url}"
    show_field 'javascript' "${url}"
}

show_html ()
{
    url="${1-}"
    printf >&2 "<!-- |"":HTML:| %-${dbg_fwid-15}s: [%s] -->\n" "url" "${url}"
    show_field 'html' "${url}"
}

get_urls ()
{
    mysql_cmd_value <<'EOF'
-- show last revision for a bin
SELECT DISTINCT
  url
 FROM owners
 ORDER BY url
 ;
EOF
}

last_revision ()
{
    url="${1}"
    mysql_cmd_value <<EOF
-- show last revision for a bin
SELECT
  MAX(revision) AS revision
 FROM owners
 WHERE url='${url}'
 GROUP BY url
 ORDER BY url
 ;
EOF
}

flush_old ()
{
    url="${1}"
    last_rev="$( ECHO= opt_verbose=0 last_revision "${url}" )"
    printf >&2 "# |"":DBG:| %-${dbg_fwid-15}s: [%s] [%s]\n" "url/last_rev" "${url}" "${last_rev}"

    if test -n "${last_rev}" && test ${last_rev} -gt 1
    then
        mysql_cmd <<EOF
DELETE
 FROM owners
 WHERE url='${url}' AND revision > 1
 ;
DELETE
 FROM sandbox
 WHERE url='${url}' AND revision < ${last_rev}
 ;
UPDATE sandbox
 SET revision = 1
 WHERE url='${url}' AND revision = ${last_rev}
 ;
EOF
    fi
}

rename_url ()
{
    url_from="${1}"
    url_to="${2}"

    to_exists="$( ECHO= opt_verbose=0 mysql_cmd_value <<EOF
SELECT url
 FROM owners
 WHERE url='${url_to}'
 LIMIT 1
 ;
EOF
 )"
    if test -n "${to_exists}"
    then
        printf >&2 "error: destination url \`%s\` exists\n" "${url_to}"
        exit 1
    fi

    mysql_cmd <<EOF
UPDATE owners
 SET url='${url_to}'
 WHERE url='${url_from}'
 ;
UPDATE sandbox
 SET url='${url_to}'
 WHERE url='${url_from}'
 ;
EOF
}

table_columns ()
{
    table="${1-}"
    sed_filter="${2-}"
    #  --raw
    mysql_cmd_value <<EOF \
| ${AWK__PROG-awk} '{ print $1; }' \
| ${SED__PROG-sed} "${sed_filter}" \
| join_input ', '
SHOW COLUMNS FROM ${table};
EOF
}

copy_url ()
{
    url_from="${1}"
    url_to="${2}"

    to_exists="$( ECHO= opt_verbose=0 mysql_cmd_value <<EOF
SELECT url
 FROM owners
 WHERE url='${url_to}'
 LIMIT 1
 ;
EOF
 )"
    if test -n "${to_exists}"
    then
        printf >&2 "error: destination url \`%s\` exists\n" "${url_to}"
        exit 1
    fi

    owners_columns="$( table_columns owners '/^id$/d' )"
    sandbox_columns="$( table_columns sandbox '/^id$/d' )"

    mysql_cmd <<EOF
CREATE TEMPORARY TABLE c_owners LIKE owners;
CREATE TEMPORARY TABLE c_sandbox LIKE sandbox;

TRUNCATE c_owners;
TRUNCATE c_sandbox;

INSERT INTO c_owners
 SELECT *
  FROM owners
  WHERE url='${url_from}'
  ORDER BY id
  ;
INSERT INTO c_sandbox
 SELECT *
  FROM sandbox
  WHERE url='${url_from}'
  ORDER BY id
  ;

UPDATE c_owners
 SET url='${url_to}'
 WHERE url='${url_from}'
 ;
UPDATE c_sandbox
 SET url='${url_to}'
 WHERE url='${url_from}'
 ;

INSERT INTO
   owners ( ${owners_columns} )
 SELECT ${owners_columns}
  FROM c_owners
  ORDER BY id
  ;

INSERT INTO
   sandbox ( ${sandbox_columns} )
 SELECT ${sandbox_columns}
  FROM c_sandbox
  ORDER BY id
  ;
EOF
}

delete_url ()
{
    url="${1}"
    if test x"${url}" = x'*'
    then
        mysql_cmd <<EOF
TRUNCATE owners;
TRUNCATE sandbox;
EOF
    else
        mysql_cmd <<EOF
DELETE
 FROM owners
 WHERE url='${url}'
 ;
DELETE
 FROM sandbox
 WHERE url='${url}'
 ;
EOF
    fi
}

user_add ()
{
    user="${1}"
    password="${1}"
    mysql_cmd <<EOF
REPLACE
  INTO ownership (name, \`key\`)
  VALUES ('${user}', PASSWORD('${password}'))
  ;
EOF
}

jsbin_configure ()
{
    opt_configure_debug=0
    case "${1-}" in
    -f|--f*) # --force
       opt_configure_debug=1
       shift;;
    esac

    if test ${opt_configure_debug} = 1
    then
        test -z "${OFFLINE}" && OFFLINE="${JSBIN_DIR}"
    fi

    SUBST_AT="$( make_config_script )"
    tmsg "$( printf "# |"":INF:| %-${dbg_fwid-15}s: [%s]\n" "SUBST_AT" "${SUBST_AT}" )"

    (
    if test x"${1+set}" = xset
    then
        for template in ${1+"$@"}
        do
            printf "%s\n" "${template}"
        done
    else
        ${LS___PROG-ls} -1 "${INST_DIR}"/*.in
        ${FIND_PROG-find} "${JSBIN_DIR}" -name '*.in' -print
    fi
    ) \
    | ${SORT_PROG-sort} \
    | ${UNIQ_PROG-uniq} \
    | (
    while read in_file
    do
        # skip blank lines and comments
        case "${in_file}" in
        ''|"${comm-#}"*) continue;;
        esac
        test -r "${in_file}" || exit 1
        dst_file="$( printf "%s\n" "${in_file}" | ${SED__PROG-sed} 's,[.]in$,,' )"
        if test x"${in_file}" = x"${dst_file}"
        then
            printf >&2 "internal error: in_file == dst_file: \`%s\`\n" "${in_file}"
            exit 1
        fi
        if test -z "${ECHO}"
        then
            texec ${SED__PROG-sed} "${SUBST_AT}" "${in_file}" >"${dst_file}"
        else
            texec ${SED__PROG-sed} '"${SUBST_AT}"' "${in_file}" ">${dst_file}"
        fi
    done
    )
}

jsbin_make ()
{
    (
        texec cd "${JSBIN_DIR}" || exit 1
        texec ${MAKE_PROG-make}
    )
}

jsbin_install_as ()
{
    script_base="$( printf "%s\n" "${DB_NAME}" | ${SED__PROG-sed} 's,_,-,g' )"
    test -r "${INST_DIR}/jsbin-admin" || jsbin_configure "${INST_DIR}/jsbin-admin.in"
    texec ${CP___PROG-cp} -p "${INST_DIR}/jsbin-admin" "${BIN_DIR}/${script_base}-admin"
    texec ${CHMODPROG-chmod} 755 "${BIN_DIR}/${script_base}-admin"
}

jsbin_install_a2 ()
{
    texec ${A2ENMOD-a2enmod} rewrite
    texec ${CP___PROG-cp} -p "${INST_DIR}/jsbin.conf" "${APACHE_CONF_D}/${DB_NAME}.conf"
    texec ${SERVICE-service} apache2 restart
}

jsbin_install_db ()
{
    opt_force=0
    case "${1-}" in
    -f|--f*) # --force
       opt_force=1;;
    esac

    if test ${opt_force} = 1
    then
        # forcibly drop database
	(
	export CONN_DB_NAME='mysql'
        mysql_admin_cmd <<EOF
${MYSQL_HEADER}
DROP DATABASE /*! IF EXISTS */ ${DB_NAME};
EOF
	)
    fi

    # create database
    (
    export CONN_DB_NAME='mysql'
    mysql_admin_cmd <<EOF
${MYSQL_HEADER}
CREATE DATABASE /*! IF NOT EXISTS */ ${DB_NAME};
EOF
    )

    # drop user
    mysql_admin_cmd <<EOF
${MYSQL_HEADER}
DROP USER '${DB_USER}'@'${DB_HOST}';
EOF

    # create user
    mysql_admin_cmd <<EOF
${MYSQL_HEADER}
CREATE USER '${DB_USER}'@'${DB_HOST}' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL
 ON ${DB_NAME}.*
 TO '${DB_USER}'@'${DB_HOST}';
EOF

    if test ! -r "${JSBIN_DIR}/index.php"
    then
        printf >&2 "error: JSBIN_DIR not found\n"
        exit 1
    fi

    # fill database
    if test -r "${JSBIN_DIR}/build/full-db-v3.mysql.sql"
    then
	script="${JSBIN_DIR}/build/full-db-v3.mysql.sql"
    else
	script="${JSBIN_DIR}/build/jsbin.sql"
    fi
    mysql_admin_cmd <"${script}"
}

jsbin_get_config ()
{
    (
    cd "${JSBIN_DIR}" || exit 1
    jsbin_config_base="$( basename "${JSBIN_CONFIG_DIR}" )"

    ${FIND_PROG-find} '(' -name "${jsbin_config_base}" -prune ')' -o '(' -name '*.in' -print ')' \
    | ${SED__PROG-sed} 's,^\./,,' \
    | ${SORT_PROG-sort} \
    | (
    while read in_file
    do
        # skip blank lines and comments
        case "${in_file}" in
        ''|"${comm-#}"*) continue;;
        esac
        # ::fillme::
        dir="$( dirname "${in_file}" )"
        texec mkdir -p "${JSBIN_CONFIG_DIR}/${dir}"
        texec ${CP___PROG-cp} -p "${JSBIN_DIR}/${in_file}" "${JSBIN_CONFIG_DIR}/${in_file}"
    done
    )
    )
}

jsbin_set_config ()
{
    (
    opt_force=0
    exit_code=
    for arg in ${1+"$@"}
    do
        case "${arg}" in
        -q|-q*) # --quiet
            exit_code=0;;
        -f|-f*) # --force
            opt_force=1;;
        esac
    done

    test -n "${exit_code}" && test ! -d "${JSBIN_CONFIG_DIR}" && exit ${exit_code}
    cd "${JSBIN_CONFIG_DIR}" || exit ${exit_code}
    ${FIND_PROG-find} -name '*.in' -print \
    | ${SED__PROG-sed} 's,^\./,,' \
    | ${SORT_PROG-sort} \
    | (
    exit_code=0
    while read in_file
    do
        # skip blank lines and comments
        case "${in_file}" in
        ''|"${comm-#}"*) continue;;
        esac
        # ::fillme::
        dir="$( dirname "${in_file}" )"
        test ${opt_force} = 1 || test ! -r "${JSBIN_DIR}/${in_file}" || continue
        texec mkdir -p "${JSBIN_DIR}/${dir}"
        texec ${CP___PROG-cp} -p "${JSBIN_CONFIG_DIR}/${in_file}" "${JSBIN_DIR}/${in_file}"
        test x"${?}" = x0 || exit_code=1
    done
    exit ${exit_code}
    )
    real_exit_code="${?}"
    test -n "${exit_code}" || test x"${real_exit_code}" = x"0"
    )
}

set_backup_options ()
{
    backup_dir="."
    case "${1-}" in
    -d|--d*) # --dir
        shift
        backup_dir="${1}"
        shift;;
    esac
    file="${1-}"
}

goto_backup_dir ()
{
    if test -n "${ECHO}"
    then
        if test -d "${backup_dir}"
        then
            cd "${backup_dir}" 2>/dev/null || \
            file="$(  printf "%s-%05d%s\n" "${DB_NAME}" "99999" ".sql" )"
        fi
    fi
    texec mkdir -p "${backup_dir}"
    texec cd "${backup_dir}" || exit 1
}

set_backup_file ()
{
    if test -z "${file}"
    then
        last_seq="$( last_file_seq "${DB_NAME}-" ".sql" )"
        # 273.97260274 years worth of daily backups should be enough
        test -z "${last_seq}" && last_seq=100000
        next_seq="$( expr "${last_seq}" - 1 )"
        file="$(  printf "%s-%05d%s\n" "${DB_NAME}" "${next_seq}" ".sql" )"
    fi
}

last_file_seq ()
{
    pfx="${1-}"
    sfx="${2-}"
    ls -1 "${pfx}"*"${sfx}" 2>/dev/null | \
    ${SED__PROG-sed} '
s,^'"${pfx}"',,
s,'"${sfx}"'$,,
s,^00*$,0,
s,^00*\([^0]\),\1,
q
'
}

# |:here:|

# --------------------------------------------------
# |||:sec:||| OPTION PROCESSING
# --------------------------------------------------

ECHO=
opt_verbose=0
while :
do
    test x${1+set} = xset || break
    case "${1}" in
    -\?|--h*) # --help
        usage; exit 0;;
    -h|--h*) # --host
        shift
        MYSQL_HOST="${1}";;
    -u|--u*) # --user
        shift
        MYSQL_USER="${1}";;
    -p|--p*) # --password
        shift
        MYSQL_PASSWORD="${1}";;
    --admin-u*) # --admin-user
        shift
        DB_ADMIN_USER="${1}";;
    --admin-p*) # --admin-password
        shift
        DB_ADMIN_PASSWORD="${1}";;
    -d|--da*) # --database
        shift
        DB_NAME="${1}";;
    -q|--q*) # --quiet
        opt_verbose=0;;
    -v|--v*) # --verbose
        opt_verbose=1;;
    -d|--de*) # --debug
        opt_verbose=1
        ECHO='pecho';;
    --docu*) # --docu
        usage --full; exit 0;;
    --) # end of options
        shift; break;;
    -) # stdin
        break;;
    -*) # unknown option
        echo >&2 "`basename "${0}"`: error: unknown option \`${1}'"
        exit 1;;
    *) break;;
    esac
    shift
done

# --------------------------------------------------
# |||:sec:||| MAIN
# --------------------------------------------------

#ECHO='pecho'                   # |:debug:|

# |:here:|

action="${1-}"
test x"${1+set}" = xset && shift

case "${action}" in
l|ls|li|lis|list|s|sh|sho|show|'')
    show_bins ${1+"$@"}
    ;;
f|fl|flu|flus|flush)
    test x"${1+set}" = xset || set -- $( get_urls )
    for url in ${1+"$@"}
    do
        flush_old "${url}"
    done
    ;;
j|js)
    test x"${1+set}" = xset || set -- $( get_urls )
    for url in ${1+"$@"}
    do
        show_js "${url}"
    done
    ;;
ht|htm|html)
    test x"${1+set}" = xset || set -- $( get_urls )
    for url in ${1+"$@"}
    do
        show_html "${url}"
    done
    ;;
m[v]|mv|ren|rena|renam|rename)
    url_from="${1-}"
    url_to="${2-}"
    if test -z "${url_from}" || test -z "${url_to}"
    then
        printf >&2 "error: rename argument missing or empty\n"
        usage >&2
        exit 1
    fi
    rename_url "${url_from}" "${url_to}"
    ;;
c|cp|co|cop|copy)
    url_from="${1-}"
    url_to="${2-}"
    if test -z "${url_from}" || test -z "${url_to}"
    then
        printf >&2 "error: copy argument missing or empty\n"
        usage >&2
        exit 1
    fi
    copy_url "${url_from}" "${url_to}"
    ;;
rm|del|dele|delet|delete)
    if test x"${1+set}" != xset
    then
        printf >&2 "error: missing argument for delete\n"
        usage >&2
        exit 1
    fi
    for url in ${1+"$@"}
    do
        delete_url "${url}"
    done
    ;;
# |:todo:| not necessary and also broken
# u|us|use|user)
#     user="${1-}"
#     password="${2-}"
#     if test -z "${user}" || test -z "${password}"
#     then
#         printf >&2 "error: user argument missing or empty\n"
#         usage >&2
#         exit 1
#     fi
#     user_add "${user}" "${password}"
#     ;;
b|ba|bac|back|backu|backup)
    (
    set_backup_options ${1+"$@"}
    goto_backup_dir
    set_backup_file

    if test -r "${file}"
    then
        printf >&2 "error: \`%s\` already exists. Please, clean up.\n" "${file}"
        exit 1
    fi

    mysql_set_credentials
    test x"${DB_ADMIN_USER+set}" = xset && db_user="${DB_ADMIN_USER}"
    test x"${DB_ADMIN_PASSWORD+set}" = xset && db_password="${DB_ADMIN_PASSWORD}"
    mysql_set_options

    if test -z "${ECHO}"
    then
        texec ${MYSQL_DUMP} ${host_opt} ${db_host} ${user_opt} ${DB_USER} ${password_opt}${DB_PASSWORD} "${DB_NAME}" >"${file}"
    else
        texec ${MYSQL_DUMP} ${host_opt} ${db_host} ${user_opt} ${DB_USER} ${password_opt}${DB_PASSWORD} "${DB_NAME}" ">${file}"
    fi
    )
    ;;
res|rest|resto|restor|restore)
    (
    set_backup_options ${1+"$@"}
    goto_backup_dir
    set_backup_file

    if test ! -r "${file}"
    then
        printf >&2 "error: \`%s\` does not exist\n" "${file}"
        exit 1
    fi

    if test -z "${ECHO}"
    then
        mysql_cmd <"${file}"
    else
        mysql_cmd '<'"${file}" </dev/null
    fi
    )
    ;;
install)
    opt_force=''
    opt_configure_debug=''
    for arg in ${1+"$@"}
    do
        case "${arg}" in
        -d|--d) # --debug
            opt_configure_debug='--debug'
            ;;
        -r|--r) # --random-pass
            # |:info:| random password for package installation:
            DB_PASSWORD="$( ${HEAD_PROG-head} --bytes 50 </dev/urandom | ${MD5SUMPROG-md5sum} | ${CUT__PROG-cut} -d ' ' -f 1 )"
            test -z "${DB_PASSWORD}" && DB_PASSWORD="jsbin-${RANDOM-${$}}"
            if test -z "${ECHO}"
            then
                texec printf "DB_PASSWORD='%s'\n" "${DB_PASSWORD}" >> "${INST_DIR}/.config.rc"
            else
                texec printf "DB_PASSWORD='%s'\n" "${DB_PASSWORD}" ">> ${INST_DIR}/.config.rc"
            fi
            ;;
        -f|--f) # --force
            opt_force='--force'
            ;;
        esac
    done
    jsbin_set_config --quiet
    jsbin_configure ${opt_configure_debug}
    jsbin_make
    jsbin_install_as
    jsbin_install_a2
    jsbin_install_db ${opt_force}
    ;;
configure)
    jsbin_configure ${1+"$@"}
    ;;
make)
    jsbin_make ${1+"$@"}
    ;;
installas)
    jsbin_install_as ${1+"$@"}
    ;;
installa2)
    jsbin_install_a2 ${1+"$@"}
    ;;
installdb)
    jsbin_install_db ${1+"$@"}
    ;;
set-config)
    jsbin_set_config ${1+"$@"}
    ;;
get-config)
    # developer command
    jsbin_get_config
    ;;
h|he|hel|help)
    usage
    exit 0
    ;;
*)
    printf >&2 "error: unknown action \`%s\`\n" "${action}"
    usage >&2
    exit 1
    ;;
esac

exit # |||:here:|||

#
# :ide-menu: Emacs IDE Main Menu - Buffer @BUFFER@
# . M-x `eIDE-menu' (eIDE-menu "z")

# :ide: SNIP: insert OPTION LOOP
# . (snip-insert-mode "sh_b.opt-loop" nil t)

# :ide: SHELL: Run with --docu
# . (progn (save-buffer) (shell-command (concat "sh " (file-name-nondirectory (buffer-file-name)) " --docu")))

# :ide: SHELL: Run with --help
# . (progn (save-buffer) (shell-command (concat "sh " (file-name-nondirectory (buffer-file-name)) " --help")))

# :ide: SHELL: Run with --verbose ls hello jqui-dialog rfid-tabs
# . (progn (save-buffer) (shell-command (concat "sh " (file-name-nondirectory (buffer-file-name)) " --verbose ls hello jqui-dialog rfid-tabs")))

# :ide: SHELL: Run with js hello jqui-dialog rfid-tabs
# . (progn (save-buffer) (shell-command (concat "sh " (file-name-nondirectory (buffer-file-name)) " js hello jqui-dialog rfid-tabs")))

# :ide: SHELL: Run with html hello jqui-dialog rfid-tabs
# . (progn (save-buffer) (shell-command (concat "sh " (file-name-nondirectory (buffer-file-name)) " html hello jqui-dialog rfid-tabs")))

# :ide: SHELL: Run with --debug install
# . (progn (save-buffer) (shell-command (concat "sh " (file-name-nondirectory (buffer-file-name)) " --debug install")))

# :ide: SHELL: Run with --debug restore
# . (progn (save-buffer) (shell-command (concat "sh " (file-name-nondirectory (buffer-file-name)) " --debug restore")))

# :ide: SHELL: Run with --debug backup
# . (progn (save-buffer) (shell-command (concat "sh " (file-name-nondirectory (buffer-file-name)) " --debug backup")))

# :ide: SHELL: Run with --debug backup --dir /var/cache
# . (progn (save-buffer) (shell-command (concat "sh " (file-name-nondirectory (buffer-file-name)) " --debug backup --dir /var/cache")))

# :ide: SHELL: Run with --debug rename live live
# . (progn (save-buffer) (shell-command (concat "sh " (file-name-nondirectory (buffer-file-name)) " --debug rename live live")))

# :ide: SHELL: Run with backup
# . (progn (save-buffer) (shell-command (concat "sh " (file-name-nondirectory (buffer-file-name)) " backup")))

# :ide: SHELL: Run w/o args
# . (progn (save-buffer) (shell-command (concat "sh " (file-name-nondirectory (buffer-file-name)) "")))

#
# Local Variables:
# mode: sh
# comment-start: "#"
# comment-start-skip: "#+"
# comment-column: 0
# End:
# mmm-classes: (here-doc ide-entries)
