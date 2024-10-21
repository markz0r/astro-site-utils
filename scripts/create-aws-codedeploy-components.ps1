# Set exit on error
$ErrorActionPreference = 'Stop'; $DebugPreference = 'Continue'

{
    param(
        [Parameter(Mandatory = $true)]
        [string]$awsProfile,
        [Parameter(Mandatory = $true)]
        [string]$appName,
        [Parameter(Mandatory = $true)]
        [string]$deploymentGroupName,
        [Parameter(Mandatory = $true)]
        [string]$deploymentConfigName,
        [Parameter(Mandatory = $true)]
        [string]$serviceRoleArn,
        [Parameter(Mandatory = $true)]
        [string]$ec2TagKey,
        [Parameter(Mandatory = $true)]
        [string]$ec2TagValue,
        [Parameter(Mandatory = $true)]
        [string]$s3BucketName,
        [Parameter(Mandatory = $true)]
        [string]$s3Key,
        [Parameter(Mandatory = $true)]
        [string]$s3BundleType
    )   
}

# Test values:
$awsProfile = 'mwc'
$appName = 'mwclearning-prod'
$deploymentGroupName = 'mwclearning-prod-deployment-group'
$deploymentConfigName = 'CodeDeployDefault.OneAtATime'
$serviceRoleArn = 'arn:aws:iam::683431728818:role/mwclearning-CodeDeoploy-service-role'
$ec2TagKey = 'HostType'
$ec2TagValue = 'Front'
$s3BucketName = 'mwc-website-artifacts'
$s3BundleType = 'tgz'
#$s3Key = 'osm-dev-stag-16-d5f6eb6815176285dfb70ffcf631e3e7963aa5e7/osm-dev-stag.tar.gz'



# List applications
$EXISTING_APP_LIST = aws deploy list-applications --profile $awsProfile
$EXISTING_APP_LIST = $EXISTING_APP_LIST | ConvertFrom-Json
Write-Debug "EXISTING_APP_LIST: $EXISTING_APP_LIST"

# Create the application if it does not exist
if ($EXISTING_APP_LIST.applications -notcontains $appName) {
    aws deploy create-application --application-name $appName --profile $awsProfile
}
else {
    Write-Debug "Application $appName already exists"
}

# List deployment groups
$EXISTING_DEP_GROUPS = aws deploy list-deployment-groups --application-name $appName --profile $awsProfile
$EXISTING_DEP_GROUPS = $EXISTING_DEP_GROUPS | ConvertFrom-Json
Write-Debug "EXISTING_DEP_GROUPS: $EXISTING_DEP_GROUPS"

# Create the deployment group if it does not exist -- REQUIRES AdminAccess
if ($EXISTING_DEP_GROUPS.deploymentGroups -notcontains $deploymentGroupName) {
    aws deploy create-deployment-group --application-name $appName --deployment-group-name $deploymentGroupName --deployment-config-name $deploymentConfigName --service-role-arn $serviceRoleArn --ec2-tag-filters "Key=$($ec2TagKey),Value=$($ec2TagValue),Type=KEY_AND_VALUE" --profile $awsProfile
}
else {
    Write-Debug "Deployment group $deploymentGroupName already exists"
}

# Create a new deployment - Can be done by a user with CodeDeployFullAccess
aws deploy create-deployment --application-name $appName --deployment-group-name $deploymentGroupName --s3-location "bucket=$($s3BucketName),key=$($s3Key),bundleType=$($s3BundleType)" --profile $awsProfile
