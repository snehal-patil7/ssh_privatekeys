##################################
# AWS Settings
##################################
variable "region" {
  default = "eu-central-1"
}


##################################
# Environment
##################################
variable env_prefix {
  default = "vfde-art-dev02-vfde_bss_solstice-eucentral1"
}


##################################
# PORTS 
##################################
variable port {
  default = {
    lb_bastion   = "22"
    lbl_bastion  = "22"
    lbtg_bastion = "22"
  }
}

##################################
# PROTOCOLS 
##################################
variable protocol {
  default = {
    lbl_bastion  = "TCP"
    lbtg_bastion = "TCP"
  }
}

##################################
# EC2 instance
##################################
variable instance_params {
  description = "default instance parameters"

  default = {
    ## CPU:
    ## t2.micro: 1vCPU, 1GiB
    ## t2.small: 1vCPU, 2GiB
    instance_type = "t2.micro"

    ## Filesystem
    root_vol_size = "8"
    root_vol_type = "gp3"
  }
}

variable "bastion_host_motd" {
  default = "Bastion Host ART-DEV02.VFDE_BSS_SOLSTICE"
}

variable "bastion_host_name" {
  default = "Jump-ART-DEV02.VFDE_BSS_SOLSTICE"
}

variable "cloudwatch_log_group_name" {
  default = "Bastion-Host-Logs"
  type    = string
}

variable "proxy_prefix" {
  default = "art-dev02-vfde-solstice"
}

// use this here, it is more accurate
variable "region_ami" {

  default = {
    eu-central-1 = "ami-01031a432d4fbbfff"
  }

  ## hardened AMI:
  ## For security reasons: Please use only a Vodafone hardened AMI!
  ## Please restrict to following OS types only (unix):
  ## amazon linux2, redhat, centos
  ## Where future standard will be amazon linux2 "amzn2" (as no license issues will come up)!
  ##
  ## You can identify the avalable AMI from within
  ## AWS web console - "EC2" service - "AMI" left menu - choose "Private images" - AMI names starting with vf-gdc-...
  ## e.g. choose one out of:
  ## AMI Name / AMI ID
  ## vf-gdc-amzn2-hvm-2019-08-15T09-21-46Z-x86_64-gp2    / ami-042b18153e9e9e29e
  ## vf-gdc-rhel-7.6-hvm-2019-07-17T10-56-57Z-x86_64-gp2 / ami-0b7fff92782ccfc7c
  ## vf-gdc-centos-7-hvm-2019-06-27T09-20-54Z-x86_64-gp2 / ami-0a78ad7d7bb3d9a5f

}
