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

#
# example usage:
#   ./gen_ca.sh "REST Switch"
#

ext_public=_ca_public.cer
ext_private=_ca_private

gen_ca() {
    # remove spaces & drop to lowercase for output filename
    local target=$(echo ${org// /-} | tr '[:upper:]' '[:lower:]')
    local subject="/C=${country}/O=${org}/OU=${org} Trust Network/CN=${org} Class 3 Public Certification Authority"

    # generate ca private key
    local ca_private_key_filename="${target}${ext_private}"
    echo
    echo "generating ${bits} bit ca private key: \"${ca_private_key_filename}\"..."
    rm -f "${ca_private_key_filename}"
    touch "${ca_private_key_filename}"
    chmod 600 "${ca_private_key_filename}"
    openssl genrsa -out "${ca_private_key_filename}" ${bits}

    # gen ca public certificate
    local ca_public_key_filename="${target}${ext_public}"
    echo
    echo "generating ca public certificate: \"${ca_public_key_filename}\"..."
    rm -f "${ca_public_key_filename}"
    openssl req -x509 -sha256 -new -nodes -extensions v3_ca -key "${ca_private_key_filename}" -days ${days} -out "${ca_public_key_filename}" -subj "${subject}"

    # check the certificate
    echo
    openssl x509 -text -noout -in "${ca_public_key_filename}"
    echo

    echo
    echo
    echo "  --> generated ca public cert:  ${ca_public_key_filename}"
    echo "  --> generated ca private key:  ${ca_private_key_filename}"
    echo
    echo
}


#
# errormsg <msg>
#
errormsg() {
    printf '\n***\n***  error: %s\n***\n' "$1"
}


#
# help
#
usage() {
cat << EOF

Usage:
 $(basename "$0") [options] <org name> [country=US]

Options:
 -b, --bits  <number>    number of bits for the certificate (default: 4096 bits)
 -y, --years <number>    number of years until expiriation (default: 10 years)
 -h, --help              display this help text and exit

EOF
}


#
# parse command line
#
if [ $# -eq 0 ]; then
    usage
    exit 0
fi

org=
bits=4096
days=3653
while [ $# -gt 0 ]; do
    case "$1" in
    -b|--bits)
        shift
        bits=$1
        ;;
    -y|--years)
        shift
        days=$((($1 * 365) + ($1 / 4 + 1)))
        ;;
    -h|--help)
        usage
        exit 0
        ;;
    -*)
        errormsg "unknown option: $1"
        usage
        exit 1
        ;;
    *)
        org=$1
        ;;
    esac
    shift
done

if [ -z "${org}" ]; then
    echo
    echo "***"
    echo "***  ERROR: Certificare Authority \"<org name>\" must be specified"
    echo "***"
    usage
    exit 1
fi

if [ -z "${country}" ]; then country=US; fi

gen_ca

