SHELL := /usr/bin/env bash
.PHONY: doctor keys exosys ueth services cascade health

doctor:
	bash scripts/00_doctor.sh
keys:
	bash scripts/05_generate_wireguard_keys.sh
exosys:
	sudo -E bash scripts/10_exosys_setup_sinkhole.sh
ueth:
	sudo -E bash scripts/20_rhiz_ueth_bastion_setup.sh
services:
	sudo -E bash scripts/30_install_guardian_services.sh
cascade:
	bash scripts/40_cascade_orchestrate.sh
health:
	bash scripts/50_health.sh
