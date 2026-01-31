variable "prefix" {
  type    = string
  default = "devops-challenge"
}

variable "location" {
  type    = string
  default = "westeurope"
}

variable "location_b" {
  type    = string
  default = "northeurope"
}

variable "tags" {
  type = map(string)
  default = {
    purpose = "devops-challenge"
    author  = "ilarion"
  }
}

variable "kubernetes_version" {
  type    = string
  default = null
}

variable "node_vm_size" {
  type    = string
  default = "Standard_D2s_v5"
}

variable "node_count" {
  type    = number
  default = 2
}
