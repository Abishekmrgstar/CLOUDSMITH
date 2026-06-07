output "public_ip" {
  value = aws_instance.app.public_ip
}

output "instance_id" {
  value = aws_instance.app.id
}

output "app_url" {
  value = "http://${aws_instance.app.public_ip}"
}