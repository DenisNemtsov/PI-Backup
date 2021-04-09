<#___________________________________________________________________________
 Developed by _______________________________________________________________|
     ________              ________   _________    _______   __  _________
     \____   \_______      \____   \ |__\   _  \   \      \ |__|/   _____/
      |    |  \_  __ \      |    |  \|  /  /_\  \  /   |   \|  |\_____  \
      |    |   \  | \/      |    |   \  \  \_/   \/    |    \  |/        \
      /_______  /__|   /\  /_______  /__|\_____  /\____|__  /__/_______  /
              \/       \/          \/          \/         \/           \/
 _______________________                           ____________ � 1990 - 2020
|_______________________| Mons�rum est in nostrum |__________________________|

������� ���������:
	* - ��������� �����������
	+ - ���������� �����������
	- - ���������� �����������

25.08.2020(v1.0) * - ������ ����������, ������ ��������� ������.
27.08.2020(v1.0) * - ��������� ���� ��� ������ � ����� Powershell v2.0.
07.09.2020(v1.0) * - ����������� ��������� ���������.
                 + - ���������� ������������ � ��������� ��������.
#>

<# �������� �����������

    ������ ��� ������� ����������� ��������� ���������� ����������� ������ PI Server.
��������� ��������� �������������� ��� ������ ���������� ���������� � ������ ��������
� ���������� ���������� �������������. ����������� ������� ������������� � ���� 
'�������� �������'.log (PIBackup.log) ������������� � ����� �������, ��� ����������
������� ��������� ���������� $LogSize ���������� �������������� ��������������
����� ������� � '�������� �������'.old (PIBackup.old), ���� �������� � ������������
����������, ��� ���������� ��������� ����������� � ���������.

                       				������� ������,
                         					� ���������� �����������,
                            					������ ���, Dr.Di0NiS (c) 2020 #>

$Deep = 7                                                                                          # ������� �������� ������ � ���� (������: 5 - ������ ������ ���� ���� �� ������� ����, ����� �������)
$Path = 'D:\BKP\'                                                                                  # ���� ��� �������� ������ ������
$Format = 'yyyy.MM.dd'                                                                             # ������ ���� � ����� ������
$LogSize = 10                                                                                      # ������������ ������ ����� ������� � ����������

<#
.SYNOPSIS
	����� ������� �������, ��������� ���������������� ������
	���� ��������� ��������.
#>
function Main()
{
    $starttime = Get-Date
    Write-Log('��������������������������������������������������������������������������������')
    Write-Log('���                       ������ ������� PI Backup v1.0                      ���')
    Write-Log('��������������������������������������������������������������������������������')
    Backup
    Cleanup
    Write-Log('����� ���������� �������: ' + (New-TimeSpan -Start $starttime -End (Get-Date)).Milliseconds.ToString() + ' �����������')
}

<#
.SYNOPSIS
	�������� ��������� ������ ����������� ������ ������������
	���������� ����� pibackup.cmd.
#>
function Backup()
{
    Write-Log('������ ��������� ���������� ����������� ������ PI Server...')
	
	$Type = (Get-Date -UFormat %u)
	$Name = $Path + (Get-Date).ToString($Format).Trim()
    
	Switch ($Type)
    {
        {$PSItem -lt 7} {Write-Log('������ ��� ��������� �����: ���������� (Daily)...')
            try
            {
                Write-Log('����� ��������� �����: ' + $Name + '_Daily')
				& 'C:\Program Files\PI\adm\pibackup.bat' $Name'_Daily' '1'
                Write-Log('��������� ����� ������ PI Server ������� �������...')
            }
            catch
            {
                Write-Log('��������! ������ �������� ��������� ����� ������ PI Server!')
            }
        }
        {$PSItem -eq 7} {Write-Log('������ ��� ��������� �����: ������������ (Weekly)...')
            try
            {
                Write-Log('����� ��������� �����: ' + $Name + '_Weekly')
				& 'C:\Program Files\PI\adm\pibackup.bat' $Name'_Weekly' '7'
                Write-Log('��������� ����� ������ PI Server ������� �������...')
            }
            catch
            {
                Write-Log('��������! ������ �������� ��������� ����� ������ PI Server!')
            }
        }
    }
}

<#
.SYNOPSIS
	�������� ������ ��������� ����� ���� �������� �������, 
	��������� ������� (���������� ����) �������� ���������� $Deep.
#>
function Cleanup()
{
    Write-Log('������ ��������� �������� ���������� ������ ��������� �����...')
	
	$Folders = Get-ChildItem -Path $Path | ?{$_.PSIsContainer}
    foreach ($Folder in $Folders)
    {
        if ($Folder.CreationTime -le (Get-Date).AddDays(-1 * $Deep))
        {
            Write-Log('�������� �����: ' + $Folder.FullName)
            Remove-Item -Path $Folder.FullName -Recurse -Force
        }
    }
}

<#
.SYNOPSIS
	����� ��������� � ���� ������. �������� ������� ����� �������, ��������������
	� �������� ������ ����� � ������ ����������.
#>
function Write-Log($Message)
{
    $basefile = ([System.IO.Path]::GetFileNameWithoutExtension($MyInvocation.ScriptName))
	$logfile = $basefile + '.log'
	$oldfile = $basefile + '.old'
    $timestamp = (Get-Date).ToString('dd.MM.yyyy HH:mm')
    $string = $timestamp + ' ' + $Message
	if (!(Test-Path -Path $logfile))
	{
		New-Item -Path . -Name $logfile -ItemType 'file'
	}
	if ((((Get-Item $logfile).Length) / 1MB) -ge $LogSize)
    {
        if (Test-Path -Path $oldfile)
        {
            Remove-Item -Path $oldfile
        }
        Rename-Item -Path $logfile -NewName $oldfile
    }
    Add-Content $logfile -Value $string
}

Main