# Implement your module commands in this script.
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"


function Get-GitlabGroups {
    [CmdletBinding()]
    <#
    .SYNOPSIS
        Returns Gitlab Groups
    .DESCRIPTION
        Returns All Gitlab groups that token has permission.
    .EXAMPLE
        PS C:\> Get-GitlabGroups
        id                                : 2
        web_url                           : http://localhost/groups/Devops
        name                              : Devops
        path                              : Devops
        description                       :
        visibility                        : private
        share_with_group_lock             : False
        require_two_factor_authentication : False
        two_factor_grace_period           : 48
        project_creation_level            : developer
        auto_devops_enabled               :
        subgroup_creation_level           : maintainer
        emails_disabled                   :
        mentions_disabled                 :
        lfs_enabled                       : True
        avatar_url                        :
        request_access_enabled            : True
        full_name                         : Devops
        full_path                         : Devops
        parent_id                         :
    .INPUTS
        N/A
    .OUTPUTS
        N/A
    .NOTES
        General notes
    #>
    param (
    )

    begin {
        $reqID = Get-Random -Minimum 1 -Maximum 999999999
        $headers = @{ Authorization = "Bearer $($global:GitlabToken)" }
    }
    process {
        try {

            $result = $null
            $page = 1
            do {
                Write-Verbose -Message "$(get-date -Format 'yyyyMMddHHmmss') - $($PSCmdlet.MyInvocation.MyCommand.Name) - ReqID:$reqID -> Set Env vars: $(Get-Variable -Scope Global | Where-Object{$_.Name -match "Gitlab"} | Out-String)" -Verbose
                $url = [Uri]::new([Uri]::new($global:GitlabApi), "groups?page=$page").ToString()
                Write-Verbose -Message "$(get-date -Format 'yyyyMMddHHmmss') - $($PSCmdlet.MyInvocation.MyCommand.Name) - ReqID:$reqID -> Created url:$url"
                Write-Verbose -Message "$(get-date -Format 'yyyyMMddHHmmss') - $($PSCmdlet.MyInvocation.MyCommand.Name) - ReqID:$reqID -> Created header:$($headers | out-string)"
                $response = Invoke-WebRequest -Uri $url -Headers $headers -SkipCertificateCheck
                $result += $response.Content | ConvertFrom-Json
                $page ++
            } while ($page -le $response.Headers."X-Total-Pages"[0]) #X-Total-Pages returns number of page size in an array list.
            Write-Verbose -Message "$(get-date -Format 'yyyyMMddHHmmss') - $($PSCmdlet.MyInvocation.MyCommand.Name) - ReqID:$reqID -> Returns result:$result"
            return $result
        }
        catch {
            throw $PSItem
        }
    }
    end {
    }
}

function New-GitlabGroup {
    [CmdletBinding()]
    <#
    .SYNOPSIS
        Creates Gitlab Group
    .DESCRIPTION
        Creates New Group or Subgroup in Gitlab
    .EXAMPLE
        PS C:\> New-GitlabGroup -name "myGroup" -connection @{uri="http://localhost/api/v4/";token="qweasd123asd"}
        Creates new group
    .EXAMPLE
        PS C:\> New-GitlabGroup -name "myGroup" -connection @{uri="http://localhost/api/v4/";token="qweasd123asd"} -parentID 2
        Creates new subgroup in groupID 2
    .INPUTS
        N/A
    .OUTPUTS
        N/A
    .NOTES
        General notes
    .PARAMETER name
        Name of the gitlab group
    .PARAMETER parentID
        Parent ID of the subgroup
    #>
    param (
        # ParentID of subgroup
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [int32]
        $parentID,
        # Group name
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [String]
        $name
    )
    begin {
        $reqID = Get-Random -Minimum 1 -Maximum 999999999
        $headers = @{ Authorization = "Bearer $($global:GitlabToken)" }
    }
    process {
        try {
            [String]::IsNullOrWhiteSpace($parentID) ? $($query = "groups?name=$name&path=$name") : $($query = "groups?name=$name&path=$name&parent_id=$parentID")
            $url = [Uri]::new([Uri]::new($global:GitlabApi), $query ).ToString()
            Write-Verbose -Message "$(get-date -Format 'yyyyMMddHHmmss') - $($PSCmdlet.MyInvocation.MyCommand.Name) - ReqID:$reqID -> Created url:$url"
            $result = Invoke-RestMethod -Uri $url -Headers $headers -Method Post -SkipCertificateCheck
            Write-Verbose -Message "$(get-date -Format 'yyyyMMddHHmmss') - $($PSCmdlet.MyInvocation.MyCommand.Name) - ReqID:$reqID -> Returns result:$result"
            return $result
        }
        catch {
            throw $PSItem
        }
    }
    end {
    }
}

