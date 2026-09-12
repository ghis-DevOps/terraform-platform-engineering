# Configures cost allocation tag activation in Billing Dashboard

# resource "aws_ce_cost_allocation_tag" "standard_tags" {
#   for_each = toset(["Environment", "Owner", "Project", "CostCenter"])
#   tag_key  = each.value
#   status   = "Active"
# }




