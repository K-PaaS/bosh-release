#!/bin/bash

set -ue

echo \
'/****************************************************************
*	${1} : release-name	                                *
*	${2} : version			                        *
*	${3} : PaaS-TA version			                *	
*       # ./create-relase bosh 271.2.0	2                       *
****************************************************************/
'
if [ "$#" -eq 3 ]; then
	bosh create-release --name ${1} --sha2 --force --tarball ./${1}-${2}-PaaS-TA-v${3}.tgz --version ${2}-PaaS-TA-v${3}
else
	bosh create-release --name ${1} --sha2 --force --tarball ./${1}-${2}-PaaS-TA.tgz --version ${2}-PaaS-TA
fi

