terraform {
  required_providers {
    azuread = {
      source = "hashicorp/azuread"
    }
    fabric = {
      source = "microsoft/fabric"
    }
    github = {
      source = "integrations/github"
    }
    random = {
      source = "hashicorp/random"
    }
  }
}
