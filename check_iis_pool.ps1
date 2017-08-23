#################################################################################
#
# NAME: 	check_iis_pool.ps1
#
# COMMENT:  Script to check for IIS Pool with Nagios/Icinga2 + NRPE/NSClient++
#
#           Checks:
#           - if there is any app which is in stopped state
#
#			Return Values for NRPE:
#			Everything started - OK (0)
#			There is some App with stopped state - CRITICAL (2)
#			Script errors - UNKNOWN (3)
#
#			NRPE Handler to use with NSClient++:
#			[NRPE Handlers]
#			check_updates=cmd /c echo scripts\check_iis_pool.ps1 $ARG1$ $ARG2$; exit $LastExitCode | powershell.exe -command - 
#
#
# CHANGELOG:
# 0.1  2017-08-23 - initial version
#
#################################################################################
# Copyright (C) 2017 Pawel Szafer pszafer@gmail.com
#
# This program is free software; you can redistribute it and/or modify it under 
# the terms of the GNU General Public License as published by the Free Software 
# Foundation; either version 3 of the License, or (at your option) any later 
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT 
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with 
# this program; if not, see <http://www.gnu.org/licenses>.
#################################################################################

Import-Module WebAdministration

$returnStateOK = 0
$returnStateWarning = 1
$returnStateCritical = 2
$returnStateUnknown = 3
$returnStatePendingReboot = $returnStateWarning
$returnStateOptionalUpdates = $returnStateWarning

$statuses = @{
	ok = @()
	critical = @()
}

$criticalTitles = "";
$countCritical = 0;
$countOK = 0;

$ApplicationPoolsState = Get-WebAppPoolState | % {  return  @{($_.itemxpath -split ("'"))[1]="$($_.value)" } } | % getEnumerator | % {
	if ($_.value -ne "Started"){
		$statuses.critical += $_.key
	}
	else {
		$statuses.ok += $_.key
	}
}

$countCritical = $statuses.critical.length
$countOK = $statuses.ok.length

if ($countCritical -gt 0) {
	if ($countOK -gt 0){
		Write-Host "CRITICAL - apps:" + $statuses.critical + " but some Apps are OK:" + $statuses.ok
		exit $returnStateCritical
	}
	else {
		Write-Host "CRITICAL - apps:" + ($statuses.critical | String-Out) + " "
		exit $returnStateCritical
	}
	
	# report critical, report OK
}
elseif ($countOK -gt 0){
	Write-Host "OK - all apps are ok " + ($statuses.ok -join ',')
	exit $returnStateOK
	# report OK
}
else {
	Write-Host "Cannot check AppPool state"
	exit $returnStateUnknown
}

exit 0