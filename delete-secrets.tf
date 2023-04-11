resource "null_resource" "delete_secrets_files" {
  for_each = local.secrets

  triggers = {
    file_path = local_file.secrets_files[each.key].filename
  }

  // Only delete the file after the bastion host is created
  depends_on = [aws_instance.bastion_host]

  provisioner "local-exec" {
    command = "rm -f ${local_file.secrets_files[each.key].filename}"
  }
}
