#== Class: pxe_server
#
class pxe_server (


        # Array of the necessary packages to be installed
        $packages = ['xinetd', 'tftp-server', 'dnsmasq', 'httpd', 'pykickstart', 'nfs-utils', 'syslinux'],

        # Array of ISOs to provide via TFTP.
        $isos = ['OracleLinux_7_3'],
        # Array of ISOs to provide a Kickstart file for. This might be coincidentally identical to the Array of ISOs "$isos", but can also just be a subset..
        $ks_locations = ['OracleLinux_7_3'],
        # Array of Kickstart file names. For example the files will be named according to the hostname of the machine they install.
        $ks_names = ['db001srv', 'db002srv', 'loadb001srv', 'loadb002srv', 'queue001srv', 'queue002srv', 'stor001srv', 'stor002srv', 'web001srv', 'web002srv'],

        # NFS Sharepoint where the ISOs are stored.
        $iso_library_location = 'iso001srv.mydomain.tld:/iso',
        # Path where to mount the NFS Sharepoint.
        $iso_library_mount_path = '/mnt/',

        # Path where the individual ISOs will be mounted. Here it is placed in the default webserver root directory
        $iso_mount_path_parent = '/var/www/html/',

        # Owner for files and folders
        $owner = 'root',
        # Group for files and folders
        $group = 'root',
        # Mode (octal) for files
        $filemode = '0444',
        # Mode (octal) for folders
        $foldermode = '0555',

        # Location of the PXE Boot Menu file.
        $pxefile = '/tftpboot/pxelinux.cfg/default',

        # Puppet bucket URI where the Kickstart files can be found.
        $kickstart_source = 'puppet:///modules/pxe_server/',

        # IP address of the PXE/TFTP server.
        $pxe_server_ip = '10.0.0.250',
        #
        $pxe_server_name = 'pxe001srv',
        # IP address of the webserver.
        $web_server_ip = '10.0.0.250',

        # DHCP Ramhge Begn IP address
        $dhcp_range_begin = '10.0.0.240',
        # DHCP Ramhge End IP address
        $dhcp_range_end = '10.0.0.249',
        # DHCP IP address lease time
        $dhcp_range_leasetime = '1h',
) {
#               notify{"isos are: ${isos}": }
#               notify{"ks_locations are: ${ks_locations}": }
#               notify{"ks_names are: ${ks_names}": }
#               notify{"packages are: ${packages}": }
#               notify{"iso_library_location is: ${iso_library_location}": }
#               notify{"iso_library_mount_path is: ${iso_library_mount_path}": }
#               notify{"iso_mount_path_parent is: ${iso_mount_path_parent}": }
#               notify{"owner are: ${owner}": }
#               notify{"group are: ${group}": }
#               notify{"filemode are: ${filemode}": }
#               notify{"foldermode are: ${foldermode}": }
#               notify{"pxefile is: ${pxefile}": }
#               notify{"kickstart_source is: ${kickstart_source}": }
#               notify{"pxe_server_ip are: ${pxe_server_ip}": }
#               notify{"web_server_ip are: ${web_server_ip}": }
        # Install all necessary packages
        package { $packages: ensure => 'installed' }
        # Configuration for tftp-server daemon
        file_line { 'tftp_on':
                ensure => present,
                path   => '/etc/xinetd.d/tftp',
                line   => "\tdisable\t\t\t= no",
                match  => "\\tdisable\\t\\t\\t= ",
        }
        file_line { 'tftp_server_args':
                ensure => present,
                path   => '/etc/xinetd.d/tftp',
                line   => "\tserver_args\t\t= -s /tftpboot",
                match  => "\\tserver_args\\t\\t= ",
        }
        # Configuration for tftp-server service
        file_line { 'tftp_service_cwd':
                ensure => present,
                path   => '/usr/lib/systemd/system/tftp.service',
                line   => 'ExecStart=/usr/sbin/in.tftpd -s /tftpboot',
                match  => '^ExecStart=/usr/sbin/in.tftpd',
                after  => '\[Service\]',
        }
        file_line { 'tftp_service_wanted':
                ensure => present,
                path   => '/usr/lib/systemd/system/tftp.service',
                line   => 'WantedBy=multi-user.target',
                match  => '^WantedBy=',
                after  => '\[Install\]',
        }
        # Configuration for dnsmasq
        file_line { 'dnsmasq_domain':
                ensure => present,
                path   => '/etc/dnsmasq.conf',
                line   => 'domain=mydomain.tld',
                match  => '^domain=',
        }
        file_line { 'dnsmasq_dhcp_range':
                ensure => present,
                path   => '/etc/dnsmasq.conf',
                line   => "dhcp-range=${dhcp_range_begin},${dhcp_range_end},${dhcp_range_leasetime}",
                match  => '^dhcp-range=',
        }
        file_line { 'dnsmasq_dhcp_boot':
                ensure => present,
                path   => '/etc/dnsmasq.conf',
                line   => "dhcp-boot=pxelinux.0,${pxe_server_name},${pxe_server_ip}",
                match  => '^dhcp-boot=',
        }
        # Mount ISO share, create mount paths for ISO(s) and mount ISO(s), create tftp folders and files
        mount { $iso_library_mount_path:
                        ensure  => 'mounted',
                        fstype  => 'nfs',
                        atboot  => true,
                        device  => $iso_library_location,
                        require => Package['nfs-utils'],
        }
        file { '/tftpboot/':
                        ensure => 'directory',
                        owner  => $owner,
                        group  => $group,
                        mode   => $foldermode,
        }
        file { '/tftpboot/pxelinux.0':
                        ensure  => 'file',
                        source  => '/usr/share/syslinux/pxelinux.0',
                        mode    => $filemode,
                        require => File['/tftpboot/'],
        }
        file { '/tftpboot/vesamenu.c32':
                        ensure  => 'file',
                        source  => '/usr/share/syslinux/vesamenu.c32',
                        mode    => $filemode,
                        require => File['/tftpboot/'],
        }
        file { '/tftpboot/pxelinux.cfg':
                        ensure  => 'directory',
                        owner   => $owner,
                        group   => $group,
                        mode    => $foldermode,
                        require => File['/tftpboot/'],
        }
        file { $pxefile:
                        ensure  => 'file',
                        source  => 'puppet:///modules/pxe_server/default',
                        owner   => $owner,
                        group   => $group,
                        mode    => $filemode,
                        require => File['/tftpboot/'],
        }
        file { $iso_mount_path_parent:
                        ensure  => 'present',
                        require => Package['httpd'],
        }
        $isos.each |String $iso| {
          file { ["${iso_mount_path_parent}${iso}/", "${iso_mount_path_parent}${iso}/ISO/"]:
                          ensure  => 'directory',
                          owner   => $owner,
                          group   => $group,
                          mode    => '0755',
                          require => Package['httpd'],
          }
          mount { "${iso_mount_path_parent}${iso}/ISO/":
                          ensure  => 'mounted',
                          fstype  => 'iso9660',
                          atboot  => true,
                          device  => "${iso_library_mount_path}${iso}.iso",
                          options => 'loop',
                          require => [File["${iso_mount_path_parent}${iso}/ISO/"], Mount[$iso_library_mount_path],],
          }
          file { "/tftpboot/${iso}/":
                          ensure  => 'directory',
                          owner   => $owner,
                          group   => $group,
                          mode    => $foldermode,
                          require => File['/tftpboot/'],
          }
          file { "/tftpboot/${iso}/vmlinuz":
                          ensure  => 'file',
                          source  => "${iso_mount_path_parent}${iso}/ISO/images/pxeboot/vmlinuz",
                          mode    => $filemode,
                          require => [File['/tftpboot/'], Mount["${iso_mount_path_parent}${iso}/ISO/"],],
          }
          file { "/tftpboot/${iso}/initrd.img":
                          ensure  => 'file',
                          source  => "${iso_mount_path_parent}${iso}/ISO/images/pxeboot/initrd.img",
                          mode    => $filemode,
                          require => [File['/tftpboot/'], Mount["${iso_mount_path_parent}${iso}/ISO/"],],
          }
        }
        $ks_locations.each |String $ks_location| {
          $ks_names.each |String $ks_name| {
              file { "${iso_mount_path_parent}${ks_location}/${ks_name}.ks":
                          ensure  => 'file',
                          source  => "${kickstart_source}${ks_location}/${ks_name}.ks",
                          owner   => $owner,
                          group   => $group,
                          mode    => $filemode,
                          require => File[$iso_mount_path_parent],
              }
              file_line { "${pxefile}_${ks_location}_${ks_name}_LABEL":
                      ensure  => present,
                      path    => $pxefile,
                      line    => "LABEL Install ${ks_name}",
                      require => [File[$pxefile], File["${iso_mount_path_parent}${ks_location}/${ks_name}.ks"],],
              }
              file_line { "${pxefile}_${ks_location}_${ks_name}_MENULABEL":
                      ensure  => present,
                      path    => $pxefile,
                      line    => "\tMENU LABEL Install ${ks_name}",
                      require => [File[$pxefile], File["${iso_mount_path_parent}${ks_location}/${ks_name}.ks"], file_line["${pxefile}_${ks_location}_${ks_name}_LABEL"],],
              }
              file_line { "${pxefile}_${ks_location}_${ks_name}_KERNEL":
                      ensure  => present,
                      path    => $pxefile,
                      line    => "\tkernel OracleLinux_7_3/vmlinuz",
                      require => [File[$pxefile], File["/tftpboot/${ks_location}/vmlinuz"], file_line["${pxefile}_${ks_location}_${ks_name}_MENULABEL"],],
              }
              file_line { "${pxefile}_${ks_location}_${ks_name}_ENV":
                      ensure  => present,
                      path    => $pxefile,
                      line    => "\tappend ksdevice=eth0 console=tty0 load_ramdisk=1 initrd=${ks_location}/initrd.img inst.ks=http://${web_server_ip}/${ks_location}/${ks_name}.ks inst.repo=http://${web_server_ip}/${ks_location}/ISO/",
                      require => [File[$pxefile], File["${iso_mount_path_parent}${ks_location}/${ks_name}.ks"],File["/tftpboot/${ks_location}/initrd.img"], File["/tftpboot/${ks_location}/initrd.img"], file_line["${pxefile}_${ks_location}_${ks_name}_KERNEL"],],
              }
              file_line { "${pxefile}_${ks_location}_${ks_name}_BLANK":
                      ensure  => present,
                      path    => $pxefile,
                      line    => "\n",
                      require => [File[$pxefile], File["${iso_mount_path_parent}${ks_location}/${ks_name}.ks"], file_line[],],
              }
          }
        }
        # Manage SELinux
        selboolean { 'tftp_anon_write':
                        persistent => true,
                        value      => off,
                        require    => Package['tftp-server'],
        }
        selboolean { 'tftp_home_dir':
                        persistent => true,
                        value      => on,
                        require    => Package['tftp-server'],
        }
        exec { 'se_tftp':
                        command => '/sbin/restorecon -r /tftpboot/',
                        user    => 'root',
                        require => Package['tftp-server'],
        }
        exec { 'se_http':
                        command => '/sbin/restorecon -r /var/www/html/',
                        user    => 'root',
                        require => Package['httpd'],
        }
        # Manage Firewall
        exec { 'fw_allow_tftp':
                        command => '/bin/firewall-cmd --permanent --add-service=tftp',
                        user    => 'root',
        }
        exec { 'fw_allow_dhcp':
                        command => '/bin/firewall-cmd --permanent --add-service=dhcp',
                        user    => 'root',
        }
        exec { 'fw_allow_http':
                        command => '/bin/firewall-cmd --permanent --add-service=http',
                        user    => 'root',
        }
        exec { 'reload_firewall':
                        command => '/bin/firewall-cmd --reload',
                        user    => 'root',
        }
        # Enable and restart services
        exec { 'enable_xinetd':
                        command => '/bin/systemctl enable xinetd',
                        user    => 'root',
                        require => Package['xinetd'],
        }
        exec { 'restart_xinetd':
                        command => '/bin/systemctl restart xinetd',
                        user    => 'root',
                        require => Package['xinetd'],
        }
        exec { 'enable_tftp':
                        command => '/bin/systemctl enable tftp',
                        user    => 'root',
                        require => Package['tftp-server'],
        }
        exec { 'restart_tftp':
                        command => '/bin/systemctl restart tftp',
                        user    => 'root',
                        require => Package['tftp-server'],
        }
        exec { 'enable_dsnmasq':
                        command => '/bin/systemctl enable dnsmasq',
                        user    => 'root',
                        require => Package['dnsmasq'],
        }
        exec { 'restart_dnsmasq':
                        command => '/bin/systemctl restart dnsmasq',
                        user    => 'root',
                        require => Package['dnsmasq'],
        }
        exec { 'enable_httpd':
                        command => '/bin/systemctl enable httpd',
                        user    => 'root',
                        require => Package['httpd'],
        }
        exec { 'restart_httpd':
                        command => '/bin/systemctl restart httpd',
                        user    => 'root',
                        require => Package['httpd'],
        }
}
