# Get github user PAT token
$token = "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"

# Define the API endpoint for listing your own repositories
$reposApiUrl = "https://api.github.com/user/repos"
$branchProtectionUrl = "https://api.github.com/repos/$repoFullName/branches/main/protection"
$repoUrl = "https://api.github.com/user/repos"

# Set up headers with authentication
$headers = @{
    Authorization = "token $token"
}
# Scan and print organizations

# Call the GitHub API to list your repositories
$repos = Invoke-RestMethod -Uri $reposApiUrl -Headers $headers

# Define the branch protection rule configuration
$branchProtectionConfig = @{
    required_pull_request_reviews = @{
        require_code_owner_reviews      = $true
        required_approving_review_count = 1
        dismiss_stale_reviews           = $true
    }
    enforce_admins                = $true
    required_status_checks        = @{
        strict   = $false
        contexts = @()
    }
    restrictions                  = @{
        users = @()
        teams = @()
        apps  = @()
    }
    allow_force_pushes            = $false
    allow_deletions               = $false
} | ConvertTo-Json

function UpdateBranchProtectionRule {
    param (
        [string] $repositoryName,
        [string] $branchProtectionUrl
    )

    try {
        # Check if rule exists
        Invoke-RestMethod -Uri $branchProtectionUrl -Headers $headers -Method GET -ContentType "application/vnd.github.luke-cage-preview+json"

        # Update existing rule
        Invoke-RestMethod -Uri $branchProtectionUrl -Headers $headers -Method PUT -ContentType "application/vnd.github.luke-cage-preview+json" -Body $branchProtectionConfig

        Write-Host "Branch protection rule updated for $repositoryName"
    }
    catch {
        
        Write-Host "Failed to update branch protection rule for $repositoryName"
        Write-Host "Error: $_"
    }
}

function Add-PublicGitHubRepo {
    param (
        [string] $repositoryName
    )

    # Create a JSON object with the repository name and make it public
    $repoData = @{
        name           = $repositoryName
        private        = $false
        default_branch = $defaultBranch
        auto_init      = $true
    } | ConvertTo-Json

    try {

        Invoke-RestMethod -Uri $repoUrl -Headers $headers -Method POST -ContentType "application/json" -Body $repoData

        Write-Host "Public repository $repositoryName created successfully."
    }
    catch {
        Write-Host "Failed to create public repository $repositoryName"
        Write-Host "Error: $($_.Exception.Message)"
    }
}

function Add-PrivateGithubRepo {
    param (
        [string] $repositoryName
    )

    # Create a JSON object with the repository name and make it public
    $repoData = @{
        name           = $repositoryName
        private        = $false
        default_branch = $defaultBranch
        auto_init      = $true
    } | ConvertTo-Json

    try {

        Invoke-RestMethod -Uri $repoUrl -Headers $headers -Method POST -ContentType "application/json" -Body $repoData

        Write-Host "Public repository $repositoryName created successfully."
    }
    catch {
        Write-Host "Failed to create public repository $repositoryName"
        Write-Host "Error: $($_.Exception.Message)"
    }
}

function RemoveRepo {
    param (
        [string] $repositoryName
    )

    try {
        # Make a POST request to create the repository with authentication
        $deleteRepoUrl = "https://api.github.com/repos/$repoFullName"

        Invoke-RestMethod -Uri $deleteRepoUrl -Headers $headers -Method DELETE

        Write-Host "Repository $repositoryName created successfully."
    }
    catch {
        Write-Host "Failed to delete repository $repositoryName"
        Write-Host "Verify whether the repository exists or check your PAT token permissions"
        Write-Host "Error: $($_.Exception.Message)"
    }
}

# If branch protection exists , update it. else create it
Write-Host "Welcome to Allenrkiou's senior devops script"
Write-Host "1. Create a new Repository`n2. Update all branch protection rules`n3. Delete Branch"
$options = Read-Host "Please enter your option`n"
switch ($options) {
    1 {
        $repositoryName = Read-Host "Please enter the repository name`n"
        $defaultBranch = "main"
        if ($repositoryName -and $repositoryName -notmatch '\d') {
            $repositoryType = Read-Host "Type of repo :`n1. Public`n2. Private`n"

            if ($repositoryType -eq 1) {
                Add-PublicGitHubRepo -repositoryName $repositoryName

            }
            elseif ($repositoryType -eq 2) {
                Add-PrivateGithubRepo -repositoryName $repositoryName

            }
            else {
                Write-Host "Invalid option. Please choose between 1,2"
            }
        }
        else {
            Write-Host "Repository name cannot be empty and cannot contain numbers"
        }
        

    }
    2 {
        $updateChoice = Read-Host "Do you want to update :`n1) A specific repo?`n2) All`n"
        if ($updateChoice -eq 1) {
            $repositoryName = Read-Host "Repo name to update`n"
            foreach ($repo in $repos) {
                if ($repo.name -eq $repositoryName -and $repo.owner.login -eq "cotsiosglad") {
                    $repoFullName = $repo.full_name
                    UpdateBranchProtectionRule -repositoryName $repositoryName -branchProtectionUrl $branchProtectionUrl
                    Write-Host "Branch protection rule created for $repositoryName"
                }
                Write-Host "Debug:`nRepo: $repositoryName`nBranchProtectionUrl:$branchProtectionUrl"
            }
            
        }
        elseif ($updateChoice -eq 2) {
            foreach ($repo in $repos) {
                UpdateBranchProtectionRule -repositoryName $repo.name -branchProtectionUrl $branchProtectionUrl
            }
        }
    }
    3 {
        foreach ($repo in $repos) {
            $repoFullName = $repo.full_name
            $repoName = $repo.name
            Write-Host "Current Repos : $repoName"
        }

        $repositoryName = Read-Host "Which repository do you want to delete?`n"
        if ($repositoryName) {
            $scaryChoice = Read-Host "This Repository will be permanently removed.`nAre you sure you want to remove $repositoryName ?`nType Yes or No "
            if ($scaryChoice -eq "Yes" -or $scaryChoice -eq "yes" ) {
                $repoFullName = $repositoryName.full_name
                RemoveRepo -repositoryName $repositoryName
            }
            elseif ($scaryChoice -eq "No" -or $scaryChoice -eq "no") {
                Write-Host "Thank god, that was scary"
            }
            else {
                Write-Host "You can only choose between yes or no."
            }
        }

    }
    default {
        Write-Host "Invalid option. Please choose between 1,2,3."
    }
}