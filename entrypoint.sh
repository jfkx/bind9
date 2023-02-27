#!/bin/bash

lf="/etc/bind/named.conf.local"
of="/etc/bind/named.conf.options"

#lf="./x"
#of="./y"
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

aq=$(echo "$CFG" | jq -rM ".config | .[\"allow-query\"]")
if [ "$aq" != "null" ] ; then
    cfg="${cfg}\tallow-query { $aq };"
fi

ar=$(echo "$CFG" | jq -rM ".config | .[\"allow-recursion\"]")
if [ "$ar" != "null" ] ; then
    cfg="${cfg}\trecursion yes;\tallow-recursion { $ar };"
fi

aqc=$(echo "$CFG" | jq -rM ".config | .[\"allow-query-cache\"]")
if [ "$aqc" != "null" ] ; then
    cfg="${cfg}\tallow-query-cache { $aqc };"
fi

# echo above config value and close option brackets
echo -e "\n$cfg" >> $of
echo -e "\n};" >> $of

# we don't need IPv6
sed -i 's/listen-on-v6 { any; };/listen-on-v6 { none; };/g' $of

sed -i 's/options {/options {\n\
        allow-new-zones yes;\n\
        querylog yes;/;' $of

# tsig secret key

# key d4n.eu. {
#     algorithm hmac-md5;
#     secret "U9HOes0RAEmM6nTuLOc9AA==";
# };

# controls {
#         inet 127.0.0.1 port 953 allow { 127.0.0.1; };
# };

# zone "d4n.eu" {
#     type master;
#     allow-update { key d4n.eu. ; } ;
#     file "/etc/bind/zones/db.d4n.eu";
# };

ts=$(echo "$CFG" | jq -rM ".config | .[\"tsig-secret\"]")
if [ "$ts" != "null" ] ; then
    echo -e "\nkey tsig-secret {" >> $lf
    echo "     algorithm hmac-md5;" >> $lf
    echo "     secret \"$ts\";" >> $lf
    echo "};" >> $lf

    echo -e "\nkey rndc-key-80.211.194.143 {" >> $lf
    echo "     algorithm hmac-md5;" >> $lf
    echo "     secret \"$ts\";" >> $lf
    echo "};" >> $lf

    cai=$(echo "$CFG" | jq -rM ".config | .[\"control_allow_ips\"]")
    if [ "$cai" == "null" ] ; then
        cai="127.0.0.1;"
    fi

    echo -e "\ncontrols {" >> $lf
    echo "     inet * port 953 allow { $cai } keys { \"rndc-key-80.211.194.143\"; \"tsig-secret\"; };" >> $lf
    echo "};" >> $lf
fi

echo $DNS | jq -r ".domains" | jq 'keys[]' -r | while read domain ; do
    zf="/etc/bind/zones/db.$domain"
    #zf="./zones/db.$domain"

    ip=$(echo "$DNS" | jq -r ".domains | .[\"$domain\"] | .A")
    ns1=$(echo "$DNS" | jq -r ".domains | .[\"$domain\"] | .NS1")
    ns2=$(echo "$DNS" | jq -r ".domains | .[\"$domain\"] | .NS2")

    echo -e "\nzone \"$domain\" {" >> $lf
    echo "    type master;" >> $lf
    echo "    allow-update { key tsig-secret ; } ;" >> $lf
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
        k=$(echo "$DNS" | jq -r ".domains | .[\"$domain\"] | .DNS | .[\"$dns\"] | .key")
        t=$(echo "$DNS" | jq -r ".domains | .[\"$domain\"] | .DNS | .[\"$dns\"] | .type")
        val=$(echo "$DNS" | jq -r ".domains | .[\"$domain\"] | .DNS | .[\"$dns\"] | .value")
        if [ $t = "A" -o $t = "TXT" ] ; then
            echo -e "$k\t\tIN\t\t$t\t\t$val" >> $zf
        #elif [$t = "TXT" ] ; then
        #    echo -e "$k\t\tIN\t\t$t\t\t$val" >> $zf
        else
            echo -e "$k\t\tIN\t\t$t\t\t$val." >> $zf
        fi
    done
done

chmod g+w /etc/bind/zones

/usr/sbin/named -g -c /etc/bind/named.conf -u bind
