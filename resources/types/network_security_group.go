package types

import (
	"fmt"
	"multy-go/resources"
	"multy-go/resources/common"
	"multy-go/resources/output/network_security_group"
	rg "multy-go/resources/resource_group"
	"multy-go/validate"
	"strconv"
)

/*
Notes
NSG can only be applied to NIC (currently done in VM creation, to be changed to separate resource)
When NSG is applied, only rules specified are allowed.
AWS: VPC traffic is always added as an extra rule
*/

type NetworkSecurityGroup struct {
	*resources.CommonResourceParams
	Name             string     `hcl:"name"`
	VirtualNetworkId string     `hcl:"virtual_network_id"`
	Rules            []RuleType `hcl:"rules,optional"`
}

type RuleType struct {
	Protocol  string `cty:"protocol"`
	Priority  int    `cty:"priority"`
	FromPort  string `cty:"from_port"`
	ToPort    string `cty:"to_port"`
	CidrBlock string `cty:"cidr_block"`
	Direction string `cty:"direction"`
}

const (
	INGRESS = "ingress"
	EGRESS  = "egress"
	BOTH    = "both"
	ALLOW   = "allow"
	DENY    = "deny"
)

func (r *NetworkSecurityGroup) Translate(cloud common.CloudProvider, ctx resources.MultyContext) []interface{} {
	var virtualNetwork *VirtualNetwork
	if vn, err := ctx.GetResource(r.VirtualNetworkId); err != nil {
		r.LogFatal(r.ResourceId, "virtual_network_id", err.Error())
	} else {
		virtualNetwork = vn.Resource.(*VirtualNetwork)
	}

	if cloud == common.AWS {
		awsRules := translateAwsNsgRules(r, r.Rules)

		allowVpcTraffic := network_security_group.AwsSecurityGroupRule{
			Protocol:   "-1",
			FromPort:   0,
			ToPort:     0,
			CidrBlocks: []string{virtualNetwork.CidrBlock},
		}

		awsRules[INGRESS] = append(awsRules[INGRESS], allowVpcTraffic)
		awsRules[EGRESS] = append(awsRules[EGRESS], allowVpcTraffic)

		return []interface{}{
			network_security_group.AwsSecurityGroup{
				AwsResource: common.AwsResource{
					ResourceName: network_security_group.AwsSecurityGroupResourceName,
					ResourceId:   r.GetTfResourceId(cloud),
					Tags:         map[string]string{"Name": r.Name},
				},
				VpcId:   virtualNetwork.GetVirtualNetworkId(cloud),
				Ingress: awsRules["ingress"],
				Egress:  awsRules["egress"],
			},
		}
	} else if cloud == common.AZURE {
		return []interface{}{
			network_security_group.AzureNsg{
				AzResource: common.AzResource{
					ResourceName:      network_security_group.AzureNetworkSecurityGroupResourceName,
					ResourceId:        r.GetTfResourceId(cloud),
					Name:              r.Name,
					ResourceGroupName: rg.GetResourceGroupName(r.ResourceGroupId, cloud),
					Location:          ctx.GetLocationFromCommonParams(r.CommonResourceParams, cloud),
				},
				Rules: translateAzNsgRules(r.Rules),
			},
		}
	}
	validate.LogInternalError("cloud %s is not supported for this resource type ", cloud)
	return nil
}

func (r NetworkSecurityGroup) GetId(cloud common.CloudProvider) string {
	if cloud == common.AWS {
		return fmt.Sprintf("%s.%s.id", network_security_group.AwsSecurityGroupResourceName, r.GetTfResourceId(cloud))
	} else if cloud == common.AZURE {
		return fmt.Sprintf("%s.%s.id", network_security_group.AzureNetworkSecurityGroupResourceName, r.GetTfResourceId(cloud))
	}
	validate.LogInternalError("cloud %s is not supported for this resource type ", cloud)
	return ""
}

