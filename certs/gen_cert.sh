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
#   ./gen_cert.sh -a "rest-switch.com" -d www.restswitch.com -o "REST Switch" -c Durham -s "North Carolina" -u rest-switch_ca_public.cer -v rest-switch_ca_private
#

ext_public=_cert_public.cer
ext_private=_cert_private

gen_cert() {
    # remove spaces & drop to lowercase for output filename
    if [ -z "${outfile}" ]; then
        local target=$(echo "${org}" | sed "s/ /-/g" | tr '[:upper:]' '[:lower:]')
    else
        local target=${outfile}
    fi
    local subject="/C=${country}/ST=${state}/L=${city}/O=${org}/CN=${domain}"

    if [ ! -z "${domain_alias}" ]; then
        local san=$(echo "${domain_alias}" | sed "s/^/DNS:/; s/ /,DNS:/g")
    fi

    # generate cert private key
    local cert_private_key_filename="${target}${ext_private}"
    echo
    echo "generating ${bits} bit private key: \"${cert_private_key_filename}\"..."
    rm -f "${cert_private_key_filename}"
    touch "${cert_private_key_filename}"
    chmod 600 "${cert_private_key_filename}"
    openssl genrsa -out "${cert_private_key_filename}" ${bits}

    local cert_csr_filename="${target}${ext_private}-csr"
    echo
    echo "generating certificate signing request: \"${cert_csr_filename}\"..."
    rm -f "${cert_csr_filename}"
    touch "${cert_csr_filename}"
    chmod 600 "${cert_csr_filename}"

    # generate the csr
    openssl req -sha256 -new -nodes -key "${cert_private_key_filename}" -out "${cert_csr_filename}" -subj "${subject}"

    local cert_public_key_filename="${target}${ext_public}"
    local temp_public_key_filename="${target}.tmp"

    rm -f "${temp_public_key_filename}"
    touch "${temp_public_key_filename}"
    if [ ! -z "${san}" ]; then
        echo "subjectAltName=${san}" > "${temp_public_key_filename}"
    fi
    echo 'basicConstraints=CA:FALSE' >> "${temp_public_key_filename}"
    echo 'keyUsage=critical,digitalSignature,keyEncipherment' >> "${temp_public_key_filename}"
    echo 'extendedKeyUsage=serverAuth,clientAuth' >> "${temp_public_key_filename}"

    openssl x509 -req -days ${days} -in "${cert_csr_filename}" -extfile "${temp_public_key_filename}" -CA "${ca_public_key_filename}" -CAkey "${ca_private_key_filename}" -CAcreateserial -out "${cert_public_key_filename}"
    rm -f "${temp_public_key_filename}"
    rm -f "${cert_csr_filename}"

    # check the certificate
    echo
    openssl x509 -text -noout -in "${cert_public_key_filename}"
    echo

    echo
    echo
    echo "  --> generated cert public cert:  ${cert_public_key_filename}"
    echo "  --> generated cert private key:  ${cert_private_key_filename}"
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
 $(basename "$0") <options> [output_file]

Options:                       * = required option
 -a, --alias <domain1 domain2>   space delimited list of domain aliases
 -b, --bits <number>             number of bits for the certificate (default: 4096 bits)
 -c, --city <name>             * certificate subject city (L)
 -d, --domain <name>           * certificate subject domain (CN)
 -o, --org <name>              * certificate subject organization (O)
 -s, --state <name>            * certificate subject state (ST)
 -t, --country <name>            certificate subject country (C) (default: US)
 -u, --ca-pub <ca_public>      * certificate authority public key filename
 -v, --ca-priv <ca_private>    * certificate authority private key filename
 -y, --years <number>            number of years until expiriation (default: 2 years)
 -h, --help                      display this help text and exit

EOF
}


#
# parse command line
#
if [ $# -eq 0 ]; then
    usage
    exit 0
fi

domain=
domain_alias=
org=
city=
state=
country=
domain=
ca_public_key_filename=
ca_private_key_filename=
bits=4096
days=731
outfile=
while [ $# -gt 0 ]; do
    case "$1" in
    -a|--alias)
        shift
        domain_alias=$1
        ;;
    -b|--bits)
        shift
        bits=$1
        ;;
    -c|--city)
        shift
        city=$1
        ;;
    -d|--domain)
        shift
        domain=$1
        ;;
    -o|--org)
        shift
        org=$1
        ;;
    -s|--state)
        shift
        state=$1
        ;;
    -t|--country)
        shift
        country=$1
        ;;
    -u|--ca-pub)
        shift
    ca_public_key_filename=$1
        ;;
    -v|--ca-priv)
        shift
    ca_private_key_filename=$1
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
        outfile=$1
        ;;
    esac
    shift
done

if [ -z "${domain}" ]; then
    echo
    echo "***"
    echo "***  ERROR: \"domain\" (-d or --domain) must be specified"
    echo "***"
    usage
    exit 1
fi
if [ -z "${org}" ]; then
    echo
    echo "***"
    echo "***  ERROR: \"organization name\" (-o or --org) must be specified"
    echo "***"
    usage
    exit 1
fi
if [ -z "${city}" ]; then
    echo
    echo "***"
    echo "***  ERROR: \"city\" (-c or --city) must be specified"
    echo "***"
    usage
    exit 1
fi
if [ -z "${state}" ]; then
    echo
    echo "***"
    echo "***  ERROR: \"state\" (-s or --state) must be specified"
    echo "***"
    usage
    exit 1
fi
if [ -z "${ca_public_key_filename}" ]; then
    echo
    echo "***"
    echo "***  ERROR: \"ca public cert filename\" (-u or --ca-pub) must be specified"
    echo "***"
    usage
    exit 1
fi
if [ -z "${ca_private_key_filename}" ]; then
    echo
    echo "***"
    echo "***  ERROR: \"ca private cert filename\" (-v or --ca-priv) must be specified"
    echo "***"
    usage
    exit 1
fi

if [ -z "${country}" ]; then country=US; fi


gen_cert

