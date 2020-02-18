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
PATH="${PATH}:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin"
SYMCLONE_PROCESS_ID="${BASHPID}"
SYMCLONE_PROCESS_RUNTIME=$(date +'%Y%m%d')
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
then
  printf "\\n%s is a part of bash Fylesystem Backup Libraries file. Dont execute it directly!\\n\\n" "${0##*/}"
  exit 1
fi

#-------------------------------------------------------------------
#               DECLARATION DES VARIABLES
#-------------------------------------------------------------------

#  PARAMETRES DE CONFIGURATION
#----------------------------------------
: ${SYMCLONE_SCRIPTNAME:-SYMLunClone}
: ${SYMCLONE_ARRAY_SID:-}
: ${SYMCLONE_SOURCE_DEVICE:-}
: ${SYMCLONE_TARGET_DEVICE:-}
: ${SYMCLONE_SOURCE_DEVICE_SIZE:-}
: ${SYMCLONE_TARGET_DEVICE_SIZE:-}
: ${SYMCLONE_SOURCE_DEVICE_ALIAS:-SRC_VOL}
: ${SYMCLONE_TARGET_DEVICE_ALIAS:-TGT_VOL}
: ${SYMCLONE_DEVICEGROUP_NAME:-}
: ${SYMCLONE_COMMAND_SCOPE:-ENABLE}
: ${SYMCLONE_INPROGRESS_STATUS:-}
: ${SYMCLONE_TARGET_STORAGEGROUP:-}

#  SYSTEMES DE FICHIERS
#----------------------------------------
SYMCLONE_CONFIG_DIRECTORY="${SYMCLONE_BASE_DIRECTORY}/Config"
SYMCLONE_CONTROL_DIRECTORY="${SYMCLONE_CORE_DIRECTORY}/Ressources"
SYMCLONE_LIB_DIRECTORY="${SYMCLONE_CORE_DIRECTORY}/Libraries"
SYMCLONE_HELPER_DIRECTORY="${SYMCLONE_LIB_DIRECTORY}/Helpers"

SYMCLONE_CONFIG_FILE="${SYMCLONE_CONFIG_DIRECTORY}/Setup.conf"
SYMCLONE_ENV_FILE="${SYMCLONE_CONTROL_DIRECTORY}/.vars"
SYMCLONE_CONTROL_FILE="${SYMCLONE_CONTROL_DIRECTORY}/.credits"
SYMCLONE_LIB_FILE="${SYMCLONE_LIB_DIRECTORY}/SYMCloneLibraries.sh"
SYMCLONE_PID_FILE="/var/run/${SYMCLONE_SCRIPTNAME}"
export PATH="${PATH}:${SYMCLONE_BASE_DIRECTORY}"
export SYMAPI_COMMAND_SCOPE="${SYMCLONE_COMMAND_SCOPE}"

#-------------------------------------------------------------------
#               DEBUT DU TRAITEMENT
#-------------------------------------------------------------------

if [ ! -f "${SYMCLONE_LIB_FILE}" ]; then
   printf " \e[31m %s \n\e[0m" "Blibliotheque de fonction introuvable!" 
   exit 1 
fi
. ${SYMCLONE_LIB_FILE}

require ${SYMCLONE_CONTROL_FILE}
require ${SYMCLONE_CONFIG_FILE}
require ${SYMCLONE_ENV_FILE}

ValidateUserSettings "${SYMCLONE_CONFIG_FILE}"
. ${SYMCLONE_CONFIG_FILE}
. ${SYMCLONE_CONTROL_FILE}
. ${SYMCLONE_ENV_FILE}

[ -z "${SYMCLONE_ARRAY_SID}" ]   			&& writeLog "Parametre SYMCLONE_ARRAY_SID manquant";
[ -z "${SYMCLONE_SOURCE_DEVICE}" ]   		&& writeLog "Parametre SYMCLONE_SOURCE_DEVICE manquant";
[ -z "${SYMCLONE_TARGET_DEVICE}" ]   		&& writeLog "Parametre SYMCLONE_TARGET_DEVICE manquant";
[ -z "${SYMCLONE_SOURCE_DEVICE_ALIAS}" ]   	&& writeLog "Parametre SYMCLONE_SOURCE_DEVICE_ALIAS manquant";
[ -z "${SYMCLONE_TARGET_DEVICE_ALIAS}" ]   	&& writeLog "Parametre SYMCLONE_TARGET_DEVICE_ALIAS manquant";
[ -z "${SYMCLONE_DEVICEGROUP_NAME}" ]   	&& writeLog "Parametre SYMCLONE_DEVICEGROUP_NAME manquant";
[ -z "${SYMCLONE_TARGET_STORAGEGROUP}" ]    && writeLog "Parametre SYMCLONE_TARGET_STORAGEGROUP manquant";

# PARAMETER VALIDATION
#-----------------------------------------
writeLog "VALIDATION DES PARAMETRES DE CONFIGURATION" "info";

[ $(strLen "${SYMCLONE_ARRAY_SID}") -lt 8 ] && writeLog "Le Parametre SYMCLONE_ARRAY_SID doit avoir au moins 8 caractere";
StorageArrayExists "${SYMCLONE_ARRAY_SID}" || writeLog "L'Identifiant de la baie est invalide: ${SYMCLONE_ARRAY_SID}";

