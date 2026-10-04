provider "aws" {
  region  = var.region
  profile = "ucla-library-dsc"

  default_tags {
    tags = {
      Project     = "pointcloud"
      Environment = "production"
      ManagedBy   = "terraform"
      Repository  = "ucla-data-science-center/pointcloud-infra"
      Owner       = "UCLA Library Data Science Center"
    }
  }
}
