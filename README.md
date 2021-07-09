# bind9

zone "d4n.eu" IN {
    type master;
    allow-transfer { any; };
    allow-update { any; };
    file "/etc/bind/devilbox-wildcard_dns.d4n.eu.conf.zone";
};

$TTL  1
@      IN SOA  d4n.eu. root.d4n.eu. (
                 1624995557           ; Serial number of zone file
                 1200     ; Refresh time
                 180       ; Retry time in case of problem
                 1209600      ; Expiry time
                 10800 ) ; Maximum caching time in case of failed lookups
;
       IN NS     ns1.d4n.eu.
       IN NS     ns2.d4n.eu.
       IN A      90.178.21.146
;
ns1    IN A      90.178.21.146
ns2    IN A      90.178.21.146
*      IN A      90.178.21.146
