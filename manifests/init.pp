# Class: svn
#
# This module manages svn
#
class svn {

    package { "subversion": }

    # Definition: svn::checkout
    #
    # checkout/switch an svn repository
    # Note that the owner/group case statements are a hack and need to be refactored
    #
    # Parameters:   
    #   $reposerver - server name of svn repo
    #   $method     - protocol for which you are connecting
    #   $repopath   - path to repository on remote server
    #   $branch     - which branch under $repopath
    #   $workingdir - local directory
    #   $remoteuser - optional remote user, defaults to not being 
    #   $localuser  - user on local system that initiates the svn connection
    #
    # Actions:
    #   checkout/switch an svn repository
    #
    # Requires:
    #   $reposerver
    #   $method
    #   $repopath
    #   $brnach
    #   $workingdir
    #   $localuser
    #
    # Sample Usage:
    #    svn::checkout { "dns $dns_branch":
    #        reposerver => "bindRepoServer",
    #        method     => "http",
    #        repopath   => "dns",
    #        workingdir => "/var/named/chroot/var/named/zones",
    #        branch     => "$dns_branch",
    #        localuser  => "dnsreposvn",
    #        require    => Package["bind-chroot"],
    #        notify     => Service["named"],
    #    } # svn::checkout
    #
	define checkout($reposerver = false, 
			$method = false, 
			$repopath = false, 
			$branch = false, 
			$workingdir = false, 
			$trustcert = false, 
			$revision = "HEAD", 
			$remoteuser = false, 
			$remotepass = false, 
			$localuser 
	) {

        Exec {
            path => "/bin:/usr/bin:/usr/local/bin",
            user        => $localuser,
            environment => $localuser ? {
                puppet      => "HOME=/var/lib/puppet",
                svnupdater  => "HOME=/home/svnupdater",
                },
        } # Exec

	$urlmethod = $method ? {
		false => "",
		default => "$method://"
	}

	$optuser = $remoteuser ? {
		false	=> "",
		default	=> "--username $remoteuser",
	}

	$urlhost = $host ? {
		false	=> "",
		default	=> "$reposerver"
	}

	$optpassword = $remotepass ? {
		false	=> "",
		default	=> "--password $remotepass"
	}

	$opttrustcert = $trustcert ? {
		false	=> "",
		default => "--trust-server-cert --non-interactive"
	}

        $optnoauthcache = $noauthcache ? {
                false => "",
                default => "--no-auth-cache"
        }

	$svnurl = "${urlmethod}${urlhost}${repopath}${branch}"

	$svn_command_checkout = "svn checkout $optnoauthcache $optuser $optpassword $opttrustcert -r$revision $svnurl $workingdir"
	$svn_command_switch = "svn switch $optnoauthcache $optuser $optpassword $opttrustcert -r$revision $svnurl $workingdir"

        file { "$workingdir":
            owner   => $remoteuser ? {
                svnupdater  => "svnupdater",
                false       => "$localuser",
            },
            group   => $remoteuser ? {
                svnupdater  => "svnupdater",
                false       => "$localuser",
            },
            ensure  => directory,
            recurse => true,
        } # file

        exec {
            "initial checkout":
                command => $svn_command_checkout,
                require => File["$workingdir"],
#                before  => Exec["switch"],
                creates => "$workingdir/.svn";
#            "switch":
#                command => $svn_command_switch,
#                require => [File["$workingdir"],Exec["update"]],
#                before  => Exec["revert"];
#            "update":
#                require => File["$workingdir"],
#                command =>  "svn update --non-interactive $workingdir";
#            "revert":
#                command => "svn revert -R $workingdir",
#                onlyif  => "svn status --non-interactive $workingdir | egrep '^M|^! |^? ' ";
        } # exec
    } # define checkout
} # class svn
