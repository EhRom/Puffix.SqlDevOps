# Deploy SSIS packages and configuration

The scripts in this folder are designed to deploy SSIS packages, and their environment to a SQL Server Integration Service instance. It can be associated with [Sql Agent Jobs deployment](../SqlAgentJobs/README.md) for full automation of the deployment.

## Script files

The following file tree is expected on the deployment machine in order to be able to run the scripts:

```text
| - <root>
|  | - Scripts
|  |  | - SsisPackageAndEnvironment.ps1
|  |  | - deploy-ssis.ps1
|  |  | - undeploy-ssis.ps1
|  |  | - DecryptOpsCredentials.ps1
|  |  | - DecryptOpsCredentials.ps1 (option)
|  |  | - UseOpsCredentials.ps1 (option)
|  | - <env 1>
|  |  | - settings-<env 1>.txt
|  |  | - ssisenvironment-<env 1>.json
|  |  | - credentials-<env 1>.enc (option)
|  | - <env 2>
|  |  | - settings-<env 2>.txt
|  |  | - ssisenvironment-<env 2>.json
|  |  | - credentials-<env 2>.enc (option)
```

## SsisPackageAndEnvironment.ps1

The `SsisPackageAndEnvironment.ps1` script is the core library and objects for deploying SSIS packages (`.ispac` files) and the SSIS environments linked to the packages.

## deploy-ssis.ps1

The `deploy-ssis.ps1` is used to deploy the SSIS packages and the SSIS environements. The SSIS environments contains the configuration of the SSIS packages, especially the secret to connect to the data sournces. The `deploy-ssis.ps1` script contains three sections:

1. Load the parameters from the `ssisenvironment-<env>.txt` file,
1. Load the secrets from the `credentials-<env>.enc` file (option),

  > Alternatives to the encrypted file will soon be available cf. [credentials-\<env\>.enc, DecryptOpsCredentials.ps1 & UseOpsCredentials.ps1](#credentials-envenc-decryptopscredentialsps1--useopscredentialsps1) paragraph.

1. Deploy the SSIS packages and environments using the `.ispac` file specified in the `ssisenvironment-<env>.txt` file, the `CredentialManager` object and the `ssisenvironment-<env>.json` for the difinition of the environments and the link to the SSIS packages.

As all the configuration to deploy the artefacts is specified in settings files dedicated to environments, the only command to execute is:

```powershell
.\deploy-ssis.ps1 '<env>'
```

With `<env>` as the name of the environment to deploy.

## undeploy-ssis.ps1

The `undeploy-ssis.ps1` is used to undeploy the SSIS packages and the SSIS environements. The script contains two sections:

1. Load the parameters from the `ssisenvironment-<env>.txt` file,
1. Undeploy the SSIS packages and environments using the `.ispac` file specified in the `ssisenvironment-<env>.txt` file and the `ssisenvironment-<env>.json` for the difinition of the environments and the link to the SSIS packages.

As all the configuration to deploy the artefacts is specified in settings files dedicated to environments, the only command to execute is:

```powershell
.\undeploy-ssis.ps1 '<env>'
```

With `<env>` as the name of the environment to deploy.

## settings-\<env\>.txt

*More to come soon.*

## credentials-\<env\>.enc, DecryptOpsCredentials.ps1 & UseOpsCredentials.ps1

The `credentials-<env>.enc` is an encryped file which contains encrypted credentials (two level of encryption).

The file is decrypted with the `DecryptOpsCredentials.ps1` script, and loaded in a `CredentialManager` object (cf. [OpsCredentials](../Secrets/OpsCredentials.md) for more information)

The `CredentialManager` object is used by the `SsisPackageAndEnvironment.ps1` script to define the secrets required by SSIS environments and packages. This is a solution for storing passwords securely (double encryption) in a Git repository, even though storing, even encrypted secrets, in a Git repository should be avoided.

The documentation to create and maintain the `credentials-<env>.enc` file is available in the [GenerateCredentialsAndSecret manual](../Secrets/GenerateCredentialsAndSecret.md).

> Alternatives with secret storage in an Azure Key Vault or an Azure DevOps library will soon be available.

## ssisenvironment-\<env\>.json

*More to come soon.*

---

[Back to Deploy section](https://github.com/EhRom/Puffix.SqlDevOps/tree/master/Deploy)

[Back to root](https://github.com/EhRom/Puffix.SqlDevOps)