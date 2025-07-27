resource "aws_security_group" "sg" {
	name = "teste-sg-${var.project_name}"
	description = "Usado para expor o servico"
	vpc_id = aws_vpc.main.id

	ingress {
		from_port = 80
		to_port = 80
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
		description = "Allow HTTP traffic"
	}

	egress {
		from_port = 0
		to_port = 0
		protocol = "-1"
		cidr_blocks = ["0.0.0.0/0"]
		description = "Allow all traffic"
	}
}