resource "aws_s3_bucket" "my_bucket" {
  bucket = "akshay-netspi" 
  acl    = "private"
}

resource "aws_iam_role" "s3_write_role" {
  name               = "s3-write-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"  
      },
      Action    = "sts:AssumeRole"
    }]
  })
}


resource "aws_iam_role_policy" "s3_write_policy" {
  name   = "s3-write-policy"
  role   = aws_iam_role.s3_write_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Action    = "s3:PutObject",
        Resource  = aws_s3_bucket.my_bucket.arn + "/*"
      }
    ]
  })
}

output "iam_role" {
  value = aws_iam_role.s3_write_role.id
}

output "bucket_arn" {
    value = aws_s3_bucket.my_bucket.arn
}