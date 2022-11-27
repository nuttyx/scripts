#!/usr/bin/bash

if [[ $# -lt 1 ]]; then
  echo "$0 needs (at least) an argument (domain or domain:port) to work"
  exit 4
fi
echo "$1" | grep -q ":" 2>/dev/null
# Set default port to 443 (HTTPS) if none provided
if [[ $? -ne 0 ]]; then
  a="$1:443"
else
  a="$1"
fi
# Extra parameters as modifiers of openssl (-tls1_2, -servername ***, -starttls protocol, etc)
shift

# openssl connects to remote site, no input provided (to disconnect immediately), 
# parsing result to extract certificate, 
# using openssl to convert to text,
# use awk to extract only the valuable info and print it in a condensed way
# MIGHT need to correct something upon openssl updates.
openssl s_client -connect "$a" "$@" </dev/null 2>&1 \
  | awk '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/ {print}' \
  | openssl x509 -dates -noout -issuer -subject -text \
  | awk '/Not A/ {datea=substr($0,index($0,":")+1)} 
    /Not B/ {dateb=substr($0,index($0,":")+1)} 
    /Subject:/ {subj=substr($0,index($0,":")+1)} 
    /Issuer:/ {issu=substr($0,index($0,":")+1)} 
    /Public-Key:/ {leng=substr($0,index($0,":")+1)} 
    /Public Key Algorithm:/ {pkalg=substr($0,index($0,":")+1)}
    /Signature Algorithm:/ {algo=substr($0,index($0,":")+1)} 
    /(IP|DNS):/ {gsub(/,*[ \t]*(IP|DNS):/," ",$0);san=$0} 
    END {
      print "Subject: " subj;
      print "Issuer:  " issu;
      print "Dates:   " dateb;
      print "         " datea;
      print "Algo.:   " pkalg;
      print "Length:  " leng;
      print "Hash:    " algo;
      print "SAN:     " san;
    }'
