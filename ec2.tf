

# need to run terraform import as written in readme.md to get EIP
resource "aws_eip" "my_eip" {
  
}

#crete key pair
resource "aws_key_pair" "my_keypair" {
  key_name   = "my-keypair"  
  public_key = file("C/Users/Lenovo/Desktop/TF_Space/keys/nvig_aksh.pub") 
}

#create sg for ssh and efs
resource "aws_security_group" "ssh_sg" {
  name        = "ssh-security-group"
  description = "Allow SSH traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }
  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#efs creation
resource "aws_efs_file_system" "my_efs" {
  creation_token = "as-znc_sju-naj"
  performance_mode = "generalPurpose"
  throughput_mode = "bursting"

  tags = {
    Name = "MyEFS"
  }
}

#efs mount target
resource "aws_efs_mount_target" "efs_mount_target_a" {
  file_system_id = aws_efs_file_system.my_efs.id
  subnet_id      = "subnet-fbf32e34"  
  security_groups = [aws_security_group.ssh_sg.name]
}

resource "aws_efs_mount_target" "efs_mount_target_b" {
  file_system_id = aws_efs_file_system.my_efs.id
  subnet_id      = "subnet-rcg90e3q" 
  security_groups = [aws_security_group.ssh_sg.name]
}

#create IAM role for efs
resource "aws_iam_role" "efs_write_role" {
  name = "efs-write-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com" 
        },
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "efs_write_policy" {
  name = "efs-write-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Action    = [
          "elasticfilesystem:ClientWrite",  
          "elasticfilesystem:ClientRootAccess"
        ],
        Resource  =aws_efs_file_system.my_efs.arn + "/"
      }
    ]
  })
}

#ec2 provisioning
resource "aws_instance" "my_ec2" {
  ami           = "amzn2-ami-hvm-x86_64-gp2"  
  instance_type = "t2.micro" 
  key_name               = aws_key_pair.my_keypair.key_name
  security_groups        = [aws_security_group.ssh_sg.name]  
  iam_instance_profile   = [module.res.iam_role, aws_iam_role.efs_write_role]
  depends_on = [aws_s3_bucket.my_bucket]
  
  provisioner "remote-exec" {
    inline = [
      "sudo yum install -y nfs-utils", 
      "sudo mkdir -p /data/my-efs",  
      "sudo mount -t nfs4 ${aws_efs_file_system.my_efs.dns_name}:/ /mnt/my-efs",
      "echo '${aws_efs_file_system.my_efs.dns_name}:/ /mnt/my-efs nfs4 defaults 0 0' | sudo tee -a data/test",  # Persist mount
    ]   
  }
}

#EIP attachment
resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.my_ec2.id  
  allocation_id = aws_eip.my_eip.id      
}

##outputs
output "efs_arn" {
  value = aws_efs_file_system.my_efs.arn
}

output "ec2_arn" {
  value = aws_instance.my_ec2.arn
}

output "sg_id" {
  value = aws_security_group.ssh_sg.arn
}

