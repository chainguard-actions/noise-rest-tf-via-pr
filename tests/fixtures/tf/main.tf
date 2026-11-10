variable "message" {
  type    = string
  default = "hello"
}

resource "terraform_data" "example" {
  input = var.message
}
