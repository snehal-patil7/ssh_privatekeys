# EC2 instance Keys
##############################################################
// Default EC2 User Key
resource "aws_key_pair" "bastion_key" {

  key_name   = "bastion_host_ec2_user_key"
  public_key =
}

##############################################################
# Bastion host(s), with users to access the account
##############################################################
variable "instance_num" {
  default = "2"
}

resource "aws_instance" "bastion_hosts" {
  //  use max 3 Bastion Hosts
  count = var.instance_num
  // depends_on                  = ["aws_efs_file_system.efs_homes_bastion_host"]
  instance_type          = var.instance_params["instance_type"]
  ami                    = var.region_ami["eu-central-1"]
  iam_instance_profile   = aws_iam_instance_profile.ec2_bastion_profile.id
  vpc_security_group_ids = [data.terraform_remote_state.bastion-core.outputs.sg_bastion_ssh, data.terraform_remote_state.bastion-core.outputs.sg_efs_bastion_host]
  // Only AZ A, because of problems with the lb failover via private link.
  subnet_id = data.terraform_remote_state.core.outputs.priv_net.0
  // use this to place the hosts in all 3 AZs 
  #subnet_id                   = "${element(data.terraform_remote_state.core.outputs.priv_net, count.index)}"
  key_name                = aws_key_pair.bastion_key.key_name
  user_data               = data.template_file.setup_client_sso-sh.rendered
  disable_api_termination = true

  tags = merge(
    var.tags,
    map(
      "Name", "${var.env_prefix}-Bastion_Host",
      "Role", "Bastion Host",
      "SSM_Ansible", "BastionHost",
      "AutoTurnOFF", "Yes",
      "StartTime", "0600",
      "StopTime", "1800"

    )
  )
  root_block_device {
    encrypted   = true
    volume_size = "10"

  }
  volume_tags = merge(
    var.tags,
    map(
      "Name", "${var.env_prefix}-Bastion_Host",
      "Role", "Bastion Host",
      "SSM_Ansible", "BastionHost"
    )
  )
  lifecycle {
    ignore_changes = [user_data]
  }
}


##############################################################
# DNS Section
##############################################################

resource "aws_route53_record" "bastion_hosts" {

  count   = var.instance_num
  zone_id = data.terraform_remote_state.core.outputs.route53_int_zone
  name    = "jump${count.index}"
  type    = "A"
  ttl     = "300"
  // matches up record N to instance N
  records = [element(aws_instance.bastion_hosts.*.private_ip, count.index)]

}

resource "aws_route53_record" "bastion_hosts_dns_rr" {

  zone_id = data.terraform_remote_state.core.outputs.route53_int_zone
  name    = "jump"
  type    = "A"
  ttl     = "300"
  records = aws_instance.bastion_hosts.*.private_ip

}


resource "aws_lb_target_group_attachment" "lb_target_group_attachment_bastion_hosts" {

  count            = var.instance_num
  target_group_arn = data.terraform_remote_state.bastion-core.outputs.lb_target_group_bastion_arn
  target_id        = element(aws_instance.bastion_hosts.*.id, count.index)
  port             = 22

}



resource "aws_iam_role" "ec2-bastion-host-role" {

  name               = "ec2-bastion-host-role"
  description        = "Bastion Host EC2-Role to access AWS Services"
  assume_role_policy = <<EOF
{
      "Version": "2012-10-17",
      "Statement": [
        {
          "Action": "sts:AssumeRole",
          "Principal": {
            "Service": "ec2.amazonaws.com"
          },
          "Effect": "Allow",
          "Sid": ""
        }
      ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ec2-role-bastion-attach" {
  role       = aws_iam_role.ec2-bastion-host-role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeCommitReadOnly"
}

resource "aws_iam_role_policy_attachment" "ec2-role-bastion-attach2" {
  role       = aws_iam_role.ec2-bastion-host-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}
resource "aws_iam_role_policy_attachment" "ec2-role-bastion-attach3" {
  role       = aws_iam_role.ec2-bastion-host-role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeCommitPowerUser"
}

resource "aws_iam_role_policy_attachment" "ec2-role-bastion-ssm" {
  role       = aws_iam_role.ec2-bastion-host-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}


resource "aws_iam_instance_profile" "ec2_bastion_profile" {
  name = "ec2_bastion_profile"
  role = aws_iam_role.ec2-bastion-host-role.name
}



resource "aws_iam_policy" "iam_basic_host_policy" {
  name        = "IAM_Basic"
  path        = "/"
  description = "IAM Basic Policy for EC2 Hosts"
  policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Action": "iam:ListAccountAliases",
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_cloudwatch_log_group" "BastionHostLogGroup" {
  name              = var.cloudwatch_log_group_name
  retention_in_days = 30
}

resource "aws_iam_role_policy_attachment" "ec2-role-bastion-iam-basic-host-role" {
  role       = aws_iam_role.ec2-bastion-host-role.name
  policy_arn = aws_iam_policy.iam_basic_host_policy.arn
}


resource "aws_iam_policy" "custom-policy-Bastion-LogRolePolicy" {
  name        = "BastionLogRolePolicyLogRolePolicy"
  path        = "/"
  description = "IAM role Policy for Bastion-Policy for LogRolePolicy"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "logs:DescribeLogStreams"
            ],
            "Resource": [
                    "${aws_cloudwatch_log_group.BastionHostLogGroup.arn}"
            ],
            "Effect": "Allow"
        },
        {   
            "Effect": "Allow",
            "Action": [
                "ssm:DescribeParameters"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ssm:GetParameters",
                "ssm:GetParameter"
            ],
            "Resource": "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/LandingZone/Bastion/CW/CONFIG"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ec2-role-bastion-attach-LogRolePolicy" {
  role       = aws_iam_role.ec2-bastion-host-role.name
  policy_arn = aws_iam_policy.custom-policy-Bastion-LogRolePolicy.arn
}
