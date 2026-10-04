terraform {
  backend "s3" {
    bucket       = "ucla-library-terraform-state"
    key          = "pointcloud-infra/production/terraform.tfstate"
    region       = "us-west-2"
    profile      = "ucla-library-dsc"
    encrypt      = true
    use_lockfile = true
  }
}
