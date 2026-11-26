variable "region" {
  type    = string
  default = "eu-north-1"
}

variable "spokes" {
  type = map(string)
  default = {
    prod   = "10.0.0.0/16"
    dev    = "10.1.0.0/16"
    shared = "10.2.0.0/16"
  }
}
