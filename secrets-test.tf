locals {
  secrets = {
    "snehal_privatekey" = "private_key.txt",
    "snehal_cert"       = "cert.txt"
  }
}

data "aws_secretsmanager_secret" "secrets" {
  for_each = local.secrets

  name = each.key
}

data "aws_secretsmanager_secret_version" "secrets" {
  for_each = data.aws_secretsmanager_secret.secrets

  secret_id = each.value.id
}

resource "local_file" "secrets_files" {
  for_each = local.secrets

  content = data.aws_secretsmanager_secret_version.secrets[data.aws_secretsmanager_secret.secrets[each.key].name].secret_string

  filename = each.value
}

resource "null_resource" "delete_secrets_files" {
  for_each = local.secrets

  triggers = {
    file_path = local_file.secrets_files[each.key].filename
  }

  #provisioner "local-exec" {
  #  command = "rm -f ${local_file.secrets_files[each.key].filename}"
  #}
  provisioner "local-exec" {
    command = "echo '${data.aws_secretsmanager_secret_version.secrets[data.aws_secretsmanager_secret.secrets[each.key].name].secret_string}' > ${each.value}"
  }
  
}
