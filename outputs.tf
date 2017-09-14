output "winrm_sg" {
  value = "${aws_security_group.winrm.id}"
}
