<#___________________________________________________________________________
 Developed by _______________________________________________________________|
     ________              ________   _________    _______   __  _________
     \____   \_______      \____   \ |__\   _  \   \      \ |__|/   _____/
      |    |  \_  __ \      |    |  \|  /  /_\  \  /   |   \|  |\_____  \
      |    |   \  | \/      |    |   \  \  \_/   \/    |    \  |/        \
      /_______  /__|   /\  /_______  /__|\_____  /\____|__  /__/_______  /
              \/       \/          \/          \/         \/           \/
 _______________________                           ____________ © 1990 - 2020
|_______________________| Mons†rum est in nostrum |__________________________|

История изменений:
	* - Изменение функционала
	+ - Расширение функционала
	- - Сокращение функционала

25.08.2020(v1.0) * - Начало разработки, первая публичная версия.
27.08.2020(v1.0) * - Адаптация кода для работы в среде Powershell v2.0.
07.09.2020(v1.0) * - Исправление небольших недочетов.
                 + - Добавление комментариев с описанием процедур.
#>

<# ОПИСАНИЕ ФУНКЦИОНАЛА

    Скрипт для запуска стандартной процедуры резервного копирования данных PI Server.
Настройка программы осуществляется при помощи переменных вынесенных в начало листинга
и снабженных подробными коменнтариями. Логирование событий производиться в файл 
'Название скрипта'.log (PIBackup.log) расположенный в папке скрипта, при достижении
размера заданного переменной $LogSize происходит автоматическое переименование
файла журнала в 'Название скрипта'.old (PIBackup.old), файл хранится в единственном
экземпляре, все предыдущие считаются устаревшими и удаляются.

                       				Удачной работы,
                         					с наилучшими пожеланиями,
                            					всегда Ваш, Dr.Di0NiS (c) 2020 #>

$Deep = 7                                                                                          # Глубина хранения архива в днях (Пример: 5 - архивы старше пяти дней от текущей даты, будут удалены)
$Path = 'D:\BKP\'                                                                                  # Путь для хранения файлов бэкапа
$Format = 'yyyy.MM.dd'                                                                             # Формат даты в имени архива
$LogSize = 10                                                                                      # Максимальный размер файла журнала в мегабайтах

<#
.SYNOPSIS
	Точка запуска скрипта, выполняет последовательный запуск
	всех остальных процедур.
#>
function Main()
{
    $starttime = Get-Date
    Write-Log('§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§')
    Write-Log('§§§                       Запуск скрипта PI Backup v1.0                      §§§')
    Write-Log('§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§')
    Backup
    Cleanup
    Write-Log('Время выполнения скрипта: ' + (New-TimeSpan -Start $starttime -End (Get-Date)).Milliseconds.ToString() + ' миллисекунд')
}

<#
.SYNOPSIS
	Создание резервной копиии посредством вызова стандартного
	командного файла pibackup.cmd.
#>
function Backup()
{
    Write-Log('Запуск процедуры резервного копирования данных PI Server...')
	
	$Type = (Get-Date -UFormat %u)
	$Name = $Path + (Get-Date).ToString($Format).Trim()
    
	Switch ($Type)
    {
        {$PSItem -lt 7} {Write-Log('Выбран тип резервной копии: Ежедневный (Daily)...')
            try
            {
                Write-Log('Папка резервной копии: ' + $Name + '_Daily')
				& 'C:\Program Files\PI\adm\pibackup.bat' $Name'_Daily' '1'
                Write-Log('Резервная копия данных PI Server успешно создана...')
            }
            catch
            {
                Write-Log('ВНИМАНИЕ! Ошибка создания резервной копии данных PI Server!')
            }
        }
        {$PSItem -eq 7} {Write-Log('Выбран тип резервной копии: Еженедельный (Weekly)...')
            try
            {
                Write-Log('Папка резервной копии: ' + $Name + '_Weekly')
				& 'C:\Program Files\PI\adm\pibackup.bat' $Name'_Weekly' '7'
                Write-Log('Резервная копия данных PI Server успешно создана...')
            }
            catch
            {
                Write-Log('ВНИМАНИЕ! Ошибка создания резервной копии данных PI Server!')
            }
        }
    }
}

<#
.SYNOPSIS
	Удаление файлов резервных копий дата создания которых, 
	превышает глубину (количество дней) заданное переменной $Deep.
#>
function Cleanup()
{
    Write-Log('Запуск процедуры удаления устаревших файлов резервных копий...')
	
	$Folders = Get-ChildItem -Path $Path | ?{$_.PSIsContainer}
    foreach ($Folder in $Folders)
    {
        if ($Folder.CreationTime -le (Get-Date).AddDays(-1 * $Deep))
        {
            Write-Log('Удаление папки: ' + $Folder.FullName)
            Remove-Item -Path $Folder.FullName -Recurse -Force
        }
    }
}

<#
.SYNOPSIS
	Вывод сообщения в файл журнал. Контроль размера файла журнала, переименование
	и создание нового файла в случае превышения.
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