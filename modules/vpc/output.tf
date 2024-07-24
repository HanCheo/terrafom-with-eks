output "id" {
	value = aws_vpc.moby_vpc.id
	description = "The ID of the VPC"
}

output "private_subnet_ids" {
	value = [ for i in aws_subnet.private_subnet : i.id ]
	description = "The ID of the private subnet"
}