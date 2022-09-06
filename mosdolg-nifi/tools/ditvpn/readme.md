Install and Setup.
--

1. Obtain account credentials and certificate with password from DIT
2. Install Vagrant
3. Install Virtual Machine engine (Virtual Box or Parallels)
    
    3.1 Choose your Virtual Machine engine and apply to *Vagrantfile*. Comment and uncomment accordingly your preferences.   
    3.2 Source box
          
          # Parallels
          config.vm.box = "bento/ubuntu-16.04"
          # VirtualBox
          # config.vm.box = "ubuntu/xenial64"
    3.3 Configuration
    
            # Parallels
            server.vm.provider "parallels" do |prl|
               prl.name = "DIT-VPN"
               prl.memory = 512
               prl.cpus = 1
            end
            # VirtualBox
            # server.vm.provider "virtualbox" do |vb|
            #   vb.customize ["modifyvm", :id, "--cpus", "1"]
            #   vb.name = "DIT-VPN"
            #   vb.memory = 512
            # end               
4. Execute on local machine follow commands
    * export DIT_MD_VPN_USER=[YOUR ACCOUNT NAME]
    * export DIT_MD_VPN_PASS='[YOUR ACCOUNT PASSWORD]'
    * export DIT_MD_VPN_CERT_PASS='[YOUR CERTIFICATE PASSWORD]'
    Anyway, setup your environment variables. 
        
        Note: This should be done one time only before build VM or every time before provision.
5. Copy your certificate *.pfx into *provision* folder
6. Execute *vagrant up* and wait until your will see successful message:     
        
        ditvpn: DONE
7. Restart your VM *vagrant reload* and wait a little bit. 
8. Connect into your machine *vagrant ssh*
9. Execute *~/vpn/mon-forticlientsslvpn-expect.sh* and you will see 
        
        STATUS::Tunnel running
        
   After successful tunnelling your have opened 2 ports of your VM
   * VM IP ADDR:22222(10.89.1.20:22) - ssh gate to all other VPS on DIT premises 
   * VM IP ADDR:8443(172.24.63.139:8443) - NiFi Node1 Web Interface. (Your should adjust your hosts file to name VM IP as SMD-BUS01P)
10. Don't close current session until your need go home. 
11. Now you are able to connect any VPN resources via SSH.
12. Brief user guide to vagrant
    * vagrant up - Start/Provision of your VM
    * vagrant halt - Stop your VM
    * vagrant reload - Restart your VM
    * vagrant ssh - Connect into your VM
    * vagrant destroy - Remove your VM from host.