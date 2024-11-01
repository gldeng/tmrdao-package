IMAGE_NAME = "gldeng/tomorrowdao-contracts:sha-3d8d2d7"
CONFIG_FILE = "/static_files/scripts/config.Development.yaml"

def run(plan, aelf_node_url):

    artifact_name = plan.upload_files(src=CONFIG_FILE)
    result = plan.run_sh(
        run = "cp /app/config/config.Development.yaml /app/config.Development.yaml && dotnet /app/TomorrowDAO.Cli.dll",
        name = "tomorrowdao-cli",
        image = IMAGE_NAME,

        env_vars = {
            "AELF_RPC_URL": aelf_node_url,
            "DEPLOYER_PRIVATE_KEY": "1111111111111111111111111111111111111111111111111111111111111111"
        },
        files={
            "/app/config": artifact_name,
        },
        wait="10m",
        description = "Initialize tomorrowdao-cli"  
    )

    plan.print(result.code)  # returns the future reference to the code
    plan.print(result.output) # returns the future reference to the output
