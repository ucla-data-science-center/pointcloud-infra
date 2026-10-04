output "instance_id" {
  description = "New web server instance."
  value       = aws_instance.web.id
}

output "instance_public_ip" {
  description = "Temporary public IP of the new server, for testing before cutover."
  value       = aws_instance.web.public_ip
}

output "elastic_ip" {
  description = "Public IP that pointcloud.ucla.edu resolves to."
  value       = aws_eip.public.public_ip
}

output "eip_points_at" {
  description = "Which server currently receives pointcloud.ucla.edu traffic."
  value       = var.eip_target
}

output "test_before_cutover" {
  description = "Preview the new server under the real hostname without touching DNS."
  value       = "curl -k --resolve www.pointcloud.ucla.edu:443:${aws_instance.web.public_ip} https://www.pointcloud.ucla.edu/"
}