DeviceExists "${SYMCLONE_SOURCE_DEVICE}" "${SYMCLONE_ARRAY_SID}"    || writeLog "La LUN ${SYMCLONE_SOURCE_DEVICE} n'existe pas sur la Baie";
DeviceExists "${SYMCLONE_TARGET_DEVICE}" "${SYMCLONE_ARRAY_SID}"    || writeLog "La LUN ${SYMCLONE_TARGET_DEVICE} n'existe pas sur la Baie";
SGExists "${SYMCLONE_TARGET_STORAGEGROUP}" "${SYMCLONE_ARRAY_SID}"  || writeLog "Le Storage Group ${SYMCLONE_TARGET_STORAGEGROUP} n'existe pas sur la Baie";

SYMCLONE_SOURCE_DEVICE_SIZE=$(getDeviceSize "${SYMCLONE_SOURCE_DEVICE}" "${SYMCLONE_ARRAY_SID}")
SYMCLONE_TARGET_DEVICE_SIZE=$(getDeviceSize "${SYMCLONE_TARGET_DEVICE}" "${SYMCLONE_ARRAY_SID}")

numberCompare "${SYMCLONE_TARGET_DEVICE}" "${SYMCLONE_SOURCE_DEVICE}" ">=" ||  writeLog "La taille de la LUN source ne peut etre superieure à celle de destination";
writeLog "INITIALISATION DE LA SESSION DE CLONE" "info";

if dgExists "${SYMCLONE_DEVICEGROUP_NAME}" ; then
  #symclone -g dgtest query
    isDGMember "${SYMCLONE_SOURCE_DEVICE}" "${SYMCLONE_DEVICEGROUP_NAME}" || writeLog "La LUN ${SYMCLONE_SOURCE_DEVICE} n'est pas membre du DG ${SYMCLONE_DEVICEGROUP_NAME}";
    isDGMember "${SYMCLONE_TARGET_DEVICE}" "${SYMCLONE_DEVICEGROUP_NAME}" || writeLog "La LUN ${SYMCLONE_TARGET_DEVICE} n'est pas membre du DG ${SYMCLONE_DEVICEGROUP_NAME}";
    symclone -g "${SYMCLONE_DEVICEGROUP_NAME}" -copy recreate "${SYMCLONE_SOURCE_DEVICE_ALIAS}" SYM LD "${SYMCLONE_TARGET_DEVICE_ALIAS}"  -nop

else
    symdg create "${SYMCLONE_DEVICEGROUP_NAME}" -type regular || writeLog "Unable to create device group. please check logs for more information"; 
    symdg -g "${SYMCLONE_DEVICEGROUP_NAME}" -sid "${SYMCLONE_ARRAY_SID}" add dev "${SYMCLONE_SOURCE_DEVICE}" "${SYMCLONE_SOURCE_DEVICE_ALIAS}"
    symdg -g "${SYMCLONE_DEVICEGROUP_NAME}" -sid "${SYMCLONE_ARRAY_SID}" add dev "${SYMCLONE_TARGET_DEVICE}" "${SYMCLONE_TARGET_DEVICE_ALIAS}" -tgt

    symclone -g "${SYMCLONE_DEVICEGROUP_NAME}" -copy -differential create "${SYMCLONE_SOURCE_DEVICE_ALIAS}" SYM LD "${SYMCLONE_TARGET_DEVICE_ALIAS}"  -nop
fi

writeLog "ACTIVATION DE LA SESSION DE CLONE" "info";
symclone -g "${SYMCLONE_DEVICEGROUP_NAME}" activate "${SYMCLONE_SOURCE_DEVICE_ALIAS}" SYM LD "${SYMCLONE_TARGET_DEVICE_ALIAS}" -consistent  -nop

#  VERIFICATION DE LA PROGRESSION DE LA COPIE
#---------------------------------------------
until $(CloneSessionFinished "${SYMCLONE_DEVICEGROUP_NAME}")
do
    symclone -g "${SYMCLONE_DEVICEGROUP_NAME}" query -gb
    sleep 5
done
wait
writeLog "FINALISATION DE LA COPIE" "info";
symclone -g "${SYMCLONE_DEVICEGROUP_NAME}" terminate "${SYMCLONE_SOURCE_DEVICE_ALIAS}" SYM LD "${SYMCLONE_TARGET_DEVICE_ALIAS}"  -nop
wait

if ! IsStorageGroupMember "${SYMCLONE_TARGET_DEVICE}" "${SYMCLONE_TARGET_STORAGEGROUP}" "${SYMCLONE_ARRAY_SID}"; then
  writeLog "AJOUT DE LA LUN: ${SYMCLONE_TARGET_DEVICE} AU STORAGE GROUP: ${SYMCLONE_TARGET_STORAGEGROUP}" "info";
  symaccess -sid "${SYMCLONE_ARRAY_SID}" -name "${SYMCLONE_TARGET_STORAGEGROUP}" -type storage add devs "${SYMCLONE_TARGET_DEVICE}"
  symsg -sid "${SYMCLONE_ARRAY_SID}" -sg "${SYMCLONE_TARGET_STORAGEGROUP}" set -slo Diamond
fi
