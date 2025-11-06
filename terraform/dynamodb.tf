resource "aws_dynamodb_table" "connections" {
  name           = "social-battery-connections"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "pk"
  attribute {
    name = "pk"
    type = "S"
  }
  attribute {
    name = "sk"
    type = "S"
  }
  tags = {
    Name = "social-battery-connections"
  }
}

resource "aws_dynamodb_table" "devices" {
  name = "social-battery-devices"
  billing_mode = "PAY_PER_REQUEST"
  hash_key = "pk"
  attribute {
    name = "pk"
    type = "S"
  }
  attribute {
    name = "sk"
    type = "S"
  }
  tags = {
    Name = "social-battery-devices"
  }
}
