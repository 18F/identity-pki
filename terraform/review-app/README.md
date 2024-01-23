# EKS Cluster Management Scripts

This README provides instructions on how to use the `deploy.sh` and `destroy.sh` scripts for managing an AWS EKS cluster.

## Prerequisites

Before running these scripts, ensure you have the following tools installed. If you are using a Mac, you can install them using Homebrew:

<details>
<summary><b>AWS CLI</b></summary>

```bash
brew install awscli
```
</details>

<details>
<summary><b>Terraform</b></summary>

```bash
bin/terraform-switch <version_number>
```
</details>

<details>
<summary><b>Git</b></summary>

```bash
brew install git
```
</details>

<details>
<summary><b>jq</b></summary>

```bash
brew install jq
```
</details>

<details>
<summary><b>kubectl</b></summary>

```bash
brew install kubectl
```
</details>

<details>
<summary><b>aws-vault</b></summary>

```bash
brew install aws-vault
```
</details>

## deploy.sh

The `deploy.sh` script is used to set up an AWS EKS cluster for a given environment.

### Usage

```bash
aws-vault exec sandbox-terraform -- ./deploy.sh <env_name>
```

- `<env_name>`: The name of the environment you want to deploy.

### Features

- Initializes and configures Terraform state.
- Applies Terraform configurations based on the provided environment.
- Configures `kubectl` to interact with the created Kubernetes cluster.

## destroy.sh

The `destroy.sh` script is used to tear down an AWS EKS cluster for a given environment.

### Usage

```bash
aws-vault exec sandbox-terraform -- ./destroy.sh <env_name>
```

- `<env_name>`: The name of the environment you want to destroy.

### Features

- Tears down Terraform-managed infrastructure.
- Removes Terraform state files associated with the environment.

## Additional Information

- Both scripts include a help function that can be accessed by passing `help` as the argument.
- [Ensure AWS credentials are configured properly before running the scripts.](https://github.com/18F/identity-devops/wiki/Setting-Up-your-Login.gov-Infrastructure-Configuration)
- The scripts assume that the AWS region (`us-west-2`) and other configurations are predefined.
