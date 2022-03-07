#!/bin/bash
# this script find domain or subdomain list to ip
# and also find ip list to open ports

usage() {
    echo "Usage: $0 -d domainlist.txt -p portlist.txt" 1>&2
    exit 1
}

domain_ip() {
    cat $domainlist | while read d || [[ -n $d ]]; do
        ip=$(dig +short $d | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b")
        if [ -n "$ip" ]; then
            list=$(echo "$ip" | while read x; do echo -e "$d [$x]"; done)
            echo -e "$list" | tee -a /tmp/domains_tmp.txt
        else
            echo "$d [RESOLVE ERROR]"
        fi
    done
    sort /tmp/domains_tmp.txt | uniq >>/tmp/domains_tmp.txt.new
    mv /tmp/domains_tmp.txt.new $(pwd)/domains_ip.txt
    cat $(pwd)/domains_ip.txt | awk '{print $2}' | tr -d "[]" | sort -u >>$(pwd)/only_domains_ip.txt
    rm -fr /tmp/domains_tmp.txt
}

port_scan() {
    for line in $(cat $list_wordlist); do
        ips=$(nmap -T1 -sV -p- $line | sed '/Nmap done/d' | sed '/Starting Nmap/d' | sed '/despite returning/d' | awk 'NR>1{print l}{l=$0}' | perl -ne 'if(/NEXT SERVICE FINGERPRINT/){$f=1}else{$f=0 if $f and not /^SF/}print unless $f')
        echo -e "scan => $line\n$ips\n\n" | tee -a $(pwd)/open_ports.txt
    done
}


while getopts ":d:p:-:" optchar; do
    case "${optchar}" in
    d)
        domainlist=$OPTARG
        domain_ip
        ;;

    p)
        list_wordlist=$OPTARG
        port_scan
        ;;

    *)
        echo -e "[-] Unknown Option: ${optchar}"
        usage
        ;;
    esac
done
shift $((OPTIND - 1))

if [ -z "${domainlist}" ] && [[ -z "${list_wordlist}" ]]; then
    usage
    exit 1
fi
