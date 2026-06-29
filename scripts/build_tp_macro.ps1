$ErrorActionPreference = 'Stop'

$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$root = Split-Path -Parent $scriptDir
$templatePath = Join-Path $root 'templates\Template TP.xlsx'
$exportTemplatePath = Join-Path $root 'templates\Aguada.xlsx'
$logoPath = Join-Path $root 'assets\cor3_logo.png'
$outputPath = Join-Path $root 'outputs\Template TP - Macro Portal Transparencia - Export Municipios Applicant Type - Template Aguada.xlsm'

if (-not (Test-Path -LiteralPath $templatePath)) {
    throw "Template not found: $templatePath"
}
if (-not (Test-Path -LiteralPath $exportTemplatePath)) {
    throw "Export template not found: $exportTemplatePath"
}

Add-Type -AssemblyName System.IO.Compression.FileSystem

function Remove-WorkbookLocalPathMetadata {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$RootPath
    )

    if (-not (Test-Path -LiteralPath $Path)) { return }

    $resolvedRoot = (Resolve-Path -LiteralPath $RootPath).Path.TrimEnd('\') + '\'
    $outputsRoot = (Resolve-Path -LiteralPath (Join-Path $RootPath 'outputs')).Path.TrimEnd('\') + '\'
    $templatesRoot = (Resolve-Path -LiteralPath (Join-Path $RootPath 'templates')).Path.TrimEnd('\') + '\'
    $replacements = [ordered]@{}
    $replacements[$outputsRoot] = '.\outputs\'
    $replacements[$templatesRoot] = '.\templates\'
    $replacements[$resolvedRoot] = '.\'

    $tempPath = [System.IO.Path]::GetTempFileName()
    $sourceZip = [System.IO.Compression.ZipFile]::OpenRead($Path)
    $targetZip = [System.IO.Compression.ZipFile]::Open($tempPath, [System.IO.Compression.ZipArchiveMode]::Create)
    try {
        foreach ($entry in $sourceZip.Entries) {
            $newEntry = $targetZip.CreateEntry($entry.FullName, [System.IO.Compression.CompressionLevel]::Optimal)
            $newEntry.LastWriteTime = $entry.LastWriteTime

            $memory = New-Object System.IO.MemoryStream
            $entryStream = $entry.Open()
            try { $entryStream.CopyTo($memory) }
            finally { $entryStream.Dispose() }
            $bytes = $memory.ToArray()
            $memory.Dispose()

            if ($entry.FullName -match '\.(xml|rels)$') {
                $text = [System.Text.Encoding]::UTF8.GetString($bytes)
                foreach ($item in $replacements.GetEnumerator()) {
                    $text = $text.Replace($item.Key, $item.Value)
                }
                $bytes = [System.Text.Encoding]::UTF8.GetBytes($text)
            }

            $targetStream = $newEntry.Open()
            try { $targetStream.Write($bytes, 0, $bytes.Length) }
            finally { $targetStream.Dispose() }
        }
    }
    finally {
        $sourceZip.Dispose()
        $targetZip.Dispose()
    }

    Move-Item -LiteralPath $tempPath -Destination $Path -Force
}

$zip = [System.IO.Compression.ZipFile]::OpenRead($exportTemplatePath)
try {
    $mediaEntry = $zip.Entries | Where-Object { $_.FullName -like 'xl/media/*' } | Select-Object -First 1
    if ($null -eq $mediaEntry) { throw "No logo/media image found in export template: $exportTemplatePath" }
    if (Test-Path -LiteralPath $logoPath) { Remove-Item -LiteralPath $logoPath -Force }
    [System.IO.Compression.ZipFileExtensions]::ExtractToFile($mediaEntry, $logoPath)
}
finally {
    $zip.Dispose()
}

if (Test-Path -LiteralPath $outputPath) {
    Remove-Item -LiteralPath $outputPath -Force
}

$vbaCode = @'
Option Explicit

Private Const DATA_SHEET As String = "RoadToRecovery"
Private Const VALIDATION_SHEET As String = "Validacion"
Private Const TABLE_NAME As String = "RoadToRecovery"

Public Sub RefreshTransparencyPortal()
    Dim filePath As Variant
    filePath = Application.GetOpenFilename( _
        FileFilter:="Excel files (*.xlsx),*.xlsx", _
        Title:="Seleccione el Excel descargado del Portal de Transparencia")
    If VarType(filePath) = vbBoolean Then Exit Sub
    ImportPortalFile CStr(filePath), True
End Sub

Public Sub RefreshTransparencyPortalFromPath(ByVal filePath As String)
    ImportPortalFile filePath, False
End Sub

Public Sub ExportMunicipalityFiles()
    Dim folderPath As String
    With Application.FileDialog(4)
        .Title = "Seleccione la carpeta donde se guardaran los archivos por municipio"
        .AllowMultiSelect = False
        If .Show <> -1 Then Exit Sub
        folderPath = .SelectedItems(1)
    End With
    ExportMunicipalityFilesToFolder folderPath, True
End Sub

Public Sub ExportMunicipalityFilesToFolder(ByVal baseFolder As String, Optional ByVal showDoneMessage As Boolean = False)
    On Error GoTo CleanFail

    Dim previousScreenUpdating As Boolean
    Dim previousDisplayAlerts As Boolean
    Dim previousEnableEvents As Boolean
    previousScreenUpdating = Application.ScreenUpdating
    previousDisplayAlerts = Application.DisplayAlerts
    previousEnableEvents = Application.EnableEvents
    Application.ScreenUpdating = False
    Application.DisplayAlerts = False
    Application.EnableEvents = False
    Application.StatusBar = "Preparando exportacion por municipio..."

    If Len(Trim$(baseFolder)) = 0 Then Err.Raise vbObjectError + 201, , "Debe seleccionar una carpeta de salida."
    EnsureFolderExists baseFolder

    Dim sourceWs As Worksheet
    Dim lo As ListObject
    Set sourceWs = ThisWorkbook.Worksheets(DATA_SHEET)
    Set lo = sourceWs.ListObjects(TABLE_NAME)

    If lo.DataBodyRange Is Nothing Then
        Err.Raise vbObjectError + 202, , "La tabla RoadToRecovery no tiene datos. Primero use el boton Actualizar."
    End If

    Dim typeColumn As Long, municipalityColumn As Long
    typeColumn = 3
    municipalityColumn = 4
    If lo.ListColumns.Count < municipalityColumn Then Err.Raise vbObjectError + 203, , "No se encontro la columna Solicitante."

    Dim data As Variant, headers As Variant
    data = lo.DataBodyRange.Value
    headers = lo.HeaderRowRange.Value

    Dim rowCount As Long, colCount As Long
    rowCount = UBound(data, 1)
    colCount = 10

    Dim groups As Object
    Set groups = CreateObject("Scripting.Dictionary")
    groups.CompareMode = vbTextCompare

    Dim r As Long, municipality As String, applicantType As String
    For r = 1 To rowCount
        applicantType = CleanText(data(r, typeColumn))
        If StrComp(applicantType, "Municipio", vbTextCompare) <> 0 Then GoTo NextSourceRow
        municipality = CleanText(data(r, municipalityColumn))
        If Len(municipality) = 0 Then municipality = "Sin Municipio"
        If Not groups.Exists(municipality) Then groups.Add municipality, New Collection
        groups(municipality).Add r
NextSourceRow:
    Next r

    If groups.Count = 0 Then
        Err.Raise vbObjectError + 204, , "No se encontraron filas con Tipo de solicitante = Municipio."
    End If

    Dim exportRoot As String
    exportRoot = UniqueFolderPath(AddPathSeparator(baseFolder) & "Export Municipio " & Format(Now, "yyyymmdd_hhnnss"))
    EnsureFolderExists exportRoot

    Dim key As Variant, safeMunicipality As String, municipalityFolder As String, filePath As String
    Dim outWb As Workbook, outWs As Worksheet, outData() As Variant
    Dim outRow As Long, c As Long, rowIndex As Variant
    Dim rowIndexes As Collection
    Dim exportedCount As Long

    For Each key In groups.Keys
        Application.StatusBar = "Exportando municipio: " & CStr(key)
        safeMunicipality = SanitizeFileName(CStr(key))
        municipalityFolder = AddPathSeparator(exportRoot) & safeMunicipality
        EnsureFolderExists municipalityFolder

        Set rowIndexes = groups(key)
        ReDim outData(1 To rowIndexes.Count + 1, 1 To colCount)
        For c = 1 To colCount
            outData(1, c) = headers(1, c)
        Next c

        outRow = 2
        For Each rowIndex In rowIndexes
            For c = 1 To colCount
                outData(outRow, c) = data(CLng(rowIndex), c)
            Next c
            outRow = outRow + 1
        Next rowIndex

        Set outWb = Application.Workbooks.Add(-4167)
        Set outWs = outWb.Worksheets(1)
        outWb.Activate
        outWs.Activate
        outWs.Name = SanitizeSheetName(CStr(key))
        outWs.Columns("H:H").NumberFormat = "@"
        outWs.Range("A6").Resize(UBound(outData, 1), colCount).Value = outData

        Dim outLo As ListObject
        Set outLo = outWs.ListObjects.Add(1, outWs.Range("A6").Resize(UBound(outData, 1), colCount), , 1)
        outLo.Name = "RoadToRecovery_" & Left$(SanitizeTableName(safeMunicipality), 40)
        outLo.TableStyle = "TableStyleLight1"
        outLo.ShowAutoFilter = True
        outWs.Cells.Font.Name = "Poppins"
        outWs.Cells.Font.Size = 14
        outLo.HeaderRowRange.Font.Name = "Poppins"
        outLo.HeaderRowRange.Font.Size = 16
        outLo.HeaderRowRange.Font.Bold = True
        outLo.HeaderRowRange.WrapText = True
        outLo.HeaderRowRange.VerticalAlignment = -4108
        outLo.HeaderRowRange.HorizontalAlignment = -4108
        outWs.Rows("6").RowHeight = 60
        outLo.DataBodyRange.Font.Name = "Poppins"
        outLo.DataBodyRange.Font.Size = 14
        outLo.DataBodyRange.RowHeight = 22
        outLo.ListColumns(5).DataBodyRange.NumberFormat = "$#,##0"
        outLo.ListColumns(6).DataBodyRange.NumberFormat = "$#,##0"
        outLo.ListColumns(7).DataBodyRange.NumberFormat = "$#,##0"
        outLo.ListColumns(8).DataBodyRange.NumberFormat = "@"
        ApplyAguadaTemplateWidths outWs
        BuildReportHeading outWs, CStr(key)
        ApplyReportPageSetup outWs

        filePath = AddPathSeparator(municipalityFolder) & "RoadToRecovery - " & safeMunicipality & ".xlsx"
        outWb.SaveAs Filename:=filePath, FileFormat:=51
        outWb.Close SaveChanges:=False
        exportedCount = exportedCount + 1
    Next key

    ThisWorkbook.Worksheets("Inicio").Range("B14").Value = exportRoot
    ThisWorkbook.Worksheets("Inicio").Range("B15").Value = exportedCount
    ThisWorkbook.Worksheets("Inicio").Range("B16").Value = Now

    Application.StatusBar = False
    Application.ScreenUpdating = previousScreenUpdating
    Application.DisplayAlerts = previousDisplayAlerts
    Application.EnableEvents = previousEnableEvents

    If showDoneMessage Then
        MsgBox "Exportacion completada." & vbCrLf & vbCrLf & _
               "Municipios exportados: " & Format(exportedCount, "#,##0") & vbCrLf & _
               "Carpeta: " & exportRoot, vbInformation, "Template TP"
    End If
    Exit Sub

CleanFail:
    Dim msg As String
    msg = Err.Description
    On Error Resume Next
    If Not outWb Is Nothing Then outWb.Close SaveChanges:=False
    Application.StatusBar = False
    Application.ScreenUpdating = previousScreenUpdating
    Application.DisplayAlerts = previousDisplayAlerts
    Application.EnableEvents = previousEnableEvents
    On Error GoTo 0
    MsgBox "No se pudo completar la exportacion por municipio:" & vbCrLf & vbCrLf & msg, vbCritical, "Template TP"
End Sub

Private Sub ImportPortalFile(ByVal filePath As String, ByVal showDoneMessage As Boolean)
    On Error GoTo CleanFail

    Dim previousScreenUpdating As Boolean
    Dim previousEnableEvents As Boolean
    previousScreenUpdating = Application.ScreenUpdating
    previousEnableEvents = Application.EnableEvents
    Application.ScreenUpdating = False
    Application.EnableEvents = False
    Application.StatusBar = "Validando archivo del Portal de Transparencia..."

    If Len(Dir(filePath)) = 0 Then Err.Raise vbObjectError + 101, , "No se encontro el archivo seleccionado."

    Dim srcWb As Workbook
    Set srcWb = Workbooks.Open(Filename:=filePath, ReadOnly:=True, UpdateLinks:=False, AddToMru:=False)

    Dim srcWs As Worksheet
    Set srcWs = FindSourceWorksheet(srcWb)
    If srcWs Is Nothing Then Err.Raise vbObjectError + 102, , "No se encontro una hoja compatible en el archivo seleccionado."

    Dim headerMap As Object
    Set headerMap = CreateObject("Scripting.Dictionary")
    headerMap.CompareMode = vbTextCompare

    Dim lastCol As Long
    lastCol = srcWs.Cells(1, srcWs.Columns.Count).End(xlToLeft).Column

    Dim c As Long
    For c = 1 To lastCol
        If Len(Trim$(CStr(srcWs.Cells(1, c).Value))) > 0 Then
            headerMap(Trim$(CStr(srcWs.Cells(1, c).Value))) = c
        End If
    Next c

    Dim requiredHeaders As Variant
    requiredHeaders = Array("PW Number", "PW Title", "Applicant Type", "Applicant", "Project (DI) Cost", "Obligated", _
                            "Disbursed", "Disaster", "Damage Name", "Stage Details")

    Dim missing As String
    Dim i As Long
    For i = LBound(requiredHeaders) To UBound(requiredHeaders)
        If Not headerMap.Exists(CStr(requiredHeaders(i))) Then
            missing = missing & vbCrLf & " - " & CStr(requiredHeaders(i))
        End If
    Next i
    If Len(missing) > 0 Then
        Err.Raise vbObjectError + 103, , "El archivo seleccionado no tiene todos los encabezados esperados:" & missing
    End If

    Dim lastRow As Long
    lastRow = srcWs.Cells(srcWs.Rows.Count, headerMap("PW Number")).End(xlUp).Row
    If lastRow < 2 Then Err.Raise vbObjectError + 104, , "El archivo seleccionado no contiene filas de datos."

    Dim rowCount As Long
    rowCount = lastRow - 1
    Dim outputData() As Variant
    ReDim outputData(1 To rowCount, 1 To 10)

    Dim r As Long, sourceRow As Long
    For r = 1 To rowCount
        sourceRow = r + 1
        outputData(r, 1) = NormalizePwNumber(srcWs.Cells(sourceRow, headerMap("PW Number")).Value)
        outputData(r, 2) = CleanText(srcWs.Cells(sourceRow, headerMap("PW Title")).Value)
        outputData(r, 3) = TranslateApplicantType(srcWs.Cells(sourceRow, headerMap("Applicant Type")).Value)
        outputData(r, 4) = CleanText(srcWs.Cells(sourceRow, headerMap("Applicant")).Value)
        outputData(r, 5) = ToNumber(srcWs.Cells(sourceRow, headerMap("Project (DI) Cost")).Value)
        outputData(r, 6) = ToNumber(srcWs.Cells(sourceRow, headerMap("Obligated")).Value)
        outputData(r, 7) = ToNumber(srcWs.Cells(sourceRow, headerMap("Disbursed")).Value)
        outputData(r, 8) = NormalizeDisaster(srcWs.Cells(sourceRow, headerMap("Disaster")).Value)
        outputData(r, 9) = CleanText(srcWs.Cells(sourceRow, headerMap("Damage Name")).Value)
        outputData(r, 10) = TranslateStageDetails(srcWs.Cells(sourceRow, headerMap("Stage Details")).Value)
    Next r

    Application.StatusBar = "Actualizando tabla RoadToRecovery..."

    Dim targetWs As Worksheet
    Set targetWs = ThisWorkbook.Worksheets(DATA_SHEET)

    Dim lo As ListObject
    Set lo = targetWs.ListObjects(TABLE_NAME)

    If targetWs.AutoFilterMode Then targetWs.AutoFilterMode = False
    lo.Resize targetWs.Range(lo.HeaderRowRange.Cells(1, 1), targetWs.Cells(rowCount + 1, 10))
    lo.ListColumns(8).DataBodyRange.NumberFormat = "@"
    lo.DataBodyRange.Value = outputData

    ApplyOutputFormats lo
    ApplyAguadaTemplateWidths targetWs
    UpdateValidation filePath, rowCount, lastCol, srcWs.Name, headerMap

    srcWb.Close SaveChanges:=False

    ThisWorkbook.Worksheets("Inicio").Range("B9").Value = "Actualizado"
    ThisWorkbook.Worksheets("Inicio").Range("B10").Value = Now
    ThisWorkbook.Worksheets("Inicio").Range("B11").Value = rowCount
    ThisWorkbook.Worksheets("Inicio").Range("B12").Value = filePath
    ThisWorkbook.Worksheets("Inicio").Activate

    Application.StatusBar = False
    Application.ScreenUpdating = previousScreenUpdating
    Application.EnableEvents = previousEnableEvents

    If showDoneMessage Then
        MsgBox "Proceso completado." & vbCrLf & vbCrLf & _
               "Filas importadas: " & Format(rowCount, "#,##0") & vbCrLf & _
               "Revise la hoja Validacion para confirmar el resultado.", vbInformation, "Template TP"
    End If
    Exit Sub

CleanFail:
    Dim msg As String
    msg = Err.Description
    On Error Resume Next
    If Not srcWb Is Nothing Then srcWb.Close SaveChanges:=False
    Application.StatusBar = False
    Application.ScreenUpdating = previousScreenUpdating
    Application.EnableEvents = previousEnableEvents
    On Error GoTo 0
    MsgBox "No se pudo completar la actualizacion:" & vbCrLf & vbCrLf & msg, vbCritical, "Template TP"
End Sub

Private Function FindSourceWorksheet(ByVal wb As Workbook) As Worksheet
    On Error Resume Next
    Set FindSourceWorksheet = wb.Worksheets(DATA_SHEET)
    On Error GoTo 0
    If Not FindSourceWorksheet Is Nothing Then Exit Function

    Dim ws As Worksheet
    For Each ws In wb.Worksheets
        If LCase$(Trim$(CStr(ws.Cells(1, 1).Value))) = "pw number" Then
            Set FindSourceWorksheet = ws
            Exit Function
        End If
    Next ws
End Function

Private Function GetTableColumnIndex(ByVal lo As ListObject, ByVal columnName As String) As Long
    Dim i As Long
    For i = 1 To lo.ListColumns.Count
        If StrComp(lo.ListColumns(i).Name, columnName, vbTextCompare) = 0 Then
            GetTableColumnIndex = i
            Exit Function
        End If
    Next i
End Function

Private Sub BuildReportHeading(ByVal ws As Worksheet, ByVal municipalityName As String)
    Dim logo As Shape
    ws.Rows("1:5").RowHeight = 24
    ws.Range("A1:J5").Interior.Color = RGB(255, 255, 255)
    ws.Range("A1:J5").Font.Name = "Poppins"
    ws.Range("A1:J5").Font.Size = 14

    On Error Resume Next
    ThisWorkbook.Worksheets("LogoAsset").Visible = -1
    ThisWorkbook.Worksheets("LogoAsset").Activate
    ThisWorkbook.Worksheets("LogoAsset").Shapes("COR3Logo").Copy
    ws.Activate
    ws.Paste
    Set logo = ws.Shapes(ws.Shapes.Count)
    ThisWorkbook.Worksheets("LogoAsset").Visible = 0
    Application.CutCopyMode = False
    On Error GoTo 0
    If Not logo Is Nothing Then
        logo.Name = "COR3Logo"
        logo.LockAspectRatio = -1
        logo.Left = ws.Range("A1").Left + 6
        logo.Top = ws.Range("A1").Top + 6
        logo.Height = 54
    End If

    With ws.Range("D1:G3")
        .Merge
        .Value = "Informe Trimestral," & vbLf & "2026-Q2" & vbLf & municipalityName
        .Font.Name = "Poppins"
        .Font.Size = 16
        .Font.Bold = True
        .HorizontalAlignment = -4108
        .VerticalAlignment = -4108
        .WrapText = True
    End With

    With ws.Range("I1:J1")
        .Merge
        .Value = "Actualizado al: " & Format(Date, "m/d/yyyy")
        .Font.Name = "Poppins"
        .Font.Size = 14
        .Font.Bold = True
        .HorizontalAlignment = -4152
        .VerticalAlignment = -4108
    End With
End Sub

Private Sub ApplyReportPageSetup(ByVal ws As Worksheet)
    With ws.PageSetup
        .Orientation = 2
        .Zoom = False
        .FitToPagesWide = 1
        .FitToPagesTall = False
        .PrintTitleRows = "$6:$6"
        .LeftMargin = Application.InchesToPoints(0.25)
        .RightMargin = Application.InchesToPoints(0.25)
        .TopMargin = Application.InchesToPoints(0.35)
        .BottomMargin = Application.InchesToPoints(0.35)
        .HeaderMargin = Application.InchesToPoints(0.2)
        .FooterMargin = Application.InchesToPoints(0.2)
    End With
End Sub

Private Sub ApplyAguadaTemplateWidths(ByVal ws As Worksheet)
    ws.Columns("A").ColumnWidth = 24
    ws.Columns("B").ColumnWidth = 46
    ws.Columns("C").ColumnWidth = 25
    ws.Columns("D").ColumnWidth = 33
    ws.Columns("E").ColumnWidth = 22
    ws.Columns("F").ColumnWidth = 24
    ws.Columns("G").ColumnWidth = 27
    ws.Columns("H").ColumnWidth = 18
    ws.Columns("I").ColumnWidth = 55
    ws.Columns("J").ColumnWidth = 44
End Sub

Private Sub ApplyOutputFormats(ByVal lo As ListObject)
    With lo
        .TableStyle = "TableStyleLight1"
        .ShowAutoFilter = True
        .Range.Font.Name = "Poppins"
        .HeaderRowRange.Font.Size = 16
        .HeaderRowRange.Font.Bold = True
        If Not .DataBodyRange Is Nothing Then
            .DataBodyRange.Font.Size = 14
        End If
        .ListColumns("Costo de proyecto").DataBodyRange.NumberFormat = "$#,##0"
        .ListColumns("Obligado").DataBodyRange.NumberFormat = "$#,##0"
        .ListColumns("Desembolsado").DataBodyRange.NumberFormat = "$#,##0"
    End With
End Sub

Private Sub UpdateValidation(ByVal filePath As String, ByVal rowCount As Long, ByVal sourceColCount As Long, _
                             ByVal sourceSheetName As String, ByVal headerMap As Object)
    Dim ws As Worksheet
    Set ws = ThisWorkbook.Worksheets(VALIDATION_SHEET)
    ws.Cells.Clear

    ws.Range("A1").Value = "Validacion del refresco"
    ws.Range("A3").Value = "Archivo fuente"
    ws.Range("B3").Value = filePath
    ws.Range("A4").Value = "Hoja fuente"
    ws.Range("B4").Value = sourceSheetName
    ws.Range("A5").Value = "Fecha y hora"
    ws.Range("B5").Value = Now
    ws.Range("A6").Value = "Columnas detectadas"
    ws.Range("B6").Value = sourceColCount
    ws.Range("A7").Value = "Filas importadas"
    ws.Range("B7").Value = rowCount

    ws.Range("A10:D10").Value = Array("Campo final", "Encabezado fuente", "Columna fuente", "Estado")

    Dim finalHeaders As Variant, sourceHeaders As Variant
    finalHeaders = Array("Numero del PW", "Titulo de proyecto", "Tipo de solicitante", "Solicitante", _
                         "Costo de proyecto", "Obligado", "Desembolsado", "Desastre", "Nombre de dano", _
                         "Detalles de etapa")
    sourceHeaders = Array("PW Number", "PW Title", "Applicant Type", "Applicant", "Project (DI) Cost", "Obligated", _
                          "Disbursed", "Disaster", "Damage Name", "Stage Details")

    Dim i As Long
    For i = LBound(finalHeaders) To UBound(finalHeaders)
        ws.Cells(11 + i, 1).Value = finalHeaders(i)
        ws.Cells(11 + i, 2).Value = sourceHeaders(i)
        ws.Cells(11 + i, 3).Value = headerMap(sourceHeaders(i))
        ws.Cells(11 + i, 4).Value = "OK"
    Next i

    With ws.Range("A1:D1")
        .Merge
        .Font.Bold = True
        .Font.Size = 16
        .Font.Color = RGB(255, 255, 255)
        .Interior.Color = RGB(31, 78, 121)
    End With
    ws.Range("A10:D10").Font.Bold = True
    ws.Range("A10:D10").Interior.Color = RGB(221, 235, 247)
    ws.Range("A:D").EntireColumn.AutoFit
End Sub

Private Function CleanText(ByVal value As Variant) As Variant
    Dim s As String
    If IsError(value) Or IsEmpty(value) Or IsNull(value) Then
        CleanText = vbNullString
    Else
        s = CStr(value)
        s = Replace(s, ChrW(8211), "-")
        s = Replace(s, ChrW(8212), "-")
        CleanText = Trim$(s)
    End If
End Function

Private Function AddPathSeparator(ByVal folderPath As String) As String
    If Right$(folderPath, 1) = "\" Then
        AddPathSeparator = folderPath
    Else
        AddPathSeparator = folderPath & "\"
    End If
End Function

Private Sub EnsureFolderExists(ByVal folderPath As String)
    Dim fso As Object
    Set fso = CreateObject("Scripting.FileSystemObject")
    If Not fso.FolderExists(folderPath) Then fso.CreateFolder folderPath
End Sub

Private Function UniqueFolderPath(ByVal folderPath As String) As String
    Dim candidate As String, i As Long
    Dim fso As Object
    Set fso = CreateObject("Scripting.FileSystemObject")
    candidate = folderPath
    i = 2
    Do While fso.FolderExists(candidate)
        candidate = folderPath & " (" & i & ")"
        i = i + 1
    Loop
    UniqueFolderPath = candidate
End Function

Private Function SanitizeFileName(ByVal value As String) As String
    Dim s As String, invalidChars As Variant, i As Long
    s = Trim$(value)
    invalidChars = Array("\", "/", ":", "*", "?", """", "<", ">", "|")
    For i = LBound(invalidChars) To UBound(invalidChars)
        s = Replace(s, CStr(invalidChars(i)), "-")
    Next i
    Do While InStr(s, "  ") > 0
        s = Replace(s, "  ", " ")
    Loop
    Do While Right$(s, 1) = "." Or Right$(s, 1) = " "
        s = Left$(s, Len(s) - 1)
    Loop
    If Len(s) = 0 Then s = "Sin Municipio"
    If Len(s) > 80 Then s = Left$(s, 80)
    Select Case UCase$(s)
        Case "CON", "PRN", "AUX", "NUL", "COM1", "COM2", "COM3", "COM4", "COM5", "COM6", "COM7", "COM8", "COM9", _
             "LPT1", "LPT2", "LPT3", "LPT4", "LPT5", "LPT6", "LPT7", "LPT8", "LPT9"
            s = "_" & s
    End Select
    SanitizeFileName = s
End Function

Private Function SanitizeTableName(ByVal value As String) As String
    Dim s As String, i As Long, ch As String
    For i = 1 To Len(value)
        ch = Mid$(value, i, 1)
        If ch Like "[A-Za-z0-9_]" Then
            s = s & ch
        Else
            s = s & "_"
        End If
    Next i
    Do While InStr(s, "__") > 0
        s = Replace(s, "__", "_")
    Loop
    If Len(s) = 0 Then s = "Municipio"
    If Not Left$(s, 1) Like "[A-Za-z_]" Then s = "M_" & s
    SanitizeTableName = s
End Function

Private Function SanitizeSheetName(ByVal value As String) As String
    Dim s As String, invalidChars As Variant, i As Long
    s = Trim$(value)
    invalidChars = Array("\", "/", ":", "*", "?", "[", "]")
    For i = LBound(invalidChars) To UBound(invalidChars)
        s = Replace(s, CStr(invalidChars(i)), "-")
    Next i
    If Len(s) = 0 Then s = "Municipio"
    If Len(s) > 31 Then s = Left$(s, 31)
    Do While Right$(s, 1) = "'" Or Right$(s, 1) = " "
        s = Left$(s, Len(s) - 1)
    Loop
    SanitizeSheetName = s
End Function

Private Function ToNumber(ByVal value As Variant) As Variant
    If IsError(value) Or IsEmpty(value) Or IsNull(value) Or Len(Trim$(CStr(value))) = 0 Then
        ToNumber = 0
    ElseIf IsNumeric(value) Then
        ToNumber = CDbl(value)
    Else
        ToNumber = CDbl(Replace(CStr(value), ",", ""))
    End If
End Function

Private Function NormalizePwNumber(ByVal value As Variant) As String
    Dim s As String, p As Long, startPos As Long
    s = CleanText(value)
    p = InStr(1, s, "-PW-", vbTextCompare)
    If p > 4 Then
        startPos = p - 4
        NormalizePwNumber = Mid$(s, startPos)
    Else
        NormalizePwNumber = s
    End If
End Function

Private Function NormalizeDisaster(ByVal value As Variant) As String
    Dim s As String, p1 As Long, p2 As Long
    s = CleanText(value)
    p1 = InStrRev(s, "(")
    p2 = InStrRev(s, ")")
    If p1 > 0 And p2 > p1 Then
        NormalizeDisaster = Mid$(s, p1, p2 - p1 + 1)
    Else
        NormalizeDisaster = s
    End If
End Function

Private Function NormalizeCategory(ByVal value As Variant) As String
    Dim s As String
    s = CleanText(value)
    If LCase$(Left$(s, 8)) = "category" And Len(s) >= 10 Then
        NormalizeCategory = Mid$(s, 10, 1) & " "
    Else
        NormalizeCategory = s
    End If
End Function

Private Function TranslateApplicantType(ByVal value As Variant) As String
    Select Case CleanText(value)
        Case "Municipality": TranslateApplicantType = "Municipio"
        Case "Agency": TranslateApplicantType = "Agencia"
        Case "Private Non-Profit": TranslateApplicantType = "Organizaci" & ChrW(243) & "n sin fines de lucro"
        Case Else: TranslateApplicantType = CleanText(value)
    End Select
End Function

Private Function TranslateSector(ByVal value As Variant) As String
    Select Case CleanText(value)
        Case "Municipalities": TranslateSector = "Municipios"
        Case "Health and Social Services": TranslateSector = "Salud y Servicios Sociales"
        Case "Education": TranslateSector = "Educaci" & ChrW(243) & "n"
        Case "Housing": TranslateSector = "Vivienda"
        Case "Public Buildings": TranslateSector = "Edificios P" & ChrW(250) & "blicos"
        Case "Natural and Cultural Resources": TranslateSector = "Recursos Naturales y Culturales"
        Case "Transportation": TranslateSector = "Transportaci" & ChrW(243) & "n"
        Case "Water": TranslateSector = "Agua"
        Case "Energy": TranslateSector = "Energ" & ChrW(237) & "a"
        Case Else: TranslateSector = CleanText(value)
    End Select
End Function

Private Function TranslateSize(ByVal value As Variant) As String
    Select Case CleanText(value)
        Case "Large": TranslateSize = "Grande"
        Case "Small": TranslateSize = "Peque" & ChrW(241) & "o"
        Case Else: TranslateSize = CleanText(value)
    End Select
End Function

Private Function NormalizeQpr(ByVal value As Variant) As String
    NormalizeQpr = Replace(CleanText(value), "Quarter ", "Q")
End Function

Private Function TranslateCurrentStage(ByVal value As Variant) As String
    Select Case CleanText(value)
        Case "Planning": TranslateCurrentStage = "Planificaci" & ChrW(243) & "n"
        Case "Completed": TranslateCurrentStage = "Completado"
        Case "Construction": TranslateCurrentStage = "Construcci" & ChrW(243) & "n"
        Case "Procurement for Construction": TranslateCurrentStage = "Adquisici" & ChrW(243) & "n de construcci" & ChrW(243) & "n"
        Case "Design": TranslateCurrentStage = "Dise" & ChrW(241) & "o"
        Case "Procurement for Design": TranslateCurrentStage = "Adquisici" & ChrW(243) & "n de dise" & ChrW(241) & "o"
        Case "Permitting - Requested": TranslateCurrentStage = "Permisos - Solicitado"
        Case "Permitting - Granted": TranslateCurrentStage = "Permisos - Otorgado"
        Case Else: TranslateCurrentStage = CleanText(value)
    End Select
End Function

Private Function TranslateStageDetails(ByVal value As Variant) As String
    Select Case CleanText(value)
        Case "Other": TranslateStageDetails = "Otro"
        Case "Construction Completed": TranslateStageDetails = "Construcci" & ChrW(243) & "n completada"
        Case "Construction in Progress": TranslateStageDetails = "Construcci" & ChrW(243) & "n en progreso"
        Case "RFP Preparation or Bid Planning": TranslateStageDetails = "Preparaci" & ChrW(243) & "n de RFP o Planificaci" & ChrW(243) & "n de Subasta"
        Case "Design in Progress": TranslateStageDetails = "Dise" & ChrW(241) & "o en progreso"
        Case "Project scheduled/programmed": TranslateStageDetails = "Proyecto calendarizado"
        Case "Bid Published": TranslateStageDetails = "Subasta publicada"
        Case "Procurement Completed": TranslateStageDetails = "Adquisici" & ChrW(243) & "n completada"
        Case "Design Completed": TranslateStageDetails = "Dise" & ChrW(241) & "o completado"
        Case "Preparing Improved/Alternate Project": TranslateStageDetails = "Preparando proyecto mejorado/alterno"
        Case "Contract Awarded/Executed": TranslateStageDetails = "Contrato adjudicado/ejecutado"
        Case "State / Municipal - Other": TranslateStageDetails = "Estatal / Municipal - Otro"
        Case "State / Municipal - Construction": TranslateStageDetails = "Estatal / Municipal - Construcci" & ChrW(243) & "n"
        Case "Under Project Formulation - New version - Amendment": TranslateStageDetails = "En formulaci" & ChrW(243) & "n de proyecto - Nueva versi" & ChrW(243) & "n - Enmienda"
        Case "Under Insurance Review": TranslateStageDetails = "En revisi" & ChrW(243) & "n de seguro"
        Case "State / Municipal - Demolition": TranslateStageDetails = "Estatal / Municipal - Demolici" & ChrW(243) & "n"
        Case "Federal": TranslateStageDetails = "Federal"
        Case Else: TranslateStageDetails = CleanText(value)
    End Select
End Function

Private Function ParsePortalDate(ByVal value As Variant) As Variant
    If IsDate(value) And Not IsNumeric(value) Then
        ParsePortalDate = CDate(value)
        Exit Function
    End If

    Dim s As String
    s = CleanText(value)
    If Len(s) = 0 Then
        ParsePortalDate = vbNullString
        Exit Function
    End If

    Dim parts As Variant
    parts = Split(s, "/")
    If UBound(parts) = 2 Then
        ParsePortalDate = DateSerial(CInt(parts(2)), CInt(parts(0)), CInt(parts(1)))
    Else
        ParsePortalDate = s
    End If
End Function
'@

$workbookOpenCode = @'
Option Explicit

Private Sub Workbook_Open()
    On Error Resume Next
    ThisWorkbook.Worksheets("Inicio").Activate
End Sub
'@

$excel = $null
$workbook = $null
$exportTemplateWb = $null
try {
    $excel = New-Object -ComObject Excel.Application
    $excel.Visible = $false
    $excel.DisplayAlerts = $false
    $excel.ScreenUpdating = $false
    $excel.EnableEvents = $false

    $workbook = $excel.Workbooks.Open($templatePath)
    $workbook.SaveAs($outputPath, 52)

    $exportTemplateWb = $excel.Workbooks.Open($exportTemplatePath)
    $exportTemplateWb.Worksheets.Item(1).Copy([System.Type]::Missing, $workbook.Worksheets.Item($workbook.Worksheets.Count))
    $exportTemplateSheet = $excel.ActiveSheet
    $exportTemplateSheet.Name = 'ExportTemplate'
    $exportTemplateTable = $exportTemplateSheet.ListObjects.Item(1)
    $exportTemplateTable.Resize($exportTemplateSheet.Range('A1:J2'))
    $exportTemplateSheet.Range('A2:J2').ClearContents() | Out-Null
    $exportTemplateSheet.Range('A3:J1276').Clear() | Out-Null
    $exportTemplateSheet.Visible = 0
    $exportTemplateWb.Close($false) | Out-Null
    $exportTemplateWb = $null

    $logoSheet = $workbook.Worksheets.Add([System.Type]::Missing, $workbook.Worksheets.Item($workbook.Worksheets.Count))
    $logoSheet.Name = 'LogoAsset'
    $logoShape = $logoSheet.Shapes.AddPicture($logoPath, $false, $true, 10, 10, 150, 70)
    $logoShape.Name = 'COR3Logo'
    $logoSheet.Visible = 0

    # Build or reset Inicio.
    $inicio = $null
    try { $inicio = $workbook.Worksheets.Item('Inicio') } catch {}
    if ($null -eq $inicio) {
        $inicio = $workbook.Worksheets.Add($workbook.Worksheets.Item(1))
        $inicio.Name = 'Inicio'
    }
    $inicio.Cells.Clear()
    while ($inicio.Shapes.Count -gt 0) { $inicio.Shapes.Item(1).Delete() }

    $inicio.Range('A1:H1').Merge()
    $inicio.Range('A1').Value2 = 'Template TP - Actualizacion desde Portal de Transparencia'
    $inicio.Range('A1').Font.Bold = $true
    $inicio.Range('A1').Font.Size = 18
    $inicio.Range('A1').Font.Color = 16777215
    $inicio.Range('A1').Interior.Color = 7879740
    $inicio.Range('A3').Value2 = 'Proceso'
    $inicio.Range('A4').Value2 = '1. Descargue el Excel del Portal de Transparencia.'
    $inicio.Range('A5').Value2 = '2. Abra este archivo y habilite macros si Excel lo solicita.'
    $inicio.Range('A6').Value2 = '3. Presione el boton Actualizar y seleccione el archivo descargado.'
    $inicio.Range('A7').Value2 = '4. Revise la hoja Validacion y luego use la hoja RoadToRecovery.'
    $inicio.Range('A8').Value2 = '5. Para crear archivos separados solo de Tipo de solicitante Municipio, presione Exportar por municipio.'
    $inicio.Range('A9').Value2 = 'Estado'
    $inicio.Range('A10').Value2 = 'Ultima actualizacion'
    $inicio.Range('A11').Value2 = 'Filas importadas'
    $inicio.Range('A12').Value2 = 'Archivo usado'
    $inicio.Range('A14').Value2 = 'Carpeta de exportacion'
    $inicio.Range('A15').Value2 = 'Municipios exportados'
    $inicio.Range('A16').Value2 = 'Ultima exportacion'
    $inicio.Range('B9').Value2 = 'Pendiente'
    $inicio.Range('A3:A16').Font.Bold = $true
    $inicio.Columns.Item('A').ColumnWidth = 28
    $inicio.Columns.Item('B').ColumnWidth = 90
    $inicio.Range('A4:A8').RowHeight = 24
    $inicio.Range('A12:B14').WrapText = $true

    $button = $inicio.Shapes.AddShape(5, 620, 250, 300, 54)
    $button.Name = 'btnActualizarPortal'
    $button.TextFrame2.TextRange.Text = 'Actualizar desde archivo del portal'
    $button.TextFrame2.TextRange.Font.Bold = -1
    $button.TextFrame2.TextRange.Font.Size = 13
    $button.Fill.ForeColor.RGB = 5287936
    $button.Line.ForeColor.RGB = 5287936
    $button.TextFrame2.TextRange.Font.Fill.ForeColor.RGB = 16777215
    $button.OnAction = 'RefreshTransparencyPortal'

    $exportButton = $inicio.Shapes.AddShape(5, 620, 315, 300, 54)
    $exportButton.Name = 'btnExportarMunicipios'
    $exportButton.TextFrame2.TextRange.Text = 'Exportar municipios (Applicant Type)'
    $exportButton.TextFrame2.TextRange.Font.Bold = -1
    $exportButton.TextFrame2.TextRange.Font.Size = 13
    $exportButton.Fill.ForeColor.RGB = 12611584
    $exportButton.Line.ForeColor.RGB = 12611584
    $exportButton.TextFrame2.TextRange.Font.Fill.ForeColor.RGB = 16777215
    $exportButton.OnAction = 'ExportMunicipalityFiles'

    # Build or reset Validacion.
    $validacion = $null
    try { $validacion = $workbook.Worksheets.Item('Validacion') } catch {}
    if ($null -eq $validacion) {
        $validacion = $workbook.Worksheets.Add($workbook.Worksheets.Item($workbook.Worksheets.Count))
        $validacion.Name = 'Validacion'
    }
    $validacion.Cells.Clear()
    $validacion.Range('A1:D1').Merge()
    $validacion.Range('A1').Value2 = 'Validacion del refresco'
    $validacion.Range('A3').Value2 = 'Esta hoja se llena automaticamente despues de usar el boton Actualizar.'
    $validacion.Range('A1').Font.Bold = $true
    $validacion.Range('A1').Font.Size = 16
    $validacion.Range('A1').Font.Color = 16777215
    $validacion.Range('A1').Interior.Color = 7879740
    $validacion.Columns.Item('A').ColumnWidth = 28
    $validacion.Columns.Item('B').ColumnWidth = 45
    $validacion.Columns.Item('C').ColumnWidth = 18
    $validacion.Columns.Item('D').ColumnWidth = 18

    # Remove blank default sheet if present and empty.
    try {
        $sheet1 = $workbook.Worksheets.Item('Sheet1')
        if ($sheet1.UsedRange.Count -eq 1 -and [string]::IsNullOrWhiteSpace([string]$sheet1.Range('A1').Value2)) {
            $sheet1.Delete()
        }
    } catch {}

    $data = $workbook.Worksheets.Item('RoadToRecovery')
    $dataTable = $data.ListObjects.Item('RoadToRecovery')
    foreach ($colIndex in @(18, 16, 15, 14, 12, 11, 10, 9)) {
        if ($dataTable.ListColumns.Count -ge $colIndex) {
            $dataTable.ListColumns.Item($colIndex).Delete()
        }
    }
    $data.Activate()
    $data.Range('A1').Select() | Out-Null
    $excel.ActiveWindow.FreezePanes = $false
    $data.Range('A2').Select() | Out-Null
    $excel.ActiveWindow.FreezePanes = $true
    $data.Columns.Item('A:J').AutoFit() | Out-Null

    $module = $workbook.VBProject.VBComponents.Add(1)
    $module.Name = 'modPortalRefresh'
    $module.CodeModule.AddFromString($vbaCode)

    $thisWorkbook = $workbook.VBProject.VBComponents.Item('ThisWorkbook')
    $thisWorkbook.CodeModule.AddFromString($workbookOpenCode)

    if ($workbook.Worksheets.Item('Inicio').Index -ne 1) {
        $workbook.Worksheets.Item('Inicio').Move($workbook.Worksheets.Item(1))
    }
    $workbook.Worksheets.Item('Inicio').Activate()
    $workbook.Save()
}
finally {
    if ($null -ne $exportTemplateWb) { $exportTemplateWb.Close($false) | Out-Null }
    if ($null -ne $workbook) { $workbook.Close($true) | Out-Null }
    if ($null -ne $excel) {
        $excel.DisplayAlerts = $true
        $excel.Quit() | Out-Null
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null
    }
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
}

Remove-WorkbookLocalPathMetadata -Path $outputPath -RootPath $root

Write-Output $outputPath
