include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../modules/local-cluster"
}

inputs = {
  name = "local"
}
