{
  # Enable a TPM.
  security.tpm2.enable = true;

  # Use `tpm2-abrmd` (the user-space resource manager) to run as a systemd service.
  security.tpm2.abrmd.enable = true;

  # Makes the PKCS11 tool and libraries available in the system path.
  security.tpm2.pkcs11.enable = true;

  # These settings cause the `TPM2TOOLS_TCTI` and `TPM2_PKCS11_TCTI` environment variables to be
  # set properly to use the user-space resource manager.
  security.tpm2.tctiEnvironment.enable = true;
  security.tpm2.tctiEnvironment.interface = "tabrmd";
}
