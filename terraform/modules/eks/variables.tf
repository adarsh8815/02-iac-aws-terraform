variable "project"            { type = string }
variable "env"                { type = string }
variable "vpc_id"             { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "kubernetes_version" { type = string; default = "1.29" }
variable "allowed_cidrs"      { type = list(string); default = ["0.0.0.0/0"] }
variable "tags"               { type = map(string); default = {} }

variable "node_groups" {
  type = map(object({
    instance_types = list(string)
    capacity_type  = string
    desired_size   = number
    min_size       = number
    max_size       = number
    labels         = map(string)
    taints         = optional(list(object({ key = string, value = optional(string), effect = string })), [])
  }))
}
