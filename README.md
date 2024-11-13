# TomorrowDAO Package

This is a Kurtosis package for TomorrowDAO backend and other dependency services such as aelf node and aefinder.

## Quickstart


[![Open in Gitpod](https://gitpod.io/button/open-in-gitpod.svg)](https://gitpod.io/new/?editor=code#https://github.com/gldeng/tmrdao-package)

1. [Install Docker & start the Docker Daemon if you haven't done so already][docker-installation]
2. [Install the Kurtosis CLI, or upgrade it to the latest version if it's already installed][kurtosis-cli-installation]
3. Run the package with default configurations from the command line:

   ```bash
   # Find my local IP
   ip=$(ifconfig | awk '/inet / && !/127.0.0.1/ {print $2; exit}')
   # Run the package with my local IP as the advertised IP
   kurtosis run github.com/gldeng/tmrdao-package "{\"advertised_ip\":\"$ip\"}"
   ```

<!------------------------ Only links below here -------------------------------->

[docker-installation]: https://docs.docker.com/get-docker/
[kurtosis-cli-installation]: https://docs.kurtosis.com/install
[kurtosis-repo]: https://github.com/kurtosis-tech/kurtosis
[enclave]: https://docs.kurtosis.com/advanced-concepts/enclaves/
[package-reference]: https://docs.kurtosis.com/advanced-concepts/packages