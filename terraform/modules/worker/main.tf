resource "null_resource" "worker" {
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get -y install socat conntrack ipset",
      ""
    ]
  }
}