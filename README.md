# Ansible Certificate Manager Role

An [Ansible][1] role that manages TLS certificates.

## Table of Contents

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
    - [Variables](#variables)
    - [Example](#example)
    - [Notes](#notes)

## Features

- Uses [Let's Encrypt][2] to issue free TLS certificates.
- Supports wildcard certificates.
- Renews certificates automatically.
- Automates the distribution of certificates.

## Requirements

- Debian GNU/Linux 10 (Buster) on managed host
- [DNS provider with API][3]

## Installation

Use [Ansible Galaxy][4] to install `tobygiacometti.cert_manager`. Check out the Ansible Galaxy [content installation instructions][5] if you need help.

## Usage

To get general guidance on how to use Ansible roles, visit the [official documentation][6].

### Variables

- `cert_manager_primary_host`: Name of the host that is responsible for managing certificates. If specified, certificates are requested/renewed by the specified host and securely distributed (SSH) to all other hosts in the play. If not specified, certificates are requested/renewed separately by each host in the play. This variable should be used to prevent rate limit errors when multiple hosts need the same certificate. Please note that the Ansible inventory name of a host in the play must be used. In addition, following requirements must be met:
    - All hosts in the play must use the same SSH port.
    - All hosts in the play must have a hostname that the primary host can resolve to an accessible IP address.
- `cert_manager_account`: Encoded credentials for the Let's Encrypt account that should be used. To create an account and get the encoded credentials, execute `ansible <host> -m include_role -a name=<cert-manager-role-path> -e cert_manager_account=create`. Please note that the encoded credentials should not be stored as plain text.
- `cert_manager_email`: Address to which notification emails for certificates should be sent.
- `cert_manager_certs`: TLS certificates that should be managed. All certificate files are stored in the directory `/etc/certs/<main-domain>`. Please note that certificates are automatically removed from the certificate directory when removed from this variable. This variable takes a list of dictionaries with following key-value pairs:
    - `main_domain`: Domain that should be covered by the certificate. The provided domain is also used as an internal certificate ID. As a result, a unique main domain must be provided for each certificate. The domain can start with `*.` to cover multiple subdomains.
    - `alt_domains`: List of additional domains that should be covered by the certificate. Any domain can start with `*.` to cover multiple subdomains. Please note that a new certificate is issued if this list is adjusted for an existing certificate.
    - `state`: State of the certificate, either `issued` (default) or `revoked`.
    - `dns_provider`: Identifier for the DNS provider that is used. Visit the [acme.sh DNS API documentation][3] to retrieve the identifier (value provided to the acme.sh `--dns` option minus the prefix `dns_`).
    - `dns_credentials`: Credentials for the DNS provider's API. Visit the [acme.sh DNS API documentation][3] to retrieve the credential identifiers (names of the exported variables). Each credential identifier must be used as a key in this dictionary.
    - `verification_domain`: Domain that should be used for ownership verification. This feature is mainly used in two scenarios: When the DNS provider for a domain does not have an API or when increased security is desired. By using a separate domain for verification, the provided DNS API credentials can be scoped to the verification domain. As a result, if they were to fall into the wrong hands, they would only grant access to the verification domain and not the certificate domain itself. To make use of this feature, create the DNS record `_acme-challenge.<certificate-domain>. IN CNAME _acme-challenge.<certificate-domain>.<verification-domain>.` for each certificate domain. `*.` should be stripped from wildcard domains when creating the DNS record.

### Example

```yaml
- hosts: certs.domain.example, web_servers
  vars_prompt:
    - name: cert_manager_account
      prompt: Encoded credentials for the Let's Encrypt account
      unsafe: true
    - name: exoscale_secret_key
      prompt: Exoscale DNS API secret key
      unsafe: true
  roles:
    - role: tobygiacometti.cert_manager
      vars:
        cert_manager_primary_host: certs.domain.example
        cert_manager_email: user@domain.example
        cert_manager_certs:
          - main_domain: www.domain.example
            alt_domains:
              - domain.example
            dns_provider: exoscale
            dns_credentials:
              EXOSCALE_API_KEY: EXO344hg8245wfhuu250wefh2z4
              EXOSCALE_SECRET_KEY: "{{ exoscale_secret_key }}"
            verification_domain: acme.domain.example
```

Relevant records in the `domain.example` zone:

```
acme.domain.example. IN NS ns1.exoscale.com.
acme.domain.example. IN NS ns1.exoscale.net.
acme.domain.example. IN NS ns1.exoscale.ch.

_acme-challenge.www.domain.example. IN CNAME _acme-challenge.www.domain.example.acme.domain.example.
_acme-challenge.domain.example. IN CNAME _acme-challenge.domain.example.acme.domain.example.
```

### Notes

- This role is not responsible for managing services that use the certificates. To reload renewed certificates, either monitor the certificates using inotify or periodically restart/reload the services in question.
- Some services do not read a certificate private key using root privileges. Since the private key can only be read by the `root` and `cert-manager` users by default, the user running the service will need to be granted access. To maintain fine-grained control, this is best done using ACLs.
- Certificates are valid for 90 days and are automatically renewed every 60 days.
- Let's Encrypt has [rate limits][7] for certain operations. To prevent hitting the limits, avoid unnecessary certificate issuance.
- Certificates are never revoked automatically, even when removed. To revoke a certificate, explicitly use the `state` parameter of a `cert_manager_certs` dictionary.

[1]: https://www.ansible.com
[2]: https://letsencrypt.org
[3]: https://github.com/acmesh-official/acme.sh/wiki/dnsapi
[4]: https://galaxy.ansible.com
[5]: https://galaxy.ansible.com/docs/using/installing.html
[6]: https://docs.ansible.com/ansible/latest/user_guide/playbooks_reuse_roles.html
[7]: https://letsencrypt.org/docs/rate-limits/
