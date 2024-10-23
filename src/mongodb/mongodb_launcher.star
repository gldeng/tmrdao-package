NAME_ARG = "name"
USER_ARG = "user"
PASSWORD_ARG = "password"
IMAGE_ARG = "image"
ENV_VARS_ARG = "env_vars"

PORT_NAME = "mongodb"
PORT_NUMBER = 27017
PROTOCOL_NAME = "mongodb"

def run(plan, args):
    service_name = args.get(NAME_ARG, "mongodb")
    image = args.get(IMAGE_ARG, "mongo:8.0.1")
    user = args.get(USER_ARG, "")
    password = args.get(PASSWORD_ARG, "")
    env_var_overrides = args.get(ENV_VARS_ARG, {})

    env_vars = {}
    if user:
        env_vars["MONGO_INITDB_ROOT_USERNAME"] = user
        env_vars["MONGO_INITDB_ROOT_PASSWORD"] = password
    env_vars |= env_var_overrides

    # Add the server
    service = plan.add_service(
        name=service_name,
        config=ServiceConfig(
            image=image,
            files = {
                "/data/db": Directory(persistent_key="mongodb-data"),
            },
            ports={
                PORT_NAME: PortSpec(
                    number=PORT_NUMBER,
                    application_protocol=PROTOCOL_NAME
                ),
            },
            env_vars=env_vars,
            entrypoint=["mongod", "--bind_ip_all", "--replSet", "rs0"],
        ),
    )

    # Initialize the replica set
    init_command = [
        "mongosh",
        "--eval",
        "rs.initiate({_id: 'rs0', members: [{_id: 0, host: 'localhost:27017'}]})"
    ]

    if user and password:
        init_command = [
            "mongosh",
            "--authenticationDatabase", "admin",
            "-u", user,
            "-p", password,
            "--eval",
            "rs.initiate({_id: 'rs0', members: [{_id: 0, host: 'localhost:27017'}]})"
        ]

    plan.exec(
        service_name=service_name,
        recipe=ExecRecipe(
            command=init_command
        )
    )

    auth = ""
    if user:
        auth = "{user}:{password}@".format(user=user, password=password)

    url = "{protocol}://{auth}{hostname}:{port}/".format(
        protocol = PROTOCOL_NAME,
        auth = auth,
        hostname = service.hostname,
        port = PORT_NUMBER,
    )

    return struct(
        service=service,
        url=url,
    )
