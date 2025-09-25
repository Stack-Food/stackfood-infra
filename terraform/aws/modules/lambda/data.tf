data "archive_file" "lambda_placeholder" {
  type        = "zip"
  output_path = "${path.module}/empty-function.zip"

  source {
    content = templatefile("${path.module}/templates/dummyValue.txt", {
      function_name = var.function_name
    })
    filename = "index.js"
  }
}
