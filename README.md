Do you ever get sick of using the same subnets when you're designing networks?
Cant decide what ip address range you should use?
Dont want to use the default 192.168.0.1/24 172.16.0.1/12 or 10.0.0.1/8
Want to limit the amount of addresses to suit your use case?

Never fear, I have created this powershell script to fix your indecision.
It prompts for an input of how many ip addresses that you need and then generates a random subnet to fullfil your needs.

-----------------------------------------------------------------------------------

Sample Outputs:
Enter the required number of IP addresses for the subnet: 70

Name             Value          
----             -----          
Starting IP      172.16.139.100 
Ending IP        172.16.139.225 
Subnet Mask      255.255.255.128
CIDR             /25            
Usable Addresses 126            
Range Type       Private

Enter the required number of IP addresses for the subnet: 300

Name             Value        
----             -----        
Starting IP      10.33.149.50 
Ending IP        10.33.151.47 
Subnet Mask      255.255.254.0
CIDR             /23          
Usable Addresses 510          
Range Type       Private      

Enter the required number of IP addresses for the subnet: 600

Name             Value        
----             -----        
Starting IP      10.47.75.231 
Ending IP        10.47.79.228 
Subnet Mask      255.255.252.0
CIDR             /22          
Usable Addresses 1022         
Range Type       Private  

Enter the required number of IP addresses for the subnet: 15000000 (yes that is 15 Million)

Name             Value        
----             -----        
Starting IP      10.221.110.47
Ending IP        11.221.110.44
Subnet Mask      255.0.0.0    
CIDR             /8           
Usable Addresses 16777214     
Range Type       Private
-----------------------------------------------------------------------------------
Current known issue is if you need more ip address than what private networking allows it will still give a valid range which will of course then not be within the private addressing range.
