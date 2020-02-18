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
#-------------------------------------------------------------------
#               DECLARATION DES VARIABLES
#-------------------------------------------------------------------
SYMCLONE_BASE_DIRECTORY=$(dirname "$(readlink -f "$0")")
SYMCLONE_CORE_DIRECTORY="${SYMCLONE_BASE_DIRECTORY}/Core"
SYMCLONE_CORE_FILE="${SYMCLONE_CORE_DIRECTORY}/SYMCloneBundle.sh"

#-------------------------------------------------------------------
#               DEBUT DU TRAITEMENT
#-------------------------------------------------------------------
if [ ! -f "${SYMCLONE_CORE_FILE}" ]; then
   printf " \e[31m %s \n\e[0m" "Des fichiers indispensables sont introuvables !"  
   exit 1 
fi

case "${0}" in
    ${BASH_SOURCE[0]}) 
		. ${SYMCLONE_CORE_FILE}
		exit 0
	;;
    * ) 
		printf " \e[31m %s \n\e[0m" "This is NOT a bash library. Execute it directly !"  
		exit 1
	;;
esac
