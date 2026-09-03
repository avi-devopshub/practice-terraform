resource "aws_s3_bucket" "bucket"{
    count = 10
    bucket = "avinash-terraform-03092026-${count.index}"
    tags = {
        Name = "avinash-terraform-03092026-${count.index}"
        Environment = "Dev"
    }
}