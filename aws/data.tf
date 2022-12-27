data "http" "my_ip_address" {
  url = var.ip_check_website

  lifecycle {
    postcondition {
      condition     = contains([200], self.status_code)
      error_message = "Status code ${self.status_code} is invalid, 200 is the expected"
    }
    postcondition {
      condition     = can(cidrnetmask(self.response_body))
      error_message = "Response body must be a valid IPv4 CIDR block address, not \"${self.response_body}\""
    }
  }

}
