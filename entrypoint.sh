#!/bin/bash

#echo "$DNS" | jq -r ".[\"d4n.eu\"] | .DNS | .[\"*\"] | .IP" > /root/tmp

lf="/etc/bind/named.conf.local"
of="/etc/bind/named.conf.options"

#DNS=$(cat /opt/docker/bind9/dns.json)
#lf="/opt/docker/bind9/xxx"

# create folder for zone files if doesn't exists
[ -d /etc/bind/zones/ ] || mkdir -p /etc/bind/zones/

# allow recursion - command must be before trusted hosts
sed -i 's/^};/\n\tallow-query { any; };\n\tallow-recursion { trusted; };\n\tallow-query-cache { trusted; };\n};/g' $of

# trusted host for recursion
echo -e "\nacl \"trusted\" {" >> $of
echo -e "\t10.0.0.0/24;" >> $of
echo -e "\tlocalhost;" >> $of
echo -e "\tlocalnets;" >> $of
echo -e "};" >> $of

# we don't need IPv6
sed -i 's/listen-on-v6 { any; };/#listen-on-v6 { any; };/g' $of

echo $DNS | jq 'keys[]' -r | while read domain ; do
    zf="/etc/bind/zones/db.$domain"

    echo -e "\nzone \"$domain\" {" >> $lf
    echo "    type master;" >> $lf
    echo "    file \"$zf\";" >> $lf
    echo "};" >> $lf

    ip=$(echo "$DNS" | jq -r ".[\"$domain\"] | .A")
    ns1=$(echo "$DNS" | jq -r ".[\"$domain\"] | .NS1")
    ns2=$(echo "$DNS" | jq -r ".[\"$domain\"] | .NS2")

    echo "; Domain: $domain" >> $zf
    echo "\$TTL    1" >> $zf
    echo "@       IN      SOA     $domain. root.$domain. (" >> $zf
    echo "                        $(date +%s)      ; Serial" >> $zf
    echo "                        3600          ; Refresh" >> $zf
    echo "                        900           ; Retry" >> $zf
    echo "                        604800         ; Expire" >> $zf
    echo "                        86400         ; Negative Cache TTL" >> $zf
    echo ");" >> $zf
    echo "@       IN      NS      ns1.$domain." >> $zf
    echo "@       IN      NS      ns2.$domain." >> $zf
    echo "        IN      A       $ip" >> $zf
    echo "ns1     IN      A       $ns1" >> $zf
    echo "ns2     IN      A       $ns2" >> $zf
    echo "$DNS" | jq -r ".[\"$domain\"] | .DNS" | jq 'keys[]' -r | while read dns ; do
        t=$(echo "$DNS" | jq -r ".[\"$domain\"] | .DNS | .[\"$dns\"] | .TYPE")
        val=$(echo "$DNS" | jq -r ".[\"$domain\"] | .DNS | .[\"$dns\"] | .VALUE")
        if [ $t = "A" ] ; then
            echo -e "$dns\t\tIN\t\t$t\t\t$val" >> $zf
        else
            echo -e "$dns\t\tIN\t\t$t\t\t$val." >> $zf
        fi
    done
done

/usr/sbin/named -g -c /etc/bind/named.conf -u bind
