    function Send-LogInsightMessage ([string]$message, $TimeStamp)  
    {  
        $uri = "http://loginsight.home.uw.cz:9000/api/v1/events/ingest/1"  
        $content_type = "application/json"  
        $body = '{"events":[{"text":"'+$message+'","timestamp":'+$TimeStamp+'}]}'
        $r = Invoke-RestMethod -Uri $uri -ContentType $content_type -Method Post -Body $body
    }
    
    $runuser = "root"
    $pwd = Get-Content "E:\Scripts\root_pass" | ConvertTo-SecureString -AsPlainText -Force
    $me = New-Object System.Management.Automation.PsCredential $runuser, $pwd
    
    Get-Module -ListAvailable VM* | Import-Module
    set-PowerCLIConfiguration -DefaultVIServerMode Multiple -Scope Session -Confirm:$false | Out-Null
    foreach($ESXName in $args){Connect-VIServer -Server $ESXName -Credential $me -Force -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | Out-Null}
    $Metrics = "cpu.usage.average","cpu.ready.summation","cpu.costop.summation","mem.usage.average","net.usage.average", "*Disk.totalWriteLatency.average","*Disk.totalReadLatency.average","Disk.numberReadAveraged.average","Disk.numberWriteAveraged.average","Disk.Read.average","Disk.Write.average"
    $Events = Get-Stat -Entity * -Stat $Metrics -MaxSamples 15 -IntervalSecs 20 -Realtime -ErrorAction SilentlyContinue
    
    foreach($Event in $Events)
                {
                    if($Event.MetricId -eq "cpu.usage.average" -and ($Event.EntityId -like "VirtualMachine-*" -or $Event.EntityId -like "HostSystem-*") -and $Event.Instance -eq "")
                        {
                            $message = "Metric: VM CPU usage. VM Name:"+($Event.Entity.Name)+", Host name:"+($Event.Entity.vmhost.Name)+", Timestamp:"+($Event.Timestamp)+", value:"+($Event.Value)+" "+($Event.Unit)+", Instance: "+($Event.Instance)
                            $TimeStamp = (Get-Date ($Event.Timestamp)).ToUniversalTime()
                            $TimeStamp = (Get-Date ($TimeStamp) -UFormat %s) -replace("[,\.]\d*","")
                            $TimeStamp = $TimeStamp+"000"
                            Send-LogInsightMessage $message $TimeStamp
                        }
                    elseif($Event.MetricId -eq "mem.usage.average" -and ($Event.EntityId -like "VirtualMachine-*" -or $Event.EntityId -like "HostSystem-*") -and $Event.Instance -eq "")
                        {
                            $message = "Metric: VM MEM usage. VM Name:"+($Event.Entity.Name)+", Host name:"+($Event.Entity.vmhost.Name)+", Timestamp:"+($Event.Timestamp)+", value:"+($Event.Value)+" "+($Event.Unit)+", Instance: "+($Event.Instance)
                            $TimeStamp = (Get-Date ($Event.Timestamp)).ToUniversalTime()
                            $TimeStamp = (Get-Date ($TimeStamp) -UFormat %s) -replace("[,\.]\d*","")
                            $TimeStamp = $TimeStamp+"000"
                            Send-LogInsightMessage $message $TimeStamp
                        }
                    elseif($Event.MetricId -like "*Disk.totalWriteLatency.average" -and ($Event.EntityId -like "VirtualMachine-*" -or $Event.EntityId -like "HostSystem-*"))
                        {
                            $message = "Metric: VM Disk Write latency. VM Name:"+($Event.Entity.Name)+", Host name:"+($Event.Entity.vmhost.Name)+", Timestamp:"+($Event.Timestamp)+", value:"+($Event.Value)+" "+($Event.Unit)+", Instance: "+($Event.Instance)
                            $TimeStamp = (Get-Date ($Event.Timestamp)).ToUniversalTime()
                            $TimeStamp = (Get-Date ($TimeStamp) -UFormat %s) -replace("[,\.]\d*","")
                            $TimeStamp = $TimeStamp+"000"
                            Send-LogInsightMessage $message $TimeStamp
                        }
                    elseif($Event.MetricId -like "*Disk.totalReadLatency.average" -and ($Event.EntityId -like "VirtualMachine-*" -or $Event.EntityId -like "HostSystem-*"))
                        {
                            $message = "Metric: VM Disk Read latency. VM Name:"+($Event.Entity.Name)+", Host name:"+($Event.Entity.vmhost.Name)+", Timestamp:"+($Event.Timestamp)+", value:"+($Event.Value)+" "+($Event.Unit)+", Instance: "+($Event.Instance)
                            $TimeStamp = (Get-Date ($Event.Timestamp)).ToUniversalTime()
                            $TimeStamp = (Get-Date ($TimeStamp) -UFormat %s) -replace("[,\.]\d*","")
                            $TimeStamp = $TimeStamp+"000"
                            Send-LogInsightMessage $message $TimeStamp
                        }
                    elseif($Event.MetricId -eq "Disk.numberWriteAveraged.average" -and ($Event.EntityId -like "VirtualMachine-*" -or $Event.EntityId -like "HostSystem-*"))
                        {
                            $message = "Metric: VM Disk Write IOps. VM Name:"+($Event.Entity.Name)+", Host name:"+($Event.Entity.vmhost.Name)+", Timestamp:"+($Event.Timestamp)+", value:"+($Event.Value)+" "+($Event.Unit)+", Instance: "+($Event.Instance)
                            $TimeStamp = (Get-Date ($Event.Timestamp)).ToUniversalTime()
                            $TimeStamp = (Get-Date ($TimeStamp) -UFormat %s) -replace("[,\.]\d*","")
                            $TimeStamp = $TimeStamp+"000"
                            Send-LogInsightMessage $message $TimeStamp
                        }
                    elseif($Event.MetricId -eq "Disk.numberReadAveraged.average" -and ($Event.EntityId -like "VirtualMachine-*" -or $Event.EntityId -like "HostSystem-*"))
                        {
                            $message = "Metric: VM Disk Read IOps. VM Name:"+($Event.Entity.Name)+", Host name:"+($Event.Entity.vmhost.Name)+", Timestamp:"+($Event.Timestamp)+", value:"+($Event.Value)+" "+($Event.Unit)+", Instance: "+($Event.Instance)
                            $TimeStamp = (Get-Date ($Event.Timestamp)).ToUniversalTime()
                            $TimeStamp = (Get-Date ($TimeStamp) -UFormat %s) -replace("[,\.]\d*","")
                            $TimeStamp = $TimeStamp+"000"
                            Send-LogInsightMessage $message $TimeStamp
                        }
                    elseif($Event.MetricId -eq "Disk.Write.average" -and ($Event.EntityId -like "VirtualMachine-*" -or $Event.EntityId -like "HostSystem-*") -and $Event.Instance -eq "")
                        {
                            $message = "Metric: VM Disk Write (KBps). VM Name:"+($Event.Entity.Name)+", Host name:"+($Event.Entity.vmhost.Name)+", Timestamp:"+($Event.Timestamp)+", value:"+($Event.Value)+" "+($Event.Unit)+", Instance: "+($Event.Instance)
                            $TimeStamp = (Get-Date ($Event.Timestamp)).ToUniversalTime()
                            $TimeStamp = (Get-Date ($TimeStamp) -UFormat %s) -replace("[,\.]\d*","")
                            $TimeStamp = $TimeStamp+"000"
                            Send-LogInsightMessage $message $TimeStamp
                        }
                    elseif($Event.MetricId -eq "Disk.Read.average" -and ($Event.EntityId -like "VirtualMachine-*" -or $Event.EntityId -like "HostSystem-*") -and $Event.Instance -eq "")
                        {
                            $message = "Metric: VM Disk Read (KBps). VM Name:"+($Event.Entity.Name)+", Host name:"+($Event.Entity.vmhost.Name)+", Timestamp:"+($Event.Timestamp)+", value:"+($Event.Value)+" "+($Event.Unit)+", Instance: "+($Event.Instance)
                            $TimeStamp = (Get-Date ($Event.Timestamp)).ToUniversalTime()
                            $TimeStamp = (Get-Date ($TimeStamp) -UFormat %s) -replace("[,\.]\d*","")
                            $TimeStamp = $TimeStamp+"000"
                            Send-LogInsightMessage $message $TimeStamp
                        }
                    elseif($Event.MetricId -eq "net.usage.average" -and ($Event.EntityId -like "VirtualMachine-*" -or $Event.EntityId -like "HostSystem-*") -and $Event.Instance -eq "")
                        {
                            $message = "Metric: VM NET usage. VM Name:"+($Event.Entity.Name)+", Host name:"+($Event.Entity.vmhost.Name)+", Timestamp:"+($Event.Timestamp)+", value:"+($Event.Value)+" "+($Event.Unit)+", Instance: "+($Event.Instance)
                            $TimeStamp = (Get-Date ($Event.Timestamp)).ToUniversalTime()
                            $TimeStamp = (Get-Date ($TimeStamp) -UFormat %s) -replace("[,\.]\d*","")
                            $TimeStamp = $TimeStamp+"000"
                            Send-LogInsightMessage $message $TimeStamp
                        }
                    elseif($Event.MetricId -eq "cpu.ready.summation" -and ($Event.EntityId -like "VirtualMachine-*" -or $Event.EntityId -like "HostSystem-*") -and $Event.Instance -eq "")
                        {
                            $message = "Metric: VM CPU ready. VM Name:"+($Event.Entity.Name)+", Host name:"+($Event.Entity.vmhost.Name)+", Timestamp:"+($Event.Timestamp)+", value:"+($Event.Value)+" "+($Event.Unit)+", Instance: "+($Event.Instance)
                            $TimeStamp = (Get-Date ($Event.Timestamp)).ToUniversalTime()
                            $TimeStamp = (Get-Date ($TimeStamp) -UFormat %s) -replace("[,\.]\d*","")
                            $TimeStamp = $TimeStamp+"000"
                            Send-LogInsightMessage $message $TimeStamp
                        }
                    elseif($Event.MetricId -eq "cpu.costop.summation" -and ($Event.EntityId -like "VirtualMachine-*" -or $Event.EntityId -like "HostSystem-*") -and $Event.Instance -eq "")
                        {
                            $message = "Metric: VM co-stop. VM Name:"+($Event.Entity.Name)+", Host name:"+($Event.Entity.vmhost.Name)+", Timestamp:"+($Event.Timestamp)+", value:"+($Event.Value)+" "+($Event.Unit)+", Instance: "+($Event.Instance)
                            $TimeStamp = (Get-Date ($Event.Timestamp)).ToUniversalTime()
                            $TimeStamp = (Get-Date ($TimeStamp) -UFormat %s) -replace("[,\.]\d*","")
                            $TimeStamp = $TimeStamp+"000"
                            Send-LogInsightMessage $message $TimeStamp
                        }
                }

if($global:DefaultVIServers.count -eq 0){Disconnect-VIServer * -Confirm:$false -Force | Out-Null}
