#== Class: pxe_server
#
class pxe_server (


        $isos = ['OracleLinux_7_3'],
        $ks_names = ['OL73_db001srv', 'OL73_db002srv', 'OL73_loadb001srv', 'OL73_loadb002srv', 'OL73_queue001srv', 'OL73_queue002srv', 'OL73_stor001srv', 'OL73_stor002srv', 'OL73_web001srv', 'OL73_web002srv'],
        $ks_location_OL73 = 'OracleLinux_7_3/',

        $packages = [ 'xinetd', 'tftp-server', 'dnsmasq', 'httpd', 'pykickstart', 'nfs-utils', 'syslinux' ],

        $iso_library_location = "iso001srv.mydomain.tld:/iso",
        $iso_library_mount_path = "/mnt/",

        $iso_mount_path_parent = "/var/www/html/",

        $owner = "root",
        $group = "root",
        $filemode = "0444",
        $foldermode = "0555",

        # TODO : Modify this to support multiple boot media #
        $pxefile = "/tftpboot/pxelinux.cfg/default",
        # TODO : Modify this to support multiple boot media #

        $kickstart_source = "puppet:///modules/pxe_server/",
) {
#               notify{"isos are: ${isos}": }
#               notify{"ks_names are: ${ks_names}": }
#               notify{"ks_location_OL73 is: ${ks_location_OL73}": }
#               notify{"packages are: ${packages}": }
#               notify{"iso_library_location is: ${iso_library_location}": }
#               notify{"iso_library_mount_path is: ${iso_library_mount_path}": }
#               notify{"iso_mount_path_parent is: ${iso_mount_path_parent}": }
#               notify{"pxefile is: ${pxefile}": }
#               notify{"kickstart_source is: ${kickstart_source}": }
        # Install all necessary packages
        package { $packages: ensure => 'installed' }
        # Configuration for tftp-server daemon
        file_line { "tftp_on":
                ensure => present,
                path => "/etc/xinetd.d/tftp",
                line => "\tdisable\t\t\t= no",
                match => "\\tdisable\\t\\t\\t= ",
        }
        file_line { "tftp_server_args":
                ensure => present,
                path => "/etc/xinetd.d/tftp",
                line => "\tserver_args\t\t= -s /tftpboot",
                match => "\\tserver_args\\t\\t= ",
        }
        # Configuration for tftp-server service
        file_line { "tftp_service_cwd":
                ensure => present,
                path => "/usr/lib/systemd/system/tftp.service",
                line => "ExecStart=/usr/sbin/in.tftpd -s /tftpboot",
                match => "^ExecStart=/usr/sbin/in.tftpd",
                after => '\[Service\]',
        }
        file_line { "tftp_service_wanted":
                ensure => present,
                path => "/usr/lib/systemd/system/tftp.service",
                line => "WantedBy=multi-user.target",
                match => "^WantedBy=",
                after => '\[Install\]',
        }
        # Configuration for dnsmasq
        file_line { "dnsmasq_domain":
                ensure => present,
                path => "/etc/dnsmasq.conf",
                line => "domain=mydomain.tld",
                match => "^domain=",
        }
        file_line { "dnsmasq_dhcp_range":
                ensure => present,
                path => "/etc/dnsmasq.conf",
                line => "dhcp-range=10.0.0.240,10.0.0.249,1h",
                match => "^dhcp-range=",
        }
        file_line { "dnsmasq_dhcp_boot":
                ensure => present,
                path => "/etc/dnsmasq.conf",
                line => "dhcp-boot=pxelinux.0,pxe001srv,10.0.0.250",
                match => "^dhcp-boot=",
        }
        # Mount ISO share, create mount paths for ISO(s) and mount ISO(s), create tftp folders and files
        mount { "$iso_library_mount_path":
                        ensure   => 'mounted',
                        fstype   => 'nfs',
                        atboot   => true,
                        device   => $iso_library_location,
                        require => Package['nfs-utils'],
        }
        file { '/tftpboot/':
                        ensure => 'directory',
                        owner => $owner,
                        group => $group,
                        mode => $foldermode,
        }
        $isos.each |String $iso| {
          file { ["${iso_mount_path_parent}${iso}/", "${iso_mount_path_parent}${iso}/ISO/"]:
                          ensure => 'directory',
                          owner => $owner,
                          group => $group,
                          mode => '0755',
                          require => Package['httpd'],
          }
          mount { "${iso_mount_path_parent}${iso}/ISO/":
                          ensure   => 'mounted',
                          fstype   => 'iso9660',
                          atboot   => true,
                          device   => "${iso_library_mount_path}${iso}.iso",
                          options  => 'loop',
                          require => [File["${iso_mount_path_parent}${iso}/ISO/"], Mount["$iso_library_mount_path"],],
          }
          file { "/tftpboot/${iso}/":
                          ensure => 'directory',
                          owner => $owner,
                          group => $group,
                          mode => $foldermode,
                          require => File['/tftpboot/'],
          }
          file { "/tftpboot/${iso}/vmlinuz":
                          ensure => 'file',
                          source => "${iso_mount_path_parent}${iso}/ISO/images/pxeboot/vmlinuz",
                          mode => $filemode,
                          require => [File['/tftpboot/'], Mount["${iso_mount_path_parent}${iso}/ISO/"],],
          }
          file { "/tftpboot/${iso}/initrd.img":
                          ensure => 'file',
                          source => "${iso_mount_path_parent}${iso}/ISO/images/pxeboot/initrd.img",
                          mode => $filemode,
                          require => [File['/tftpboot/'], Mount["${iso_mount_path_parent}${iso}/ISO/"],],
          }
        }
        file { '/tftpboot/pxelinux.0':
                        ensure => 'file',
                        source => '/usr/share/syslinux/pxelinux.0',
                        mode => $filemode,
                        require => File['/tftpboot/'],
        }
        file { '/tftpboot/vesamenu.c32':
                        ensure => 'file',
                        source => '/usr/share/syslinux/vesamenu.c32',
                        mode => $filemode,
                        require => File['/tftpboot/'],
        }
        file { '/tftpboot/pxelinux.cfg':
                        ensure => 'directory',
                        owner => $owner,
                        group => $group,
                        mode => $foldermode,
                        require => File['/tftpboot/'],
        }
        file { "$pxefile":
                        ensure => 'file',
                        source => 'puppet:///modules/pxe_server/default',
                        owner => $owner,
                        group => $group,
                        mode => $filemode,
                        require => File['/tftpboot/'],
        }
        file { "$iso_mount_path_parent":
                        ensure => 'present',
                        require => Package['httpd'],
        }
        # Create KS file
        $ks_names.each |String $ks_name| {
          file { "${iso_mount_path_parent}${ks_location_OL73}${ks_name}.ks":
                          ensure => 'file',
                          source => "${kickstart_source}${ks_location_OL73}${ks_name}.ks",
                          owner => $owner,
                          group => $group,
                          mode => $filemode,
                          require => File["$iso_mount_path_parent"],
          }
        }
        # Manage SELinux
        selboolean { 'tftp_anon_write':
                        persistent => true,
                        value      => off,
                        require => Package['tftp-server'],
        }
        selboolean { 'tftp_home_dir':
                        persistent => true,
                        value      => on,
                        require => Package['tftp-server'],
        }
        exec { 'se_tftp':
                        command => "/sbin/restorecon -r /tftpboot/",
                        user    => 'root',
                        require => Package['tftp-server'],
        }
        exec { 'se_http':
                        command => "/sbin/restorecon -r /var/www/html/",
                        user    => 'root',
                        require => Package['httpd'],
        }
        # Manage Firewall
        exec { 'fw_allow_tftp':
                        command => "/bin/firewall-cmd --permanent --add-service=tftp",
                        user    => 'root',
        }
        exec { 'fw_allow_dhcp':
                        command => "/bin/firewall-cmd --permanent --add-service=dhcp",
                        user    => 'root',
        }
        exec { 'fw_allow_http':
                        command => "/bin/firewall-cmd --permanent --add-service=http",
                        user    => 'root',
        }
        exec { 'reload_firewall':
                        command => "/bin/firewall-cmd --reload",
                        user    => 'root',
        }
        # Enable and restart services
        exec { 'enable_xinetd':
                        command => "/bin/systemctl enable xinetd",
                        user    => 'root',
                        require => Package['xinetd'],
        }
        exec { 'restart_xinetd':
                        command => "/bin/systemctl restart xinetd",
                        user    => 'root',
                        require => Package['xinetd'],
        }
        exec { 'enable_tftp':
                        command => "/bin/systemctl enable tftp",
                        user    => 'root',
                        require => Package['tftp-server'],
        }
        exec { 'restart_tftp':
                        command => "/bin/systemctl restart tftp",
                        user    => 'root',
                        require => Package['tftp-server'],
        }
        exec { 'enable_dsnmasq':
                        command => "/bin/systemctl enable dnsmasq",
                        user    => 'root',
                        require => Package['dnsmasq'],
        }
        exec { 'restart_dnsmasq':
                        command => "/bin/systemctl restart dnsmasq",
                        user    => 'root',
                        require => Package['dnsmasq'],
        }
        exec { 'enable_httpd':
                        command => "/bin/systemctl enable httpd",
                        user    => 'root',
                        require => Package['httpd'],
        }
        exec { 'restart_httpd':
                        command => "/bin/systemctl restart httpd",
                        user    => 'root',
                        require => Package['httpd'],
        }
}
