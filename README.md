# feed-my-cat

 State of the art system to feed your cat using various AWS services.

## Installation

1. Configure [AWS Credentials](https://docs.aws.amazon.com/sdk-for-java/v1/developer-guide/).
2. Install [Terraform](https://learn.hashicorp.com/terraform/getting-started/install.html)


## Usage

1. `$ cd infra`
2. `$ terraform init`
3. `$ terraform apply`

You'll be prompted for your email, to which alerts will be sent in case  your cat hasn't been fed.

After installation, make sure to confirm subscription by clicking on the URL you'll get to the email specified in the installation process.

Feeding your cat is simple - Just upload an image with either Fish, Milk or Bread to the S3 bucket specified in the installation process as-well.

## Contributors

- [Pavel Shklovsky](https://github.com/pab1it0) - creator and maintainer
