# service start
alias decStart="podman run --userns keep-id --env 'USER' --add-host=nl2-s-aut-srv-01:172.23.253.16 --network=host --tz=Europe/London --name dec -d --mount type=bind,source=/data,destination=/data localhost/dec_naos-test_gsc4eo_nl2-u-moc-srv-01:latest"
# commands
alias decCheckConfig='podman exec dec decCheckConfig'
alias decConfigInterface2DB='podman exec dec decConfigInterface2DB'
alias decDeliverFiles='podman exec dec decDeliverFiles'
alias decGetFromInterface='podman exec dec decGetFromInterface'
alias decListDirUpload='podman exec dec decListDirUpload'
alias decListener='podman exec dec decListener'
alias decManageDB='podman exec dec decManageDB'
alias decNATS='podman exec dec decNATS'
alias decSend2Interface='podman exec dec decSend2Interface'
alias decStats='podman exec dec decStats'
alias decValidateConfig='podman exec dec decValidateConfig'
# tests
alias decTestInterface_NAOS_IVV-0500='podman exec -i dec decTestInterface_NAOS_IVV-0500'
alias decTestInterface_CelesTrak='podman exec -i dec decTestInterface_CelesTrak'
alias decTestInterface_NASA='podman exec -i dec decTestInterface_NASA'
