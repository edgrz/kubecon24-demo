terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.54"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.3"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  # add here provider configuration if needed

}
