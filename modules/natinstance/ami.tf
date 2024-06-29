data "aws_ami" "nat" {
  most_recent = true
  name_regex  = "^amzn-ami-vpc-nat-2018.*"

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "image-type"
    values = ["machine"]
  }


  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}
