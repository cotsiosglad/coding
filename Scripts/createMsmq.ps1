function msmqCreation {
    param (
        [string] $queue_name,
        [string] $queue_type,
        [bool] $isTransactional
    )
    $counter=0
    
        do{
            try {
                $counter++
                $queue = Get-MsmqQueue -Name $queue_name -QueueType $queue_type
                if ($queue)
                {
                    Write-Host "Queue named: $queue_name exists"
                    exit
                }
                else {
                    
                    $queue = New-MsmqQueue -Name $queue_name -QueueType $queue_type -Transactional:$isTransactional
                    if($queue)
                    {
                        return $queue
                    }
                }
            }
            catch {
                Write-Host "Failed to create/receive queue`n Retrying attempt $counter..."
                Start-Sleep 5
            }
        } while ($counter -lt 3 -or $queue) {
            exit
        }
    }


function setAcls {
    param (
        [System.Object] $queue,
        [System.Object] $permissions,
        [string] $queue_name,
        [string] $queue_type
    )
    
    try {
        foreach($perm in $permissions)
        {
            $access = $perm.access
            foreach($user in $perm.users)
            {   
                do{
                    Write-Host "Setting Perm $access for $user"
                    try {
                        if($null -eq $queue){
                            Write-Host "Queue object is empty, retrying"
                            $queue= Get-MsmqQueue -Name $queue_name -QueueType $queue_type
                        }else{
                            $setPerm = Set-MsmqQueueACL -InputObject $queue -UserName $user -Allow $access
                            if($setPerm)
                            {
                                Write-Host "Permissions $access set successfully"
                                break
                            }else {
                                $permCounter++
                                Write-Host "Retrying to set perm: $access"
                                Start-Sleep -Seconds 3
                            }
                        }
                    }
                    catch {
                        Write-Host "Failed to set perms on $user with access $access"
                    }
                }while($permCounter -lt 3 -or $setPerm)
            }
        }
    }
    catch {
        Write-Host $_.Exception.Message
    }
}


$queue_type="private"
$queue_name = "blueeeeeeee"
$isTransactional=$true
$journalingEnabled=$true
$permissions = @(
    @{
        "access" = "Fullcontrol"
        "users" = @("Everyone", "Authenticated Users")
    }
)

if(-not ($null -eq $queue_name) -and -not ($null -eq $queue_type)){

    msmqCreation -queue_name $queue_name -queue_type $queue_type -isTransactional $isTransactional

    $retryCount=0
    do {
        if ($journalingEnabled) {
            Write-Host "Enabling Journal"
            if($queue){
                $jrnlQ = Set-MsmqQueue -InputObject $queue -Journaling:$true
                Start-Sleep -Seconds 5
                if ($jrnlQ.UseJournalQueue -eq $true)
                {
                    break
                } 
            }
            else {
                Write-Host "Retrying..."
                $retryCount++
                $queue = Get-MsmqQueue -Name $queue_name -QueueType $queue_type
            }
        }
    }while($retryCount -lt 3 -or $jrnlQ.UseJournalQueue)

    setAcls -queue $queue -permissions $permissions -queue_name $queue_name -queue_type $queue_type
}else{
    Write-Host "Queue Name or Queue Type is empty"
    exit
}