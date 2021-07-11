#!/bin/bash

lf="/etc/bind/named.conf.local"
of="/etc/bind/named.conf.options"

#lf="./x"
#DNS=$(cat /opt/docker/bind9/dns.json)

# create folder for zone files if doesn't exists
[ -d /etc/bind/zones/ ] || mkdir -p /etc/bind/zones/

# remove options brackets at the end of file
sed -i "s/^};/\n# K8s config\n/g" $of

# trusted host for recursion
# echo -e "\nacl \"trusted\" {" >> $of
# echo -e "\t10.0.0.0/24;" >> $of
# echo -e "\tlocalhost;" >> $of
# echo -e "\tlocalnets;" >> $of
# echo -e "};" >> $of

cfg=""

aq=$(echo "$DNS" | jq -rM ".config | .[\"allow-query\"]")
if [ "$aq" != "null" ] ; then
    cfg="${cfg}\tallow-query { $aq };"
fi

ar=$(echo "$DNS" | jq -rM ".config | .[\"allow-recursion\"]")
if [ "$ar" != "null" ] ; then
    cfg="${cfg}\tallow-recursion { $ar };"
fi

aqc=$(echo "$DNS" | jq -rM ".config | .[\"allow-query-cache\"]")
if [ "$aqc" != "null" ] ; then
    cfg="${cfg}\tallow-query-cache { $aqc };"
fi

# echo above config value and close option brackets
echo -e "\n$cfg" >> $of
echo -e "\n};" >> $of

# we don't need IPv6
sed -i 's/listen-on-v6 { any; };/listen-on-v6 { none; };/g' $of

echo $DNS | jq -r ".domains" | jq 'keys[]' -r | while read domain ; do
    zf="/etc/bind/zones/db.$domain"

    ip=$(echo "$DNS" | jq -r ".domains | .[\"$domain\"] | .A")
    ns1=$(echo "$DNS" | jq -r ".domains | .[\"$domain\"] | .NS1")
    ns2=$(echo "$DNS" | jq -r ".domains | .[\"$domain\"] | .NS2")

    echo -e "\nzone \"$domain\" {" >> $lf
    echo "    type master;" >> $lf
    echo "    file \"$zf\";" >> $lf
    echo "};" >> $lf

    echo "; Domain: $domain" > $zf
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
    echo "$DNS" | jq -r ".domains | .[\"$domain\"] | .DNS" | jq 'keys[]' -r | while read dns ; do
        t=$(echo "$DNS" | jq -r ".domains | .[\"$domain\"] | .DNS | .[\"$dns\"] | .type")
        val=$(echo "$DNS" | jq -r ".domains | .[\"$domain\"] | .DNS | .[\"$dns\"] | .value")
        if [ $t = "A" ] ; then
            echo -e "$dns\t\tIN\t\t$t\t\t$val" >> $zf
        else
            echo -e "$dns\t\tIN\t\t$t\t\t$val." >> $zf
        fi
    done
done

/usr/sbin/named -g -c /etc/bind/named.conf -u bind
