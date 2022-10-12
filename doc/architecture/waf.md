Where WAF fits into our network layout:

```plantuml
' C4 containers
!includeurl https://raw.githubusercontent.com/RicardoNiepel/C4-PlantUML/release/1-0/C4_Container.puml

' AWS Icons
!define AWSPuml https://raw.githubusercontent.com/awslabs/aws-icons-for-plantuml/v13.0/dist
!include AWSPuml/AWSC4Integration.puml
!include AWSPuml/AWSCommon.puml
!include AWSPuml/AWSSimplified.puml
!include AWSPuml/General/all.puml
!include AWSPuml/NetworkingContentDelivery/all.puml
!include AWSPuml/Compute/all.puml
!include AWSPuml/SecurityIdentityCompliance/all.puml

title Request Flow for Gitlab (w/WAF)
Boundary(vpn, "GSA VPN") {
        Users(vpnusers, "Users", "")
}

Users(users, "Users", "")

Boundary(vpc, "Gitlab VPC") {
        ElasticLoadBalancingNetworkLoadBalancer(nlb, "NLB", )
        note left
                NLBs don't have security groups. Manage access via targets' security groups.

                NLBs preserve the client's IP. For VPC Endpoints, this is the Gitlab-VPC-internal IP. For NAT, this is the NAT's public IP.
        end note
        EC2Instances(runners, "Runners", )
        EC2Instances(proxies, "OBProxies", )
        EC2Instance(gitlab, "Gitlab", )
        Boundary(albconfig, "ALB"){
                WAF(waf, "WAF",)
                WAFRule(wafrules, "Rules",)
                ElasticLoadBalancingApplicationLoadBalancer(alb, "LB", )
        }
}

Boundary(envvpc, "Env VPC") {
        VPCEndpoints(endpoint, "Endpoint", "")
        EC2Instances(envrunners, "Runners", "")
                EC2Instances(envproxies, "OBProxies", )

}

VPCNATGateway(nat, "NAT",)

vpnusers -down-> nlb
users -down-> nlb
endpoint -down-> nlb
envrunners -> envproxies
envproxies -> endpoint
runners -up-> proxies
nlb -down-> alb: 443
nlb -down-> gitlab: 22
alb -left- waf
waf -left- wafrules
alb -down-> gitlab
gitlab -> proxies
proxies -> nat
nat -down-> nlb
```