func translateAwsNsgRules(r *NetworkSecurityGroup, rules []RuleType) map[string][]network_security_group.AwsSecurityGroupRule {
	awsRules := map[string][]network_security_group.AwsSecurityGroupRule{}

	for _, rule := range rules {
		var awsFromPort, awsToPort int
		var awsProtocol string
		var err error

		if rule.FromPort == "*" {
			awsFromPort = 0
		} else {
			awsFromPort, err = strconv.Atoi(rule.FromPort)
			if err != nil {
				r.LogFatal(r.ResourceId, "rules", fmt.Sprintf("Invalid FromPort: %s", err.Error()))
			}
		}

		if rule.ToPort == "*" {
			awsToPort = 0
		} else {
			awsToPort, err = strconv.Atoi(rule.FromPort)
			if err != nil {
				r.LogFatal(r.ResourceId, "rules", fmt.Sprintf("Invalid ToPort: %s", err.Error()))
			}
		}

		awsProtocol = rule.Protocol
		if rule.Protocol == "*" {
			awsProtocol = "-1"
			awsFromPort = 0
			awsToPort = 0
		}

		if rule.Direction == BOTH {
			awsRules[INGRESS] = append(awsRules[INGRESS], network_security_group.AwsSecurityGroupRule{
				Protocol:   awsProtocol,
				FromPort:   awsFromPort,
				ToPort:     awsToPort,
				CidrBlocks: []string{rule.CidrBlock},
			})
			awsRules[EGRESS] = append(awsRules[EGRESS], network_security_group.AwsSecurityGroupRule{
				Protocol:   awsProtocol,
				FromPort:   awsFromPort,
				ToPort:     awsToPort,
				CidrBlocks: []string{rule.CidrBlock},
			})
		} else {
			awsRules[rule.Direction] = append(awsRules[rule.Direction], network_security_group.AwsSecurityGroupRule{
				Protocol:   awsProtocol,
				FromPort:   awsFromPort,
				ToPort:     awsToPort,
				CidrBlocks: []string{rule.CidrBlock},
			})
		}
	}
	return awsRules
}

func translateAzNsgRules(rules []RuleType) []network_security_group.AzureRule {
	m := map[string]string{
		"ingress": "Inbound",
		"egress":  "Outbound",
	}

	var rls []network_security_group.AzureRule

	for _, rule := range rules {
		if rule.Direction == BOTH {
			rls = append(rls, network_security_group.AzureRule{
				Name:                     strconv.Itoa(len(rls)),
				Protocol:                 rule.Protocol,
				Priority:                 rule.Priority,
				Access:                   "Allow",
				SourcePortRange:          "*",
				SourceAddressPrefix:      "*",
				DestinationPortRange:     fmt.Sprintf("%s-%s", rule.ToPort, rule.FromPort),
				DestinationAddressPrefix: "*",
				Direction:                m[INGRESS],
			})
			rls = append(rls, network_security_group.AzureRule{
				Name:                     strconv.Itoa(len(rls)),
				Protocol:                 rule.Protocol,
				Priority:                 rule.Priority,
				Access:                   "Allow",
				SourcePortRange:          "*",
				SourceAddressPrefix:      "*",
				DestinationPortRange:     fmt.Sprintf("%s-%s", rule.ToPort, rule.FromPort),
				DestinationAddressPrefix: "*",
				Direction:                m[EGRESS],
			})
		} else {
			rls = append(rls, network_security_group.AzureRule{
				Name:                     strconv.Itoa(len(rls)),
				Protocol:                 rule.Protocol,
				Priority:                 rule.Priority,
				Access:                   "Allow",
				SourcePortRange:          "*",
				SourceAddressPrefix:      "*",
				DestinationPortRange:     fmt.Sprintf("%s-%s", rule.ToPort, rule.FromPort),
				DestinationAddressPrefix: "*",
				Direction:                m[rule.Direction],
			})
		}
	}

	return rls
}

func validateRuleDirection(s string) bool {
	return s == INGRESS || s == EGRESS || s == BOTH
}

func validateRuleAction(s string) bool {
	return s == ALLOW || s == DENY
}

func validatePort(s string) bool {
	if i, err := strconv.Atoi(s); err != nil || i < -1 {
		return false
	}
	return true
}

func (r *NetworkSecurityGroup) Validate(ctx resources.MultyContext) {
	for _, rule := range r.Rules {
		// TODO: get better source ranges
		if !validateRuleDirection(rule.Direction) {
			r.LogFatal(r.ResourceId, "rules", fmt.Sprintf("rule direction \"%s\" is not valid. direction must be \"%s\", \"%s\" or \"%s\"", rule.Direction, INGRESS, EGRESS, BOTH))
		}
		if !validatePort(rule.ToPort) {
			r.LogFatal(r.ResourceId, "rules", fmt.Sprintf("rule to_port \"%s\" is not valid", rule.ToPort))
		}
		if !validatePort(rule.FromPort) {
			r.LogFatal(r.ResourceId, "rules", fmt.Sprintf("rule from_port \"%s\" is not valid", rule.FromPort))
		}
		// TODO validate CIDR
		//		validate protocol
	}
	// TODO validate location matches with VN location
	return
}