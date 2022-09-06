# Create Test VMs

Terraform files used to deploy N number of image specific VMs to Microsoft Azure. The deployment assumes you're leveraging an existing virtual network as well as a local VM credentials file saved to a `secrets.json` file.

Example `secrets.json` and `variable.auto.tfvars` files are included in the repository.

All values enclosed in `<>` are to be replaced prior to deployment.

## Test VM Replacement

VMs are deployed by Terraform with the `replace_triggered_by` argument referencing a `random_uuid` which has the `keepers` argument set to the current timestamp of the Terraform apply, this means that every time you run Terraform apply the previously deployed VMs will be destroyed and redeployed.

[Terraform documentation](https://registry.terraform.io/providers/hashicorp/random/latest/docs#resource-keepers) for `Random` provider `Keepers` argument.
