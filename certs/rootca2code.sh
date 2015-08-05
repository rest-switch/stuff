#!/bin/sh
#
# Copyright 2015 The REST Switch Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, Licensor provides the Work (and each Contributor provides its
# Contributions) on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied, including,
# without limitation, any warranties or conditions of TITLE, NON-INFRINGEMENT, MERCHANTABILITY, or FITNESS FOR A PARTICULAR
# PURPOSE. You are solely responsible for determining the appropriateness of using or redistributing the Work and assume any
# risks associated with Your exercise of permissions under this License.
#
# Author: John Clark (johnc@restswitch.com)
#


main()
{
    printf "\n\n"
    printf "    // trust our root ca\n"
    printf "    private static final String rootCa =\n"
    flag=0
    while read line; do
        if [ 0 -ne $flag ]; then printf " +\n"; fi
        flag=1
        printf "        \"$line\""
    done < "${infile}"
    printf ";\n"
    printf "\n\n\n"
}


#
# help
#
usage() {
cat << EOF

Usage:
 $(basename "$0") <root_ca.pub>

 Export the public <root_ca.pub> in a form suitable for including in java code

EOF
}

infile=$1
if [ -z ${infile} ]; then
    usage
    exit 0;
fi


main

