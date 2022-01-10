package subnet

import (
	"fmt"
	"multy-go/resources/common"
)

const AzureResourceName = "azurerm_subnet"

type AzureSubnet struct {
	common.AzResource  `hcl:",squash"`
	AddressPrefixes    []string `hcl:"address_prefixes"`
	VirtualNetworkName string   `hcl:"virtual_network_name,expr"`
	ServiceEndpoints   []string `hcl:"service_endpoints" hcle:"omitempty"`
}

func (subnet *AzureSubnet) GetId() string {
	return fmt.Sprintf("azurerm_subnet.%s.id", subnet.ResourceId)
}