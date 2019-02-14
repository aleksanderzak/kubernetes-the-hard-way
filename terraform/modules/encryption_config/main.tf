resource "random_string" "encryption_key" {
  length = 32
}

data "template_file" "encryption_config" {
  template = "${file("${path.module}/resources/encryption_config.template")}"

  vars {
    encryption_key = "${base64encode(random_string.encryption_key.result)}"
  }
}

resource "null_resource" "distribute_encryption_key" {
  count = "${var.node_count}"

  connection {
      type         = "ssh"
      user         = "${var.node_user}"
      host         = "${element(var.nodes, count.index)}"
      bastion_host = "${var.bastion_host}"
  }

  provisioner "file" {
    destination = "${var.encryption_key_path}"
    content     = "${data.template_file.encryption_config.rendered}"
  }

  triggers {
    templates = "${data.template_file.encryption_config.rendered}"
  }
}