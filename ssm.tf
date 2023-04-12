variable "source_dir" {
  default = "ansible"
}

variable "playbook-name" {
  default = "init-playbook"

}


data "archive_file" "archive" {
  type        = "zip"
  output_path = "${var.source_dir}_out/${var.playbook-name}.zip"
  source_dir  = "${var.source_dir}_in/"
}

resource "aws_ssm_parameter" "ssd_bind_user" {
  name  = "/LandingZone/Ansible/SSSD_BIND_USER"
  type  = "String"
  value = "CN=DESVC.awsbind,OU=ServiceAccounts,OU=Administration,OU=DE,DC=internal,DC=vodafone,DC=com"
  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "ssd_bind_pw" {
  name  = "/LandingZone/Ansible/SSSD_OBFUSCATED"
  type  = "String"
  value = "AAAQAOMo3wrCRzivkAcfgEIHgUTzMaA5fjluGYWS0YV3DNjT83ZD9HyXqK574f1RWocQnfMz/wggbH74ccSaQVUjOFkAAQID"
  lifecycle {
    ignore_changes = [value]
  }
}


resource "aws_s3_bucket_object" "playbook" {
  bucket = "${data.aws_caller_identity.current.account_id}-ansiblebucket"
  key    = "${var.playbook-name}.zip"
  source = "${var.source_dir}_out/${var.playbook-name}.zip"

  # The filemd5() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the md5() function and the file() function:
  # etag = "${md5(file("path/to/file"))}"
  etag = filemd5("${var.source_dir}_out/${var.playbook-name}.zip")

  depends_on = [
    data.archive_file.archive
  ]
}

resource "aws_ssm_association" "ansible-assoc" {
  association_name = "vfde-ansible-assoc"
  name             = "AWS-ApplyAnsiblePlaybooks"

  #can be used if more than one Instance has to be configured
  # The Instance mus be tagged later with this
  targets {
    key    = "tag:SSM_Ansible"
    values = ["BastionHost"]
  }

  /*
  targets {
    key = "InstanceIds"
    values = [aws_instance.ansible-ec2-instance.id]
  }
*/

  # every day at 6pm run the playbook
  schedule_expression = "cron(0 18 * * ? *)"


  # paramerets for the AWS-ApplyAnsiblePLaybooks document to use
  parameters = {
    "SourceType" : "S3",
    "SourceInfo" : "{\"path\":\"https://s3.amazon.com/${data.aws_caller_identity.current.account_id}-ansiblebucket/${var.playbook-name}.zip\"}",
    "InstallDependencies" : "True"
    "PlaybookFile" : "playbook.yml",
    "ExtraVariables" : "SSM=True extrahostname=${var.bastion_host_name} extraefsid=${data.terraform_remote_state.bastion-core.outputs.efs_homes_bastion_host} proxyPrefix=${var.proxy_prefix}",
    "Check" : "False",
    "Verbose" : "-vvv"
  }

  # wheer to store he output of the assosiation (STDOUT and STDERR)
  output_location {
    s3_key_prefix  = "ansbile-bastion/"
    s3_bucket_name = "${data.aws_caller_identity.current.account_id}-ansiblebucket"
  }
}


resource "aws_ssm_parameter" "cwagent_config" {
  name  = "/LandingZone/Bastion/CW/CONFIG"
  type  = "String"
  value = templatefile("${path.module}/cloudwatch_config.tmpl", { loggroup_name = var.cloudwatch_log_group_name })

  tags = merge(
    var.tags,
    map(
      "Purpose", "Base CW agent config"
    )
  )
}
