resource "aws_dynamodb_table" "basic-dynamodb-table" {
  name           = "Movies"
  billing_mode   = "PROVISIONED"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "Year"
  range_key      = "Title"

  attribute {
    name = "Year"
    type = "N"
  }

  attribute {
    name = "Title"
    type = "S"
  }

}