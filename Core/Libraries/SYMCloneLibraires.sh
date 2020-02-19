#!/usr/bin/env bash
# Header_start
##############################################################################################
#                                                                                            #
#  Author:         Alfred TCHONDJO - (Iriven France)   Pour Orange                           #
#  Date:           2020-01-18                                                                #
#  Website:        https://github.com/iriven?tab=repositories                                #
#                                                                                            #
# ------------------------------------------------------------------------------------------ #
#                                                                                            #
#  Project:        SYMClone                                                                  #
#  Description:    EMC Symmetrix Device Clone Tool written in bash.                          #
#  Version:        1.0.0    (G1R0C0)                                                         #
#                                                                                            #
#  License:      GNU GPLv3                                                                   #
#                                                                                            #
#  This program is free software: you can redistribute it and/or modify                      #
#  it under the terms of the GNU General Public License as published by                      #
#  the Free Software Foundation, either version 3 of the License, or                         #
#  (at your option) any later version.                                                       #
#                                                                                            #
#  This program is distributed in the hope that it will be useful,                           #
#  but WITHOUT ANY WARRANTY; without even the implied warranty of                            #
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the                             #
#  GNU General Public License for more details.                                              #
#                                                                                            #
#  You should have received a copy of the GNU General Public License                         #
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.                     #
#                                                                                            #
# ------------------------------------------------------------------------------------------ #
#  Revisions                                                                                 #
#                                                                                            #
#  - G1R0C0 :        Creation du script le 18/01/2020 (AT)                                   #
#                                                                                            #
##############################################################################################
# Header_end
# set -x
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
then
  printf "\\n%s is a part of bash Fylesystem Backup Libraries file. Dont execute it directly!\\n\\n" "${0##*/}"
  exit 1
fi
#-------------------------------------------------------------------
#               DECLARATION DES FUNCTIONS
#-------------------------------------------------------------------
function require()
{
   local filepath="$1"
   if [ ! -f "${filepath}" ]; then
        [[ $(basename ${filepath}) =~ ^.cred* ]] || echo "Le fichier ${filepath} est introuvable!"
        exit 1
   fi
}

function isBoolean()
{  
	  [ $# -ne 1 -o -z "$1" ] && printf "Usage: ${0} [string STRING]" && exit 1
	  local input=$(echo "$1"|tr '[A-Z]' '[a-z]')
	  case "$input" in
	  '0'|'1'|'true'|'false') return 0;;
	  *) return 1 ;;
	  esac          
}

function isRoot()
{
  local username="${1:-$(whoami)}"
  [ -z "${username}" ] && return 1
  grep -i "^${username}:" /etc/passwd >/dev/null 2>&1 || return 1
  local gid=$(id -g "${username}")
  local uid=$(id -u "${username}")
  [ ${gid} -ne 0 ] &&  return 1
  [ ${uid} -ne 0 ] &&  return 1 || return 0

}

function inArray()
{
	[ $# -ne 2 -a $# -ne 3 ] && printf "Usage: ${0} [string STRING] [array ARRAY] [(optional) char SEPARATOR]" && exit 1
	local string="$1" inputArray IFS="${3:- }"
	read -ra inputArray <<< "$2"
	case "${IFS}${inputArray[*]}${IFS}" in
	*"${IFS}${string}${IFS}"*) return 0;;
	*) return 1 ;;
	esac
}

function numberCompare()
{
   local expression1=$1 expression2=$2 operator=$3
   case $operator in
      ">"|">="|"<"|"<="|"=");;
      *)operator=">";;
   esac
   local result=$(echo "${expression1} ${operator} ${expression2}"| bc -q 2>/dev/null)
   case $result in
      0|1);;
      *)result=0;;
   esac
   local stat=$((result == 0))
   return $stat
}

function ValidateUserSettings()
{
   local filepath="$1"
   local syntax="(^\s*#|^\s*$|^\s*[a-zA-Z_]+=[^',;&]*$)"
   require "${filepath}"
   if egrep -q -v "${syntax}" "${filepath}"; then
      printf " \e[31m %s \n\e[0m" "Erreur de configuration." >&2
      printf " \e[31m %s \n\e[0m" "Cette ligne du fichier de configuration contient des caractères inapropriés"
      egrep -vn "${syntax}" "${filepath}"
      exit 5
   fi
}

function writeLog()
{
   [ $# -lt 1 -o -z "$1" ] && printf "Usage:  [string MSG] [string LEVEL]" && exit 1
   local msg=$1 level=${2:-error}
   case ${level} in
      info) msg="INFO: ${msg}";logger -p local7.info -t bootalt ${msg} ;;
      *) msg="ERROR: ${msg}";logger -p local7.err -t bootalt ${msg} ;;
   esac
   local EVNTDATE=$(date +'%F %X')
   if [ "${level}" == "error" ] 
   then
      printf " \e[31m %s \n\e[0m" "${EVNTDATE}: $msg" 1>&2
      exit -1
   else
      printf " %s \n" "${EVNTDATE}: $msg" 1>&2
   fi
}

function strLen()
{
  local string="${1}"
  local length=$(printf "%s" "${string}" | wc -c)
  echo ${length}
}

function StorageArrayExists()
{
	local sid="${1}"
	[[ "${sid}" =~ ^[0-9]+$ ]] || return 1
	local StoragArrayID=$(symcfg list |grep "${sid} "|awk '{print $1;}')
	case "${StoragArrayID}" in *${sid}) return 0 ;; esac
	return 1
}

function DeviceExists(){
	local lunid="${1}"
	local sid="${2}"
	symdev -sid "${sid}" show "${lunid}" >/dev/null 2>&1
	[ $? -eq 0 ] && return 0 || return 1
}

function dgExists(){
	local dgname="${1}"
	[ -z "${dgname}" ] && return 1
	symdg show "${dgname}" >/dev/null 2>&1
	[ $? -eq 0 ] && return 0 || return 1
}

function isDGMember(){
	local lunid="${1}"
	local dgname="${2}"
	local check=$(symdg show "${dgname}" |grep -iw "${lunid}")
	[ -z "${check}" ] && return 1 || return 0
}

function SGExists(){
	local sgname="${1}"
	local sid="${2}"
	[ -z "${sgname}" ] && return 1
	local check=$(symaccess -sid "${sid}" list -type storage |grep -iw "${sgname}")
	[ -z "${check}" ] && return 1 || return 0
}

function getDeviceSize(){
	local lunid="${1}"
	local sid="${2}"
	symdev -sid ${sid} list -devs ${lunid} -cyl|grep -iw ${lunid}|awk '{print $NF;}'
}

function IsStorageGroupMember(){
	local lunid="${1}"
	local sgname="${2}"
	local sid="${3}"
	[ -z "${lunid}" ] && return 1
	[ -z "${sgname}" ] && return 1
	local check=$(symdev -sid ${sid} list -sg "${sgname}" |grep -iw "${lunid}")
	[ -z "${check}" ] && return 1 || return 0	
}

function CloneSessionStatus(){
  local dgname="${1}"
  local status="inprogress"
  symclone -g "${dgname}" -Copied verify  >/dev/null 2>&1
  [ $? -eq 0 ] && status="finished"
  echo "${status}"
}
