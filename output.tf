output "public_ip" {
  value = aws_instance.instance[*].public_ip
}

output "tag_name" {
  value = aws_instance.instance[*].tags
}

output "win_public" {
  value = aws_instance.win_instance.public_ip
}