function New-GitlabProject {
    [CmdletBinding()]
        <#
    .SYNOPSIS
        Creates Gitlab Project
    .DESCRIPTION
        Creates New Project for given group id
    .EXAMPLE
        PS C:\> New-GitlabProject -name "myPrj" -groupID 2
        Creates new project "myPrj" in groupID 2
    .INPUTS
        N/A
    .OUTPUTS
        N/A
    .NOTES
        General notes
    .PARAMETER name
        Name of the gitlab project
    .PARAMETER parentID
        Parent ID of the project
    #>
    param (
        # ID of group
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        $groupID,
        # Project name
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [String]
        $name
    )

    begin {
        $reqID = Get-Random -Minimum 1 -Maximum 999999999
        $headers = @{ Authorization = "Bearer $($global:GitlabToken)" }
    }

    process {
        try {

            $url = [Uri]::new([Uri]::new($global:GitlabApi), "projects" ).ToString()
            $body = @{
                name = $name
                namespace_id = $groupID
            }
            Write-Verbose -Message "$(get-date -Format 'yyyyMMddHHmmss') - $($PSCmdlet.MyInvocation.MyCommand.Name) - ReqID:$reqID -> Created url:$url"
            Write-Verbose -Message "$(get-date -Format 'yyyyMMddHHmmss') - $($PSCmdlet.MyInvocation.MyCommand.Name) - ReqID:$reqID -> Created body:$($body|out-string)"
            $result = Invoke-RestMethod -Uri $url -Headers $headers -Body $body -Method Post -SkipCertificateCheck
            Write-Verbose -Message "$(get-date -Format 'yyyyMMddHHmmss') - $($PSCmdlet.MyInvocation.MyCommand.Name) - ReqID:$reqID -> Returns result:$result"
            return $result
        }
        catch {
            throw $PSItem
        }


    }

    end {

    }
}

function Set-GitlabParams {

    [CmdletBinding()]
    <#
    .SYNOPSIS
        Sets gitlab connection parameters
    .DESCRIPTION
        Set connection parameters api url and token for gitlab api connection
    .EXAMPLE
        PS C:\> Set-GitlabParams -apiUrl "http://localhost/api/v4/" -apiToken "tmZemx_kdmcyBaeWMxXa"
    .INPUTS
        N/A
    .OUTPUTS
        N/A
    .PARAMETER apiUrl
        Url for Gitlab API
    .PARAMETER apiToken
        Personal Access Token required for API authentication.
    .NOTES
        This function should be called if there is no environment variable provided for Gitlab uri and token
    #>
    param (
        # URL for Gitlab api
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
            [System.Uri]::IsWellFormedUriString($_,[System.UriKind]::Absolute) ? $true : $(Throw "URL is invalid: $($_)")
        })]
        $apiUrl,
        # Token for Gitlab API
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
            [String]::IsNullOrWhiteSpace($_) ? $(Throw "Token cannot be empty") : $true
        })]
        $apiToken
    )
    begin {
        $reqID = Get-Random -Minimum 1 -Maximum 999999999
    }
    process {
        $global:GitlabApi = $apiUrl
        $global:GitlabToken = $apiToken

        Write-Verbose -Message "$(get-date -Format 'yyyyMMddHHmmss') - $($PSCmdlet.MyInvocation.MyCommand.Name) - ReqID:$reqID -> Set Env vars: $(Get-Variable -Scope Global | Where-Object{$_.Name -match "Gitlab"} | Out-String)"

    }
    end {
    }
}


# Export only the functions using PowerShell standard verb-noun naming.
# Be sure to list each exported functions in the FunctionsToExport field of the module manifest file.
# This improves performance of command discovery in PowerShell.
Export-ModuleMember -Function *-*