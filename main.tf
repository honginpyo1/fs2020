resource "ibm_is_ssh_key" "ssh1" {
  name       = "sshkey_20200302"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDawgux7227+hFO/j8I81J3QfUQI2qKCVSrvQ+z2Z2rouyAwUILknR0GNCxOg9nePSheBhlywkOJwVYHBvxFHoLDNcYJQONqYEevi/Pcoin52wmamGwLwozGpmA1O7yXRJPOovCiGHTuHNr7hKvlkOJLwIoGX9YdxirAdlpvIJ479u8hJtNebAehsRjqxrgpeGQFbksx7hLytY0GUORplR7V3RKT9VHJxeiJLypcOMqVKrOuqhxITJ/SQ9SaijnDscZRMVu5kJJzaT5mzw080imw8sGrDj1C9Sh7zV9c9Fedtc5RJEZSXu8ZRElQkZ1XDpZeviHTwlBaFSJm6A7MysEE4M7PNGAjjPUswo85mMWenI751k+1N6t+wqh6kCxkqbBLrRTjfpDLfUOYLPDrS3NwgsTuk3Ry0dVIGO2lgyfsfMjFAGZpMpMpO0lB8TVjtdzDKjbgkucP2LESfUyYiGaafCKxYzTeJQwTqEy2JnKfqKYpD2oSBlokxMVOlMT2Y7hOwdgdPovimbusJ9FABCRuAlVExRk4mzVDJAZZk5UNyYGITwS4ZO7nOOwrZ9uTBQquGWuc6V9LSROSSVAFK4pUM0ySIG31Tkvjd98hOCy9lWhLFetnxKkMvKb3DP9EuSDNLUk89oshyvSZB0hTq/iWIbouJnq37D0TIqAc4GV3w== honginpyo1@hanmail.net"
}

resource "ibm_is_vpc" "vpc1" {
  name = "${var.vpc_name}"
}

resource "ibm_is_vpc_address_prefix" "vpc-ap1" {
  name = "vpc-ap1"
  zone = "${var.zone1}"
  vpc  = "${ibm_is_vpc.vpc1.id}"
  cidr = "${var.zone1_cidr}"
}

resource "ibm_is_vpc_address_prefix" "vpc-ap2" {
  name = "vpc-ap2"
  zone = "${var.zone2}"
  vpc  = "${ibm_is_vpc.vpc1.id}"
  cidr = "${var.zone2_cidr}"
}

resource "ibm_is_vpc_address_prefix" "vpc-ap3" {
  name = "vpc-ap3"
  zone = "${var.zone3}"
  vpc  = "${ibm_is_vpc.vpc1.id}"
  cidr = "${var.zone3_cidr}"
}

resource "ibm_is_subnet" "subnet1" {
  name            = "subnet1"
  vpc             = "${ibm_is_vpc.vpc1.id}"
  zone            = "${var.zone1}"
  ipv4_cidr_block = "${var.zone1_cidr}"
  depends_on      = ["ibm_is_vpc_address_prefix.vpc-ap1"]
}

resource "ibm_is_subnet" "subnet2" {
  name            = "subnet2"
  vpc             = "${ibm_is_vpc.vpc1.id}"
  zone            = "${var.zone2}"
  ipv4_cidr_block = "${var.zone2_cidr}"
  depends_on      = ["ibm_is_vpc_address_prefix.vpc-ap2"]
}

resource "ibm_is_subnet" "subnet3" {
  name            = "subnet3"
  vpc             = "${ibm_is_vpc.vpc1.id}"
  zone            = "${var.zone3}"
  ipv4_cidr_block = "${var.zone3_cidr}"
  depends_on      = ["ibm_is_vpc_address_prefix.vpc-ap3"]
}

resource "ibm_is_instance" "instance1" {
  name    = "instance1"
  image   = "${var.image}"
  profile = "${var.profile}"

  primary_network_interface = {
    subnet = "${ibm_is_subnet.subnet1.id}"
  }
  vpc  = "${ibm_is_vpc.vpc1.id}"
  zone = "${var.zone1}"
  keys = ["${ibm_is_ssh_key.ssh1.id}"]
  user_data = "${data.template_cloudinit_config.cloud-init-apptier.rendered}"
}

resource "ibm_is_instance" "instance2" {
  name    = "instance2"
  image   = "${var.image}"
  profile = "${var.profile}"

  primary_network_interface = {
    subnet = "${ibm_is_subnet.subnet2.id}"
  }
  vpc  = "${ibm_is_vpc.vpc1.id}"
  zone = "${var.zone2}"
  keys = ["${ibm_is_ssh_key.ssh1.id}"]
  user_data = "${data.template_cloudinit_config.cloud-init-apptier.rendered}"
}

resource "ibm_is_instance" "instance3" {
  name    = "instance3"
  image   = "${var.image}"
  profile = "${var.profile}"

  primary_network_interface = {
    subnet = "${ibm_is_subnet.subnet3.id}"
  }
  vpc  = "${ibm_is_vpc.vpc1.id}"
  zone = "${var.zone3}"
  keys = ["${ibm_is_ssh_key.ssh1.id}"]
  user_data = "${data.template_cloudinit_config.cloud-init-apptier.rendered}"
}

resource "ibm_is_floating_ip" "floatingip1" {
  name = "fip1"
  target = "${ibm_is_instance.instance1.primary_network_interface.0.id}"
}

resource "ibm_is_floating_ip" "floatingip2" {
  name = "fip2"
  target = "${ibm_is_instance.instance2.primary_network_interface.0.id}"
}

resource "ibm_is_floating_ip" "floatingip3" {
  name = "fip3"
  target = "${ibm_is_instance.instance3.primary_network_interface.0.id}"
}

resource "ibm_is_security_group_rule" "sg1_tcp_rule_22" {
  depends_on = ["ibm_is_floating_ip.floatingip1", "ibm_is_floating_ip.floatingip2","ibm_is_floating_ip.floatingip3"]
  group     = "${ibm_is_vpc.vpc1.default_security_group}"
  direction = "inbound"
  remote    = "0.0.0.0/0"
  tcp = {
    port_min = "22"
    port_max = "22"
  }
}

resource "ibm_is_security_group_rule" "sg1_tcp_rule_80" {
  depends_on = ["ibm_is_floating_ip.floatingip1", "ibm_is_floating_ip.floatingip2","ibm_is_floating_ip.floatingip3"]
  group     = "${ibm_is_vpc.vpc1.default_security_group}"
  direction = "inbound"
  remote    = "0.0.0.0/0"
  tcp = {
    port_min = "80"
    port_max = "80"
  }
}
