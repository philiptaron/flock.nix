# PKI configuration for custom CA certificates.
#
# This module adds Qumulo's internal AD CA certificate to the system trust store,
# enabling TLS validation for internal services signed by that CA.
{ ... }:

{
  security.pki.certificateFiles = [ ./ad-SEA01-CA-2028.crt ];
}
