

def run(plan):

    python_script = read_file("/static_files/scripts/init_kibana.py")
    result = plan.run_python(
        run=python_script,
        image = "python:3.11-alpine",
        packages = [
            "requests"
        ]
    )