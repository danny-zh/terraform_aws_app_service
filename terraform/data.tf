# Get data about available AZ in the region
data "aws_availability_zones" "az" {
  state = "available"
}

