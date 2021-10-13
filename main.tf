# variable "vault_addr" { default = "http://127.0.0.1:8200" }
# variable "vault_token" {}
variable "access_key" {}
variable "secret_key" {}


provider "vault" {
 # address = from env variable VAULT_ADDR
 # token = from env variable VAULT_TOKEN
}

resource "vault_github_auth_backend" "github-org" {
  organization = "zeebote-org"
  tune {
    default_lease_ttl = "86400s"
    # max_lease_ttl      = "90000s"
    # listing_visibility = "unauth"
  }
}

resource "vault_github_team" "tf_devs" {
  backend  = vault_github_auth_backend.github-org.id
  team     = "vault"
  policies = ["ec2-policy", "default"]
}

resource "vault_aws_secret_backend" "aws" {
  access_key = var.access_key
  secret_key = var.secret_key
  region = "us-west-1"
  default_lease_ttl_seconds = "240"
  max_lease_ttl_seconds     = "240"
}
resource "vault_aws_secret_backend_role" "ec2-admin" {
  backend = vault_aws_secret_backend.aws.path
  credential_type = "iam_user"
  name    = "ec2-admin-role"
  policy_document = <<EOT
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "FullAccessEC2Resources",
      "Effect": "Allow",
      "Action": [
        "ec2:*"
      ],
      "Resource": [
        "*"
      ]
    },
     {
      "Sid": "FullAccessELB",
      "Effect": "Allow",
      "Action": [
        "elasticloadbalancing:*"
      ],
      "Resource": [
        "*"
      ]
    },
    {
      "Sid": "GetUsersForConsole",
      "Effect": "Allow",
      "Action": [
        "iam:GetUser",
        "iam:PassRole"
      ],
      "Resource": "*"
    }
  ]
}
EOT
}

resource "vault_policy" "github-policy" {
  name = "ec2-policy"
  policy = <<EOT
path "aws/creds/ec2-admin-role" {
  capabilities = ["read"]
}
path "auth/token/create" {
capabilities = ["update"]
}
EOT
}
