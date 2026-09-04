output "vpc" {
    value = aws_vpc.default.id
}
output "subnets"{
    value = data.aws_subnets.default.ids
}