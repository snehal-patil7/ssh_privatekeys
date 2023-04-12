##################################
# Tags
##################################
variable tags {
  description = "default tags to use"

  default = {
    ##  PCS  based tags
    Environment     = "DEV"
    PONumber        = "PO1502522145"
    LMEntity        = "VFDE"
    BU              = "LOCAL-MARKET"
    Project         = "Solstice"
    ManagedBy       = "heisenberg@vodafone.com"
    SecurityZone    = "I-A"
    Confidentiality = "C2"
    TaggingVersion  = "V2.4"
    BusinessService = "DE-AWS-ART-DEV02-TEST"
    ## VFDE based tags
    GeneratedBy = "Team Heisenberg TF"
  }
}
