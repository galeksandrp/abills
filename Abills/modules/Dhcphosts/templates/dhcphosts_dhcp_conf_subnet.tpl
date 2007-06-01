#subnet %BLOCK_NETWORK% netmask %BLOCK_MASK% {
 #  range %block_range%;
 #  authoritative;
 #}

 #Subnets %DESCRIBE%
 subnet %NETWORK% netmask %NETWORK_MASK% {
   #range
   %RANGE%
   deny unknown-clients;
   authoritative;
   %ROUTERS%
   %NET_ROUTES%
  }
