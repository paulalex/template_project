module "common_variables" {
  source = "../../../modules/common_variables"

  environment = var.environment
}

module "vpc_variables" {
  source = "../../../modules/vpc_variables"

  environment = var.environment
}

data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    bucket = lookup(module.common_variables.terraform_state_s3_bucket, var.environment, "")
    key    = module.vpc_variables.vpc_terraform_state_key
    region = module.common_variables.aws_region
  }
}

resource "aws_launch_configuration" "jenkins" {
  name =                  "${var.environment}-${var.stack_name}-launch-config"
  image_id                = var.jenkins_ami
  instance_type           = var.jenkins_instance_type
  key_name                = "${module.common_variables.org_name}-${var.environment}-ssh-key"
  security_groups         = [aws_security_group.jenkins.id]
  iam_instance_profile    = aws_iam_instance_profile.jenkins_profile.name
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
  launch_configuration = aws_launch_configuration.jenkins.name
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

resource "aws_eip" "jenkins" {
  vpc = true
}

resource "aws_security_group" "jenkins" {
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
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_iam_instance_profile" "jenkins_profile" {
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
        "Sid": "Stmt1581082925365",
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

data "template_file" "user_data" {
  template = file(
    "${path.module}/templates/user_data.sh",
  )

  vars = {
    mount_volume      = data.template_file.mount_volume.rendered
    eip_identifier    = aws_eip.jenkins.public_ip
  }
}

data "template_file" "mount_volume" {
  template = file(
    "${path.module}/templates/format_and_mount_volume.sh",
  )

  vars = {
    volume_tag  = var.jenkins_ebs_tag_name
    device_path = var.device_path
  }
}

resource "aws_ebs_volume" "vpn_volume" {
  availability_zone = module.common_variables.azs[0]
  size              = 100
  type              = "gp2"

  tags = {
    Name        = var.jenkins_ebs_tag_name
    Environment = var.environment
  }
}
