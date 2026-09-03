resource "aws_s3_bucket" "bucket"{
    bucket = "avinash-terraform-03092026"
    tags = {
        Name = "avinash-terraform-03092026"
        Environment = "Dev"
    }
}