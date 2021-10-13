output "slacko-mongodb" {
    value = aws_instance.mongodb.private_ip
}
output "slacko-app" {
    value = aws_instance.slacko-app.public_ip
}
