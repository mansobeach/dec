https://superuser.com/questions/641933/how-to-get-virtualbox-vms-to-use-hosts-dns

https://www.virtualbox.org/manual/ch09.html#nat_host_resolver_proxy

https://notes.enovision.net/linux/changing-dns-with-resolve

`VBoxManage modifyvm "<VM name>" --natdnshostresolver1 on`

`VBoxManage modifyvm "ubuntu64" --natdnshostresolver1 on`

`VBoxManage list runningvms`

