ENV?=env/rhiz-adk-lab.env
export ENV_FILE=$(ENV)

doctor:
	bash scripts/00_doctor.sh
profile:
	bash scripts/20_create_lxd_profile.sh
vm:
	bash scripts/30_create_compute_vm.sh
snapshot:
	bash scripts/31_snapshot_compute_vm.sh
bootstrap:
	bash scripts/40_bootstrap_vm_lab.sh
deploy:
	bash scripts/50_deploy_agent_gateway.sh
test:
	bash scripts/60_test_gateway.sh
all: doctor profile vm snapshot bootstrap deploy test
