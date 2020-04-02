module "common_variables" {
  source = "../../modules/common_variables"

  environment = var.environment
}

data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    bucket = lookup(module.common_variables.terraform_state_s3_bucket, var.environment, "")
    key    = module.common_variables.vpc_terraform_state_key
    region = module.common_variables.aws_region
  }
}


data "terraform_remote_state" "route53" {
  backend = "s3"

  config = {
    bucket = lookup(module.common_variables.terraform_state_s3_bucket, var.environment, "")
    key    = module.common_variables.r53_terraform_state_key
    region = module.common_variables.aws_region
  }
}

resource "aws_launch_configuration" "vpn" {
  image_id                = var.vpn-ami
  instance_type           = var.vpn_instance_type
  key_name                = "${module.common_variables.org_name}-${var.environment}-ssh-key"
  security_groups         = [aws_security_group.vpn.id]
  iam_instance_profile    = aws_iam_instance_profile.vpn_profile.name
  enable_monitoring       = false

  lifecycle {
    create_before_destroy = true
  }

  root_block_device {
    delete_on_termination = true
    volume_type           = "gp2"
  }

  user_data_base64 = base64gzip(data.template_file.user_data.rendered)
}

resource "aws_autoscaling_group" "auto_scaling_group" {
  launch_configuration = aws_launch_configuration.vpn.name
  max_size             = 1
  min_size             = 1
  desired_capacity     = 1
  name                 = "${var.environment}-${var.stack_name}-asg"

  vpc_zone_identifier = [
    data.terraform_remote_state.vpc.outputs.vpc_public_subnets[0]
  ]

  default_cooldown          = 180
  health_check_grace_period = 180
  health_check_type         = "EC2"

  tags = [
    {
      key                 = "Name"
      value               = "${var.environment}-${var.stack_name}"
      propagate_at_launch = true
    }
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_eip" "vpn" {
  vpc = true
}

resource "aws_security_group" "vpn" {
  name        = "${var.environment}-${var.stack_name}-sg"
  description = "SG for VPN"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 943
    to_port     = 943
    protocol    = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 1194
    to_port     = 1194
    protocol    = "udp"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "vpn_egress_ssh_to_private_subnets" {
  type              = "egress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.vpn.id
  cidr_blocks       = data.terraform_remote_state.vpc.outputs.private_subnets_cidr_blocks
  description       = "Allow SSH out of VPN to anywhere in a private subnet"
}

resource "aws_security_group_rule" "vpn_egress_https_to_private_subnets" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.vpn.id
  cidr_blocks       = data.terraform_remote_state.vpc.outputs.private_subnets_cidr_blocks
  description       = "Allow HTTPs out of VPN to anywhere in a private subnet"
}

resource "aws_iam_instance_profile" "vpn_profile" {
  name = "${var.environment}-${var.stack_name}-instance-profile"
  role = aws_iam_role.vpn_role.name
}

resource "aws_iam_role" "vpn_role" {
  name = "vpn-role"

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

resource "aws_iam_role_policy_attachment" "vpn_attach_ssm" {
  role       = aws_iam_role.vpn_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

resource "aws_iam_role_policy" "ebs_volume_policy" {
  name = "${var.environment}-${var.stack_name}-ebs-volume-policy"
  role = aws_iam_role.vpn_role.name

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "AllowEBSVolumeAttachment",
        "Action": [
          "ec2:AttachVolume",
          "ec2:DescribeVolumes"
        ],
        "Effect": "Allow",
        "Resource": "*"
      }
    ]
  }
  EOF
}

resource "aws_iam_role_policy" "attach_eip_policy" {
  name = "${var.environment}-${var.stack_name}-attach-eip-policy"
  role = aws_iam_role.vpn_role.name

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "AllowEIPAttachment",
        "Action": [
          "ec2:AssociateAddress"
        ],
        "Effect": "Allow",
        "Resource": "*"
      }
    ]
  }
  EOF
}

resource "aws_iam_role_policy" "modify_instance_policy" {
  name = "${var.environment}-${var.stack_name}-modify-instance-policy"
  role = aws_iam_role.vpn_role.name

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "AllowSourceDestCheckModifications",
        "Action": [
          "ec2:ModifyInstanceAttribute"
        ],
        "Effect": "Allow",
        "Resource": "*"
      }
    ]
  }
  EOF
}

resource "aws_iam_role_policy" "modify_r53_policy" {
  name = "${var.environment}-${var.stack_name}-modify-53-policy"
  role = aws_iam_role.vpn_role.name

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "AllowR53Modifications",
        "Effect": "Allow",
        "Action": [
        "route53:ChangeResourceRecordSets"
        ],
        "Resource":  "arn:aws:route53:::hostedzone/${data.terraform_remote_state.route53.outputs.main_hosted_zone_id}"
      }
    ]
  }
  EOF
}

data "template_file" "user_data" {
  template = file(
    "${path.module}/templates/user_data.sh",
  )

  vars = {
    admin_password                = var.vpnas_admin_password
    mount_volume                  = data.template_file.mount_volume.rendered
    eip_identifier                = aws_eip.vpn.id
    vpnas_path                    = var.vpnas_path
    public_fqdn_name              = "${var.vpnas_client_dns_name}.${module.common_variables.dns_zone_name}"
    create_route53_public_record  = data.template_file.create_route53_public_record.rendered
    create_route53_private_record = data.template_file.create_route53_private_record.rendered
  }
}

data "template_file" "mount_volume" {
  template = file(
    "${path.module}/../../templates/format_and_mount_volume.sh",
  )

  vars = {
    volume_tag  = var.vpn_ebs_tag_name
    device_path = var.device_path
  }
}

data "template_file" "create_route53_public_record" {
  template = file(
    "${path.module}/../../templates/create_r53_record.sh",
  )

  vars = {
    fqdn_name   = "${var.vpnas_client_dns_name}.${module.common_variables.dns_zone_name}"
    r53_zone_id = data.terraform_remote_state.route53.outputs.main_hosted_zone_id
  }
}

data "template_file" "create_route53_private_record" {
  template = file(
    "${path.module}/../../templates/create_r53_record.sh",
  )

  vars = {
    fqdn_name   = "${var.vpnas_admin_dns_name}.${module.common_variables.dns_zone_name}"
    r53_zone_id = data.terraform_remote_state.route53.outputs.main_hosted_zone_id
  }
}

resource "aws_ebs_volume" "vpn_volume" {
  availability_zone = module.common_variables.azs[0]
  size              = 20
  type              = "gp2"

  tags = {
    Name        = var.vpn_ebs_tag_name
    Environment = var.environment
  }
}
