variable "project_name"  { type = string; default = "myapp" }
variable "aws_region"    { type = string; default = "us-east-1" }
variable "allowed_cidrs" { type = list(string); default = ["10.0.0.0/8"] }
