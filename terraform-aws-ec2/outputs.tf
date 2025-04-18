output "instance_id" {
  value = aws_instance.windows_vm.id
}

output "public_ip" {
  value = aws_instance.windows_vm.public_ip
}
