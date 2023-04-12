data "template_file" "setup_client_sso-sh" {
  template = file("bootstrap/setup_client_sso.sh")

  vars = {
    bhost_name = var.bastion_host_name
    bhost_motd = var.bastion_host_motd
    //  efs_name   = aws_efs_file_system.efs_homes_bastion_host.id
    efs_name          = data.terraform_remote_state.bastion-core.outputs.efs_homes_bastion_host
    dns_int_zone_name = data.terraform_remote_state.core.outputs.route53_int_zone_name
  }

}

// Reference to Core Module State
data "terraform_remote_state" "core" {
  backend = "s3"
  config = {
    bucket  = "147101433358-terraformstates"
    profile = "art-dev02"
    key     = "core-init/state"
    region  = "eu-central-1"
  }

}

// Reference to Bastion Host Module State
data "terraform_remote_state" "bastion-core" {
  backend = "s3"
  config = {
    bucket  = "147101433358-terraformstates"
    profile = "art-dev02"
    key     = "bastion-core/state"
    region  = "eu-central-1"
  }

}
 
