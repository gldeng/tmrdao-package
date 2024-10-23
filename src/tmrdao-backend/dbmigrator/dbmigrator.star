
IMAGE_NAME = "gldeng/tomorrowdaoserver.dbmigrator:sha-b15e398"
APPSETTINGS_TEMPLATE_FILE = "/static_files/tmrdao-backend/dbmigrator/appsettings.json.template"

def run_tmrdao_backend_dbmigrator(plan, mongodb_url):

    artifact_name = plan.render_templates(
        config = {
            "appsettings.json": struct(
                template=read_file(APPSETTINGS_TEMPLATE_FILE),
                data={
                    "MongoDbUrl": mongodb_url
                },
            ),
        },
    )
    result = plan.run_sh(
        run = "cp /app/config/appsettings.json /app/appsettings.json && dotnet /app/TomorrowDAOServer.DbMigrator.dll",
        name = "tmrdao-backend-dbmigrator",
        image = IMAGE_NAME,
        files={
            "/app/config": artifact_name,
        },
        description = "Initialize mongodb"  
    )

    plan.print(result.code)  # returns the future reference to the code
    plan.print(result.output) # returns the future reference to the output