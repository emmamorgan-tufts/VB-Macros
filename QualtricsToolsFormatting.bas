Attribute VB_Name = "QualtricsTools"
''Updated 5/26/17

Sub define_table_styles()

    'After defining table styles, you MUST  edit table style
        'to uncheck "allow spacing between cells" box!

    Call Define_Matrix_Style
    Call define_appendix_table_style
    Call define_mc_table_style
    Call define_question_style


End Sub


Sub insert_header_footer()

With ActiveDocument

    Call Insert_OIRE
    Call Insert_logo
    Call Insert_footer
    
End With

End Sub

Sub format_survey_preview()

'    Application.ScreenUpdating = False

    'This macro should be used BEFORE any manual updates to the survey preview
    
    Dim i As Integer
    Dim ncol As Integer
    Dim nrow As Integer
    Dim ntables As Integer
    
    
    'This calls the formatting macros in order

    'Change global font and spacing, format title header
    
    Call Preview_Style_Change
    Call number_of_respondents
    
    Call replace_newline
    Call RemoveEmptyParagraphs
    
    With ActiveDocument

    ntables = .Tables.count
    
    For i = 1 To ntables
        ncol = .Tables(i).Columns.count
        nrow = .Tables(i).Rows.count
'        Debug.Print ncol

'        .Tables(i).AllowPageBreaks = False

        'We have one macro that will iterate through each table and perform
        'the appropriate formatting functions
        Call format_preview_tables(i, ncol)
        If ncol = 1 Then
            Call format_See_Appendix(i)
            Call format_UserNote(i)
        ElseIf ncol > 1 Then
            Call Replace_zeros(i)
            Call Replace_NaN(i)
            Call keepTableWithQuestion(i)
        End If

    Next
    
    End With
    
'    Application.ScreenUpdating = True
    
End Sub

Sub finish_clean_preview()

' This macro should be run AFTER the human components are finished
' This will number questions and delete question export tags from each table
' These macros can also easily be run separately, as long as the numbering is run first
' These apply ONLY to question info rows, so we can take advantage of this

         
    Call number_questions
    Call remove_denominatorRow
    Call Remove_Export_Tag

End Sub



Sub format_appendix()
'
' Macro that will call all the steps required to format appendix tables
'   for coded and raw text appendices

    With ActiveDocument
    
    Call Preview_Style_Change
       
    Call replace_newline
    Call RemoveEmptyParagraphs
       
    Dim ntables As Long
    ntables = .Tables.count
    Debug.Print ntables
    
    Dim i As Integer
    For i = 1 To ntables
        
        Dim celltxt As String
        celltxt = .Tables(i).Cell(4, 1).Range.Text
        If InStr(1, celltxt, "Coded Comments") Then
            isCodedComment = True
        Else
            isCodedComment = False
        End If
                
    
        .Tables(i).Select
        Selection.ClearParagraphAllFormatting
        Selection.EndOf
        
        nrow = .Tables(i).Rows.count
        ncol = .Tables(i).Columns.count
        
        'Remove text from second column of coded comment table header
        Call duplicateHeaderText(i)
            
        If (nrow >= 6) Then
            
         'set widths for each table
         .Tables(i).PreferredWidthType = wdPreferredWidthPercent
         .Tables(i).PreferredWidth = 100
         
         'Sort tables alphabetically for plain text, by N then alphabetically for coded
         Call alphabetize_table(i)
        
        .Tables(i).Style = "Appendix_style_table"
        
        'Align text vertically to be centered
            'Ideally this would be a part of the table style, but I couldn't find it....
        .Tables(i).Range.Cells.VerticalAlignment = wdCellAlignVerticalCenter
        
        .Tables(i).Rows.HeightRule = wdRowHeightAuto
                
        If ncol = 1 Then
            .Tables(i).ApplyStyleLastRow = False
            .Tables(i).ApplyStyleLastColumn = False
        ElseIf ncol = 2 And isCodedComment = True Then
            'Verify that it's a coded comment table
            .Tables(i).ApplyStyleLastRow = True
            .Tables(i).ApplyStyleLastColumn = True
            .Tables(i).Columns(2).Select
            Selection.Columns.PreferredWidthType = wdPreferredWidthPoints
            Selection.Columns.PreferredWidth = InchesToPoints(0.55)
            Selection.EndOf
        Else
            .Tables(i).ApplyStyleLastRow = False
            .Tables(i).ApplyStyleLastColumn = False
        
        End If
                 
         For j = 1 To 6
             .Tables(i).Rows(j).Select
             If j < 4 Then
                 With Selection
                     .Font.Bold = True
                     .ParagraphFormat.Alignment = wdAlignParagraphCenter
                     .Borders(wdBorderLeft).LineStyle = wdLineStyleNone
                     .Borders(wdBorderRight).LineStyle = wdLineStyleNone
                     .Borders(wdBorderTop).LineStyle = wdLineStyleNone
                     .Borders(wdBorderBottom).LineStyle = wdLineStyleNone
                 End With
             ElseIf j = 4 Then
                 With Selection
                     .Font.Italic = True
                     .ParagraphFormat.Alignment = wdAlignParagraphCenter
                     .Borders(wdBorderLeft).LineStyle = wdLineStyleNone
                     .Borders(wdBorderRight).LineStyle = wdLineStyleNone
                     .Borders(wdBorderTop).LineStyle = wdLineStyleNone
                     .Borders(wdBorderBottom).LineStyle = wdLineStyleNone
                 End With
             ElseIf j = 5 Then
                 Selection.Borders(wdBorderLeft).LineStyle = wdLineStyleNone
                 Selection.Borders(wdBorderRight).LineStyle = wdLineStyleNone
                 Selection.Borders(wdBorderTop).LineStyle = wdLineStyleNone
                 Selection.Borders(wdBorderBottom).LineStyle = wdLineStyleNone
             ElseIf j = 6 Then
                 With Selection
                     .Font.Bold = True
                     .Borders(wdBorderLeft).LineStyle = wdLineStyleSingle
                     .Borders(wdBorderRight).LineStyle = wdLineStyleSingle
                     .Borders(wdBorderTop).LineStyle = wdLineStyleSingle
                     .Borders(wdBorderBottom).LineStyle = wdLineStyleSingle
                 End With
                 
                 If ncol = 2 Then
                    .Tables(i).Cell(j, 2).Select
                    Selection.ParagraphFormat.Alignment = wdAlignParagraphCenter
                End If
             
             End If
             
         Next
         
        Call Appendix_Merge_Header(i)
        
        Set rptHeadCells = .Range(Start:=.Tables(i).Cell(1, 1).Range.Start, _
             End:=.Tables(i).Cell(3, ncol).Range.End)

                 'Make the first 6 rows into a header that will repeat across pages
         rptHeadCells.Rows.HeadingFormat = True

         
         'Need to add back side border to "responses" line
         'Also repeat bottom border so that it will exist if the table breaks
            'across multiple pages
         .Tables(i).Rows(3).Borders(wdBorderLeft).LineStyle = wdLineStyleSingle
         .Tables(i).Rows(3).Borders(wdBorderRight).LineStyle = wdLineStyleSingle
         .Tables(i).Rows(3).Borders(wdBorderVertical).LineStyle = wdLineStyleSingle
         .Tables(i).Rows(3).Borders(wdBorderBottom).LineStyle = wdLineStyleSingle
    
        End If
        
            
    Next
     
    End With
    
    Call Insert_footer
    
    'Make sure the stupid footer is the correct width...
    With ActiveDocument.Sections(1).Footers(wdHeaderFooterPrimary).Range.Tables(1)
        .PreferredWidthType = wdPreferredWidthPercent
        .PreferredWidth = 100
        
    End With
    
    

End Sub

Sub finish_clean_appendix()
'This macro should be run AFTER the human components are finished
'Removes the Export and Response Tags


    Call Remove_Export_Tag
    Call Remove_Response_Tag


End Sub
Sub Preview_Style_Change()

'First step in formatting preview
'Change global font and spacing for the document
    
    'Change paragraph spacing to have no space before or after
    'With HTML export, we need a few additional steps
    'Lauren discovered these in the senior survey; individual macros written
    ' and sent 11/17/16; incorporated 12/1/16
    
    'Specify Header 5 (block headers) to be Italic, Bold, size 14 font
    
    On Error Resume Next
    
    With ActiveDocument
    
        With .PageSetup
            .TopMargin = InchesToPoints(0.5)
            .BottomMargin = InchesToPoints(0.5)
            .LeftMargin = InchesToPoints(0.5)
            .RightMargin = InchesToPoints(0.5)
            
            .HeaderDistance = InchesToPoints(0.2)
            .FooterDistance = InchesToPoints(0.2)
            
        End With
        
        .Paragraphs.SpaceAfterAuto = False
        .Paragraphs.SpaceBeforeAuto = False
        .Paragraphs.SpaceBefore = 0
        .Paragraphs.SpaceAfter = 0
'        .Paragraphs.format.Alignment = wdAlignParagraphLeft
        
                
        'Change style of title (Heading 4), Block names (Header 5), and regular text (Compact)
                
        With .Styles("Heading 4")
            With .Font
                .Name = "Arial"
                .Size = 16
                .Color = wdColorAutomatic
            End With
            .ParagraphFormat.Alignment = wdAlignParagraphCenter
            .ParagraphFormat.SpaceAfter = 0
            .ParagraphFormat.SpaceBefore = 0
            
        End With
                
        With .Styles("Heading 5").Font
            .Name = "Arial"
            .Size = 14
            .Color = wdColorAutomatic
            .Italic = True
            .Bold = True
            .Underline = False
        End With
        
        With .Styles("Heading 5").ParagraphFormat
            .SpaceAfter = 0
            .SpaceBefore = 0
        End With
        
        With .Styles("Compact").Font
            .Name = "Arial"
            .Size = 10
            .Color = wdColorAutomatic
        End With
        
        With .Styles("Normal")
            With .Font
                .Name = "Arial"
                .Size = 10
                .Color = wdColorAutomatic
            End With
            .ParagraphFormat.SpaceAfter = 0
            .ParagraphFormat.SpaceBefore = 0
        End With
        
        With .Sections(1).Footers(wdHeaderFooterPrimary).Range
            .Paragraphs.SpaceBefore = 0
            .Paragraphs.SpaceAfter = 0
            .ParagraphFormat.LineSpacingRule = wdLineSpacingSingle
        End With
        
    'Find "Number of Respondents", select line, and change font to 10
    '.Wrap = wdFindContinue will find this regardless of where the cursor is in the doc
       
    End With
    
End Sub

Sub number_of_respondents()

    'This currently will format only overall reports
    'We will need to add an addition search for "Size of respondent group"
        'if we would like to add formatting for split reports

    With ActiveDocument
    
        With Selection.find
            .Text = "Number of Respondents: "
            .Forward = True
            .Wrap = wdFindContinue
            .format = False
            .MatchCase = True
        End With
        
        Selection.find.Execute
        
        If Selection.find.Found = True Then
            Selection.Expand wdParagraph
            Selection.Font.Size = 10
            Selection.ParagraphFormat.Alignment = wdAlignParagraphCenter
            Selection.Collapse
        Else
            Selection.find.Text = "Size of Respondent Group: "
            Selection.find.Execute
            If Selection.find.Found = True Then
                Selection.Expand wdLine
                Selection.Font.Size = 10
                Selection.ParagraphFormat.Alignment = wdAlignParagraphCenter
                Selection.Collapse
            End If
            
        End If
        
        
        
    End With

End Sub


Sub Insert_OIRE()

' Moves to the upper right hand corner and inserts, then formats, text
' This is inserted with its own formatting and can be used with any document;
    ' this is then adjusted when we change the format of Heading 4 in Preview_Style_Change
' Created by Adam Kaminski, summer 2016
' Updated ECM 5/25/17
    

With ActiveDocument

    oireName = "Office of Institutional" + Chr(10) + "Research & Evaluation" + Chr(10)
    
    Selection.HomeKey Unit:=wdStory
    Selection.TypeParagraph
    Selection.HomeKey Unit:=wdStory
    Selection.ParagraphFormat.Alignment = wdAlignParagraphRight
    With Selection.Font
        .Bold = True
        .Italic = False
        .Underline = False
        .Name = "Arial"
        .Size = 16
        .Color = wdColorAutomatic
    End With
    
    Selection.TypeText Text:=oireName
    Selection.Collapse

End With


End Sub


Sub Insert_logo()
'
' Inserts the Tufts logo in the upper left hand corner
' Created by Adam Kaminski, summer 2016
' Edits by ECM

    With ActiveDocument
        'Navigate to the top of the page
        Selection.HomeKey Unit:=wdStory
        'Pick an image via its path and insert it
        Selection.InlineShapes.AddPicture FileName:= _
        "Q:\Student Work\Emma's Student Work\Report Generation\Report Macros_Adam\tufts_logo_black.png" _
        , LinkToFile:=False, SaveWithDocument:=True
        'Select the image
        ActiveDocument.InlineShapes(1).Select
        'format the image (lock aspect ratio and adjust height)
        With Selection.InlineShapes(1)
            .LockAspectRatio = msoTrue
            .Height = 35
        End With
        'Move it to the upper left hand corner (0, 0)
        Set nShp = Selection.InlineShapes(1).ConvertToShape
        With .Shapes(1)
            .Top = 0
            .Left = 0
        End With
        
        Selection.Collapse

    End With
    
End Sub

Sub Insert_footer()
'
' Inserts a footer
'As written, assumes there is only one section; if this changes, we need to uncomment these lines

'    Dim i As Long
   ' For i = 1 To ActiveDocument.Sections.Count
'    For Each Section In ActiveDocument.Sections
'        Dim myfooter As Word.Range

    'Clear the footer if anything exists
    
    ActiveDocument.Sections(1).Footers(wdHeaderFooterPrimary).Range.Select
    Selection.Delete
    
    'In the event that we are JUST using this function, we need to change the style and format
    
    With ActiveDocument.Sections(1).Footers(wdHeaderFooterPrimary).Range
            .Paragraphs.SpaceBefore = 0
            .Paragraphs.SpaceAfter = 0
            .ParagraphFormat.LineSpacingRule = wdLineSpacingSingle
            .Font.Name = "Arial"
            .Font.Size = 9
    End With

    Dim footerTable As Table
    With ActiveDocument
        Set insert_footerTable = .Tables.Add(.Sections(1).Footers(wdHeaderFooterPrimary).Range, 2, 3)
                
        Dim oireFooter As String
        Dim analystFooter As String
        Dim internalUse As String
        Dim reportName As String
        Dim analystName As String
        Dim dateText As String
        
        'Create defeault settings for all user entry
        
        reportName = InputBox("Enter Name of sruvey, Year, Special Population" & Chr(10) _
            & "Default: NAME OF SURVEY, YEAR, AND SPECIAL POPULATION (IF APPLICABLE)")
        analystName = InputBox("Analyst Name" & Chr(10) & "Default: ANALYST NAME")
        dateText = InputBox("Enter Date" & Chr(10) & "Default: INSERT DATE")
        
        If reportName = "" Then _
            reportName = "NAME OF SURVEY, YEAR, AND SPECIAL POPULATION (IF APPLICABLE)"
        If analystName = "" Then analystName = "ANALYST NAME"
        If dateText = "" Then dateText = "INSERT DATE"
        
        Debug.Print ("ReportName: " & reportName)
        Debug.Print ("analystName: " & analystName)
        Debug.Print ("dateText: " & dateText)
        
        oireFooter = "Office of Institutional Research & Evaluation" + _
            Chr(10) + reportName
        analystFooter = "Prepared by: " & analystName + Chr(10) + _
            dateText
            
        internalUse = "**This report is intended for internal use only**"
            
        Set footerTable = .Sections(1).Footers(wdHeaderFooterPrimary).Range.Tables(1)
                        
        With footerTable
                        
            .TopPadding = InchesToPoints(0.08)
            .BottomPadding = InchesToPoints(0)
            .LeftPadding = InchesToPoints(0)
            .RightPadding = InchesToPoints(0)
            
        
            With .Cell(1, 1).Range
                .Text = oireFooter
                .ParagraphFormat.Alignment = wdAlignParagraphLeft
            End With
            
            .Cell(1, 2).Range.Select
            Selection.Collapse
            With Selection
                .Fields.Add Range:=Selection.Range, Type:=wdFieldEmpty, Text:= _
                "PAGE ", preserveFormatting:=True
                .TypeText Text:=" of "
                .Fields.Add Range:=Selection.Range, Type:=wdFieldEmpty, Text:= _
                "NUMPAGES ", preserveFormatting:=True
            End With
            
            .Cell(1, 2).Range.ParagraphFormat.Alignment = wdAlignParagraphCenter
            
            With .Cell(1, 3).Range
                .Text = analystFooter
                .ParagraphFormat.Alignment = wdAlignParagraphRight
            End With
            
            .Cell(2, 1).Range.Text = internalUse
            
            'Remove borders from the footer table
            
            .Borders(wdBorderTop).LineStyle = wdLineStyleNone
            .Borders(wdBorderBottom).LineStyle = wdLineStyleNone
            .Borders(wdBorderLeft).LineStyle = wdLineStyleNone
            .Borders(wdBorderRight).LineStyle = wdLineStyleNone
            .Borders(wdBorderHorizontal).LineStyle = wdLineStyleNone
            .Borders(wdBorderVertical).LineStyle = wdLineStyleNone
                
        End With
        
        'Merge cells of second row and format text to be centered and italicized
        
        Dim mrgrng As Range

        Set mrgrng = footerTable.Cell(2, 1).Range
        mrgrng.End = footerTable.Cell(2, 3).Range.End
        mrgrng.Cells.Merge
        
        footerTable.Rows(2).Select
        Selection.ParagraphFormat.Alignment = wdAlignParagraphCenter
        Selection.Font.Italic = True
    

    If ActiveWindow.View.SplitSpecial <> wdPaneNone Then
        ActiveWindow.Panes(2).Close
    End If
    If ActiveWindow.ActivePane.View.Type = wdNormalView Or ActiveWindow. _
        ActivePane.View.Type = wdOutlineView Then
        ActiveWindow.ActivePane.View.Type = wdPrintView
    End If

    
    End With
    
    With ActiveDocument.Sections(1).Footers(wdHeaderFooterPrimary).Range.Tables(1)
        .PreferredWidthType = wdPreferredWidthPercent
        .PreferredWidth = 100
        
        .Cell(1, 2).PreferredWidthType = wdPreferredWidthPercent
        .Cell(1, 2).PreferredWidth = 12
        
        .Cell(1, 1).PreferredWidthType = wdPreferredWidthPercent
        .Cell(1, 1).PreferredWidth = 44
        
        .Cell(1, 3).PreferredWidthType = wdPreferredWidthPercent
        .Cell(1, 3).PreferredWidth = 44
        
        .Rows.leftindent = InchesToPoints(0)
    End With

    
End Sub


Sub format_preview_tables(i As Integer, ncol As Integer)
    Dim exportTag As String

    ActiveDocument.Tables(i).Select
    Selection.ClearFormatting
'    Selection
    Selection.Collapse

    If ncol = 1 Then
        Call format_question_style(i)
    ElseIf ncol = 3 Then
        Call format_mc_singleQ(i)
    ElseIf ncol > 3 Then
        Call format_matrix_table(i)
    
    End If
    
    If i > 1 And ncol >= 3 Then
        exportTag = ActiveDocument.Tables(i - 1).Cell(1, 1).Range.Text
        exportTag = Trim(Left(exportTag, Len(exportTag) - 2))
        Debug.Print "Processed results: " + exportTag + " (" + Str(i) + ")"
    End If

End Sub

Sub define_mc_table_style()

    On Error Resume Next
    ActiveDocument.Styles("mc_table_style").Delete
    
    ActiveDocument.Styles.Add Name:="mc_table_style", Type:=wdStyleTypeTable
    
    With ActiveDocument.Styles("mc_table_style")
    
        With .ParagraphFormat
            .leftindent = InchesToPoints(0.08)
            .RightIndent = InchesToPoints(0.08)
            .Alignment = wdAlignParagraphRight
            .SpaceAfter = 0
            .SpaceBefore = 0
            .LineSpacingRule = wdLineSpaceSingle
            .KeepWithNext = True
        End With
        
        'We can specify formatting for the first and last column
        'Make default the foramtting for % since this will be unspecified
        
        .Font.Bold = True
        .Font.Name = "Arial"
        .Font.Size = 10
        
        With .Table

'            .AllowPageBreaks = False
            .AllowBreakAcrossPage = False
            
            .RightPadding = 0
            .LeftPadding = 0
            .TopPadding = InchesToPoints(0.01)
            .BottomPadding = InchesToPoints(0.01)
            
            .Borders.InsideLineStyle = wdLineStyleNone
            .Borders.OutsideLineStyle = wdLineStyleNone

            With .Condition(wdFirstColumn)
                
                With .Font
                    .Bold = True
                    .Italic = True
                    .ColorIndex = wdGray50
                End With
                
                .ParagraphFormat.Alignment = wdAlignParagraphRight
            
            End With
            
            With .Condition(wdLastColumn)
                
                .Font.Bold = False
                .ParagraphFormat.Alignment = wdAlignParagraphLeft
            
            End With
        
        End With
            

               
        'Format first column: bold, italic, gray, right aligned
        
    End With
        
    
End Sub

Sub format_mc_singleQ(i As Integer)
    
    With ActiveDocument
    
        .Tables(i).Style = "mc_table_style"

        .Tables(i).ApplyStyleFirstColumn = True
        .Tables(i).ApplyStyleLastColumn = True
    
    'Check to make sure that the first row has labels for "N" and "Percent"
    'If yes, delete the first row
        
        cellText1 = .Tables(i).Cell(1, 1).Range.Text
        cellText2 = .Tables(i).Cell(1, 2).Range.Text
'        Debug.Print "Cell_1: " & cellText1
'        Debug.Print "Cell_2: " & cellText2
        
        If cellText1 Like "N*" And cellText2 Like "Percent*" Then
            .Tables(i).Rows(1).Delete
        End If
        
        .Tables(i).AutoFitBehavior (wdAutoFitContent)
        
    
    End With
    
End Sub


Sub define_question_style()

    On Error Resume Next
    ActiveDocument.Styles("question_style").Delete
    
    ActiveDocument.Styles.Add Name:="question_style", Type:=wdStyleTypeTable
    
    With ActiveDocument.Styles("question_style")
        With .Table

'            .AllowPageBreaks = False
            .AllowBreakAcrossPage = False
            
'            .Spacing = InchesToPoints(0)
            .TopPadding = InchesToPoints(0)
            .BottomPadding = InchesToPoints(0)
            .LeftPadding = InchesToPoints(0)
            .RightPadding = InchesToPoints(0)
            
        End With
        
        With .ParagraphFormat
            .KeepWithNext = True
            .LineSpacingRule = wdLineSpaceSingle
            .SpaceAfter = 0
            .SpaceBefore = 0
        End With
        
    End With
        
    
End Sub

Sub format_question_style(i As Integer)

'Format question text and information
    
    Dim nrow As Integer
        
    With ActiveDocument
        nrow = .Tables(i).Rows.count

        .Tables(i).Style = "question_style"
        
        'format the question info, identified by single column
            ' Set table width to full page
        .Tables(i).PreferredWidthType = wdPreferredWidthPercent
        .Tables(i).PreferredWidth = 100
        
        'Bold question text
        .Tables(i).Rows(2).Select
        With Selection
            .Font.Bold = True
        End With
    
        'Make display logic red to highlight
        If nrow >= 3 Then
            Dim r As Long
            For r = 3 To nrow
                .Tables(i).Rows(r).Select
                With Selection.Font
                    .Bold = True
                    .Color = wdColorDarkRed
                End With
                Selection.Collapse
            Next
        End If
        
    ' Stop table from breaking across page

End With
    
End Sub


Sub Define_Matrix_Style()

    'If the style exists from a previous run, delete and redefine
    
    On Error Resume Next
    ActiveDocument.Styles("Matrix_table_style").Delete
    
    ActiveDocument.Styles.Add Name:="Matrix_table_style", Type:=wdStyleTypeTable
    
    With ActiveDocument.Styles("Matrix_table_style")
            
        With .Font
            .Name = "Arial"
            .Size = 10
            .Bold = True
            .Italic = False
            .ColorIndex = wdAuto
        End With
        
        With .ParagraphFormat
            .LineUnitAfter = 0
            .LineUnitBefore = 0
            .LineSpacingRule = wdLineSpaceSingle
            .Alignment = wdAlignParagraphCenter
            .KeepWithNext = True
        End With
                
        With .Table
            .RowStripe = 1
            .ColumnStripe = 0
'            .AllowPageBreaks = False
            .AllowBreakAcrossPage = False
            
            .LeftPadding = 0
            .RightPadding = 0
            .TopPadding = 0.01
            .BottomPadding = 0.01
'            .Spacing = InchesToPoints(0)
            
            With .Condition(wdFirstColumn)
                .Font.Bold = False
                .ParagraphFormat.Alignment = wdAlignParagraphLeft
                .ParagraphFormat.leftindent = InchesToPoints(0.08)
                .ParagraphFormat.RightIndent = InchesToPoints(0.08)

            End With
            
            With .Condition(wdFirstRow)
                With .Borders(wdBorderTop)
                    .LineStyle = wdLineStyleSingle
                    .LineWidth = wdLineWidth050pt
                    .Color = wdColorAutomatic
                End With
                
                With .Borders(wdBorderBottom)
                    .LineStyle = wdLineStyleSingle
                    .LineWidth = wdLineWidth050pt
                    .Color = wdColorAutomatic
                End With
                
                With .Borders(wdBorderRight)
                    .LineStyle = wdLineStyleSingle
                    .LineWidth = wdLineWidth050pt
                    .Color = wdColorAutomatic
                End With
                
                With .Borders(wdBorderVertical)
                    .LineStyle = wdLineStyleSingle
                    .LineWidth = wdLineWidth050pt
                    .Color = wdColorAutomatic
                End With
                
            End With
                        
            With .Condition(wdEvenRowBanding)
                With .Shading
                    .Texture = wdTextureNone
                    .ForegroundPatternColor = wdColorAutomatic
                    .BackgroundPatternColor = RGB(220, 230, 250)
                End With
            
                With .Borders(wdBorderVertical)
                    .LineStyle = wdLineStyleSingle
                    .LineWidth = wdLineWidth050pt
                    .Color = wdColorAutomatic
                End With
    
                With .Borders(wdBorderLeft)
                    .LineStyle = wdLineStyleSingle
                    .LineWidth = wdLineWidth050pt
                    .Color = wdColorAutomatic
                End With
            
                With .Borders(wdBorderRight)
                    .LineStyle = wdLineStyleSingle
                    .LineWidth = wdLineWidth050pt
                    .Color = wdColorAutomatic
                End With
            
            End With
          
            With .Borders(wdBorderVertical)
                .LineStyle = wdLineStyleSingle
                .LineWidth = wdLineWidth050pt
                .Color = wdColorAutomatic
            End With
    
            With .Borders(wdBorderLeft)
                .LineStyle = wdLineStyleSingle
                .LineWidth = wdLineWidth050pt
                .Color = wdColorAutomatic
            End With
            
            With .Borders(wdBorderRight)
                .LineStyle = wdLineStyleSingle
                .LineWidth = wdLineWidth050pt
                .Color = wdColorAutomatic
            End With
            
            With .Borders(wdBorderBottom)
                .LineStyle = wdLineStyleSingle
                .LineWidth = wdLineWidth050pt
                .Color = wdColorAutomatic
            End With
    
            With .Borders(wdBorderTop)
                .LineStyle = wdLineStyleSingle
                .LineWidth = wdLineWidth050pt
                .Color = wdColorAutomatic
            End With
            
        End With
        
    End With

End Sub

Sub format_matrix_table(i As Integer)

    Dim isNATable As Boolean
    isNATable = False
    
    With ActiveDocument
    
    'For reproducability - if we have already formatted the NA style type, delete the first row and start again
    
    If .Tables(i).Rows(1).Cells.count <> .Tables(i).Rows(.Tables(i).Rows.count).Cells.count _
        And InStr(1, .Tables(i).Cell(1, 2).Range.Text, "Of those NOT selecting") Then
        .Tables(i).Rows(1).Delete
    End If

        With .Tables(i)
            .Style = "Matrix_table_style"
            .ApplyStyleFirstColumn = True
            .ApplyStyleHeadingRows = True
        End With
        
        .Tables(i).Select
        Selection.Cells.VerticalAlignment = wdCellAlignVerticalCenter
        Selection.ParagraphFormat.leftindent = InchesToPoints(0.08)
        Selection.ParagraphFormat.RightIndent = InchesToPoints(0.08)
        
        Selection.Collapse
                    
        .Tables(i).Cell(1, 1).Borders(wdBorderLeft).LineStyle = wdLineStyleNone
        .Tables(i).Cell(1, 1).Borders(wdBorderTop).LineStyle = wdLineStyleNone
        
        .Tables(i).PreferredWidthType = wdPreferredWidthPercent
        .Tables(i).PreferredWidth = 100
        
        .Tables(i).Columns(1).PreferredWidth = InchesToPoints(3.5)
                        
        'Format N columns

        Dim nColumns As Long
        nColumns = .Tables(i).Columns.count

        For j = 2 To nColumns
    
            .Tables(i).Columns(j).Select
            
            Selection.find.ClearFormatting
            
            With Selection.find
                .Text = "N"
                .MatchWholeWord = True
            End With
            Selection.find.Execute
            
            If Selection.find.Found = True Then
                .Tables(i).Columns(j).PreferredWidth = InchesToPoints(0.47)
                                 
                .Tables(i).Columns(j).Select
                With Selection
                     .Font.Italic = True
                     .Font.ColorIndex = wdGray50
                 End With
                 
                 With Selection.find
                    .Text = "total_N"
                    .Replacement.Text = "Total N"
                End With

                Selection.find.Execute Replace:=wdReplaceOne
                                
                Selection.Collapse
      
            End If
             
        Next
        
        Selection.find.ClearFormatting
        Selection.find.Text = "Total N"
        .Tables(i).Select
        Selection.find.Execute
        If Selection.find.Found = True Then isNATable = True
        
        If isNATable Then Call format_NA_table(.Tables(i))
        
        Selection.Collapse

    End With
    

End Sub


Sub format_NA_table(tbl As Table)

'Adapted from Rebecca's macro
'Adjusted by Emma to be called in sequence with the macros rather than separate

    Dim rowHeadings As Row
    Dim cellHeading As Cell
    Dim iHeadingsRowIndex As Integer
    Dim iNAColumnIndex As Integer
    Dim iNAColumnIndexMin As Integer
    Dim iLast As Integer
    Dim NAText As String
    Dim validRange As Range

    
    iHeadingsRowIndex = 1                  'Set heading row to 1st row.  Best way to determine this for now.
    iNAColumnIndexMin = 4
    
    isTableTypeNA = False
    Set rowHeadings = tbl.Rows(iHeadingsRowIndex)
    
    For Each cellHeading In rowHeadings.Cells
        If InStr(1, cellHeading.Range.Text, "Total N") Then ' And cellHeading.ColumnIndex > iNAColumnIndexMin Then
            iNAColumnIndex = cellHeading.ColumnIndex
            Exit For
        End If
    Next cellHeading
    

    NAText = tbl.Cell(1, tbl.Columns.count).Range.Text
    NAText = Trim(Left(NAText, Len(NAText) - 2))
    Debug.Print NAText

    tbl.Rows.Add BeforeRow:=tbl.Rows(1)
    tbl.Cell(1, 1).Borders(wdBorderBottom).LineStyle = wdLineStyleNone
    
    With tbl.Cell(Row:=1, Column:=2).Range
        .Text = "Of those NOT selecting " & Chr(34) & NAText & Chr(34)
        .Font.Bold = True
    End With
    
    With tbl.Cell(Row:=1, Column:=iNAColumnIndex).Range
        .Text = "Of all respondents"
        .Font.Bold = True
    End With
    
    Set validRange = tbl.Cell(1, 2).Range
    validRange.SetRange Start:=validRange.Start, _
    End:=tbl.Cell(tbl.Rows.count, iNAColumnIndex - 1).Range.End

    validRange.Borders(wdBorderBottom).LineWidth = wdLineWidth150pt
    validRange.Borders(wdBorderTop).LineWidth = wdLineWidth150pt
    validRange.Borders(wdBorderLeft).LineWidth = wdLineWidth150pt
    validRange.Borders(wdBorderRight).LineWidth = wdLineWidth150pt
    
    tbl.Rows(2).Range.Borders(wdBorderBottom).LineStyle = wdLineStyleSingle
    tbl.Rows(2).Range.Borders(wdBorderBottom).LineWidth = wdLineWidth050pt
                
    If iNAColumnIndex >= 4 Then
        tbl.Cell(Row:=1, Column:=2).Merge MergeTo:=tbl.Cell(Row:=1, Column:=iNAColumnIndex - 1)
    End If
    iLast = tbl.Rows(1).Cells.count
    tbl.Cell(Row:=1, Column:=3).Merge MergeTo:=tbl.Cell(Row:=1, Column:=iLast)


    
End Sub



Sub Replace_zeros(i As Integer)
'
' Searches for "0.0%" and replaces it with "--"
' Created by Adam Kaminsky
' Edited by EM to make sure the program didn't stop part of the way through

    Application.DisplayAlerts = False
    
    
    ActiveDocument.Tables(i).Range.Select
    Selection.find.ClearFormatting
    Selection.find.Replacement.ClearFormatting
    With Selection.find
        .Text = "0.0%"
        .Replacement.Text = "--"
        .Forward = True
        .Wrap = wdFindStop
        .format = False
        .MatchCase = True
        .MatchWholeWord = False
        .MatchWildcards = False
        .MatchSoundsLike = False
        .MatchAllWordForms = False
        .MatchPrefix = True
    End With
    
    Selection.find.Execute Replace:=wdReplaceAll

'    Next

    
End Sub

Sub Replace_NaN(i As Integer)
'
' Searches for "NaN%" resulting from denominator 0 and replaces it with "--"
' Adapted from "Replace 0" code
' Created by Adam Kaminsky
' Edited by EM to make sure the program didn't stop part of the way through

    Application.DisplayAlerts = False
    
  
    ActiveDocument.Tables(i).Range.Select
    Selection.find.ClearFormatting
    Selection.find.Replacement.ClearFormatting
    With Selection.find
        .Text = "NaN%"
        .Replacement.Text = "--"
        .Forward = True
        .Wrap = wdFindStop
        .format = False
        .MatchCase = True
        .MatchWholeWord = False
        .MatchWildcards = False
        .MatchSoundsLike = False
        .MatchAllWordForms = False
        .MatchPrefix = False
    End With
    
    Selection.find.Execute Replace:=wdReplaceAll
    

    
End Sub

Sub number_questions()
'
' Numbers questions in the survey preview
' Run as part of the final cleaning macro.
'
    With ActiveDocument
    
    Dim Q As Long
    Q = 1
    
    Dim ntables As Long
    ntables = .Tables.count

    For i = 1 To ntables
        ncol = .Tables(i).Columns.count
        
    If ncol = 1 Then
        'delete data export tag
        qText = .Tables(i).Cell(2, 1).Range.Text
        qNum = CStr(Q)
        qTextNum = qNum + ". " + qText
        .Tables(i).Cell(2, 1).Range.Select
        Selection.Delete
        .Tables(i).Cell(2, 1).Range.Text = Left(qTextNum, Len(qTextNum) - 2)
        .Tables(i).Cell(2, 1).Range.Select
        With Selection.find
            .Text = "^p"
            .Replacement.Text = ""
            .Forward = True
            .Wrap = wdFindStop
            .format = False
            .MatchCase = False
            .MatchWholeWord = False
            .MatchWildcards = False
            .MatchSoundsLike = False
            .MatchAllWordForms = False
        End With
        Selection.find.Execute

    Q = Q + 1
     
    End If
    Next
    
    End With

End Sub

Sub remove_denominatorRow()

    Dim i As Integer
    Dim ntables As Integer
    
    With ActiveDocument
    
    ntables = .Tables.count

    Selection.find.ClearFormatting
    Selection.find.Replacement.ClearFormatting
    
    With Selection.find
            .Text = "Denominator Used:"
            .Replacement.Text = ""
            .Forward = True
            .Wrap = wdFindStop
            .format = False
            .MatchCase = True
            .MatchWholeWord = False
            .MatchWildcards = False
            .MatchSoundsLike = False
            .MatchAllWordForms = False
    End With
    
    For i = 1 To ntables
        If .Tables(i).Columns.count = 1 Then
            .Tables(i).Select

            If Selection.find.Execute Then Selection.Rows.Delete
        End If
    Next
    
    End With

End Sub

Sub remove_questionInfo_row()
'
' Removes question data export tags from the question info tables in the survey preview
' Called as part of the final cleaning up macro
'
    With ActiveDocument
    
    Dim ntables As Long
    ntables = .Tables.count
    
    For i = 1 To ntables
        ncol = .Tables(i).Columns.count
        
'        Delete first row of the question info (data export tag)
'        This will only appear in question info in the preview; all others have 3+ columns
'        This can be used for appendices to remove first row from coded and full text comments
        
        If ncol <= 2 Then
            'delete data export tag
            .Tables(i).Rows(1).Select
            Selection.Rows.Delete
                    
        End If
    Next
            
    End With
    
End Sub

Sub define_appendix_table_style()

    'If the style exists from a previous run, delete and redefine
    On Error Resume Next
    ActiveDocument.Styles("Appendix_style_table").Delete

    ActiveDocument.Styles.Add Name:="Appendix_style_table", Type:=wdStyleTypeTable

    With ActiveDocument.Styles("Appendix_style_table")
        With .Font
            .Name = "Arial"
            .Size = 10
            .Color = wdColorAutomatic
        End With
        
        With .ParagraphFormat
            .Alignment = wdAlignParagraphLeft
            .RightIndent = InchesToPoints(0.1)
            .leftindent = InchesToPoints(0.1)
        End With
        
        With .Table
            
             ' Not sure what these do; want to keep rows from breaking,
             'and possibly keep tables together(?)
            .AllowPageBreaks = False
            .AllowBreakAcrossPage = False
        
            .RowStripe = 1
            .ColumnStripe = 0
            
            .LeftPadding = InchesToPoints(0)
            .RightPadding = InchesToPoints(0)
    
            With .Condition(wdOddRowBanding)
                With .Shading
                    .Texture = wdTextureNone
                    .ForegroundPatternColor = wdColorAutomatic
                    .BackgroundPatternColor = RGB(220, 230, 250)
                End With
                                
                With .Borders(wdBorderLeft)
                    .LineStyle = wdLineStyleSingle
                    .LineWidth = wdLineWidth050pt
                    .Color = wdColorAutomatic
                End With
                
                With .Borders(wdBorderRight)
                    .LineStyle = wdLineStyleSingle
                    .LineWidth = wdLineWidth050pt
                    .Color = wdColorAutomatic
                End With
                
                With .Borders(wdBorderVertical)
                    .LineStyle = wdLineStyleSingle
                    .LineWidth = wdLineWidth050pt
                    .Color = wdColorAutomatic
                End With
            
            End With

            'Adjust borders
            With .Borders(wdBorderLeft)
                .LineStyle = wdLineStyleSingle
                .LineWidth = wdLineWidth050pt
                .Color = wdColorAutomatic
            End With
            
            With .Borders(wdBorderRight)
                .LineStyle = wdLineStyleSingle
                .LineWidth = wdLineWidth050pt
                .Color = wdColorAutomatic
            End With
            
            With .Borders(wdBorderBottom)
                .LineStyle = wdLineStyleSingle
                .LineWidth = wdLineWidth050pt
                .Color = wdColorAutomatic
            End With
            
            'Vertical borders should be included for coded comment appendices
            With .Borders(wdBorderVertical)
                .LineStyle = wdLineStyleSingle
                .LineWidth = wdLineWidth050pt
                .Color = wdColorAutomatic
            End With
            
            'For coded comments, need to change style of the last row to adjust
            With .Condition(wdLastRow)
                .Font.Bold = True
                .Borders(wdBorderTop).LineStyle = wdLineStyleSingle
                .Borders(wdBorderTop).LineWidth = wdLineWidth050pt
            End With
            
            With .Condition(wdLastColumn)
                .ParagraphFormat.Alignment = wdAlignParagraphCenter
            End With
                   
          'Format Header to have bottom border
            With .Condition(wdFirstRow).Borders(wdBorderBottom)
                .LineStyle = wdLineStyleSingle
                .LineWidth = wdLineWidth050pt
                .Color = wdColorAutomatic
            End With
            
        End With

    End With

End Sub

Sub alphabetize_table(i As Integer)
Attribute alphabetize_table.VB_ProcData.VB_Invoke_Func = "Normal.NewMacros.alphabetize_table"
'
' alphabetize_table Macro
'From recorded macro; has not yet been tested or incorporated into macro
'

'Sort verbatim text appendices alphabetically
    With ActiveDocument
    
        Dim ntables As Long
        ntables = .Tables.count
    
            nrow = .Tables(i).Rows.count
            ncol = .Tables(i).Columns.count
            
            If (nrow > 6) Then
                With .Tables(i)
                    Set responseRows = .Rows(7).Range
                    If ncol = 1 Then
                        responseRows.End = .Rows(nrow).Range.End
                    ElseIf ncol = 2 Then
                        responseRows.End = .Rows(nrow - 1).Range.End
                    End If
                End With
                
                responseRows.Select
                If (ncol = 1) Then
                    Selection.Sort ExcludeHeader:=False, _
                        FieldNumber:="Column 1", _
                        SortFieldType:=wdSortFieldAlphanumeric, _
                        SortOrder:=wdSortOrderAscending, _
                        LanguageID:=wdEnglishUS, subFieldNumber:="Paragraphs"
                ElseIf (ncol = 2) Then
                    Selection.Sort ExcludeHeader:=False, _
                        FieldNumber:="Column 2", _
                        SortFieldType:=wdSortFieldNumeric, _
                        SortOrder:=wdSortOrderDescending, _
                        FieldNumber2:="Column 1", _
                        SortFieldType2:=wdSortFieldAlphanumeric, _
                        SortOrder2:=wdSortOrderAscending, _
                        LanguageID:=wdEnglishUS, subFieldNumber:="Paragraphs"
                End If
            
            End If
    End With
End Sub

Sub Appendix_Merge_Header(i As Integer)
Attribute Appendix_Merge_Header.VB_ProcData.VB_Invoke_Func = "Normal.NewMacros.Appendix_Merge_Header"
'
' Appendix_Merge_Header Macro
'
'
With ActiveDocument

ncol = .Tables(i).Columns.count

If ncol = 2 Then
    .Tables(i).Rows(1).Select
    Selection.Cells.Merge
End If


Set mergeCells = .Tables(i).Rows(2).Range
mergeCells.End = .Tables(i).Rows(5).Range.End
mergeCells.Select
Selection.Cells.Merge

With Selection.ParagraphFormat
    .SpaceBefore = 0
    .SpaceAfter = 5
End With

.Tables(i).Rows(2).Height = 1

End With

End Sub

Sub duplicateHeaderText(i As Integer)

'The program produces coded comment tables with header text printed twice
'Before we merge the cells, we need to delete the duplicate text
'This macro will remove the text in the header rows of the second column

With ActiveDocument


    ncol = .Tables(i).Columns.count

'Clear text from coded comment tables; likely, this should be its own macro
    If ncol = 2 Then
        Set duplicateHead = .Tables(i).Columns(2).Cells(1).Range
        duplicateHead.End = .Tables(i).Columns(2).Cells(4).Range.End
        duplicateHead.Select
        duplicateHead.Delete
    End If

'Next

End With

End Sub


Sub fix_page_breaks()

'Macro written by CBB to adjust page breaks in appendix tables
' Will need to adapt code to work with preview tables as well
' Version with EM edits

    With ActiveDocument
        Dim ntables As Long
        ntables = .Tables.count
        
        Selection.find.ClearFormatting
        Selection.find.Replacement.ClearFormatting
        
        With Selection.find
            .Text = "Responses: "
            .Forward = True
            .Wrap = wdFindStop
            .format = False
            .MatchCase = True
            .MatchWholeWord = False
            .MatchWildcards = False
            .MatchSoundsLike = False
            .MatchAllWordForms = False
        End With

    
    For i = 1 To ntables
    
        nrow = .Tables(i).Rows.count
        
        'Determine page of first row in table

        .Tables(i).Rows(1).Select
        FirstRowPage = Selection.Information(wdActiveEndPageNumber)
        Debug.Print "FirstRowPage: " + Str(FirstRowPage)

        'Need to determine whether there are actual responses
        
        .Tables(i).Select
        
        If Selection.find.Execute Then
            ResponseRow = Selection.Information(wdEndOfRangeRowNumber)
            ResponseRowPage = Selection.Information(wdActiveEndPageNumber)
            
            Debug.Print "ResponseRow: " + Str(ResponseRow)
            Debug.Print "nrow: " + Str(nrow)
            Debug.Print "ResponseRowPage: " + Str(ResponseRowPage)
            
            If ResponseRow = nrow Then
                If ResponseRowPage <> FirstRowPage Then
                    .Tables(i).Rows(1).Select
                    Selection.InsertBreak (wdPageBreak)
                End If
            
            ElseIf ResponseRow < nrow Then
                .Tables(i).Rows(ResponseRow + 1).Select
                FirstCommentPage = Selection.Information(wdActiveEndPageNumber)
                Debug.Print "FirstCommentPage: " + Str(FirstCommentPage)
                
                If FirstRowPage <> FirstCommentPage Then
                    .Tables(i).Rows(1).Select
                    Selection.InsertBreak (wdPageBreak)
                End If
            End If
        End If
                              
    Next
    
    End With

End Sub



Sub preview_remove_block_titles()

'This macro will remove the section indicators (block titles from .qsf)
'They are currently input into the document as heading 5
'We want to delete the row of text with heading 5 and the next row

With Selection.find
    .ClearFormatting
    .Style = ActiveDocument.Styles("Heading 5")
    .Replacement.ClearFormatting
    .Text = ""
    .Replacement.Text = ""
    .Forward = True
    .Wrap = wdFindStop
    .format = True
    .MatchCase = True
    .MatchWholeWord = False
    .MatchWildcards = False
    .MatchSoundsLike = False
    .MatchAllWordForms = False
End With


npar = ActiveDocument.Paragraphs.count
Debug.Print (npar)
For i = 1 To npar
    Debug.Print "Paragraph" + Str(i)
    ActiveDocument.Paragraphs(i).Range.Select
    Selection.HomeKey Unit:=wdLine
    Selection.find.Execute

    If Selection.find.Found = True Then
        Selection.find.Parent.MoveDown Unit:=wdLine, count:=2, Extend:=wdExtend
        Selection.find.Parent.Delete
    Else: Exit For
    End If

Next
        
End Sub

Sub TableCellPadding()

'For Lauren to run after previews have been generated
'Will adjust cell padding for all tables
'Need to add this to initial macro for others to run

With ActiveDocument
    ntables = .Tables.count
    For i = 1 To ntables
        ncol = .Tables(i).Columns.count
        nrow = .Tables(i).Rows.count
        
        If ncol > 1 Then
            With .Tables(i)
                .LeftPadding = InchesToPoints(0.08)
                .RightPadding = InchesToPoints(0.08)
                .TopPadding = InchesToPoints(0.01)
                .BottomPadding = InchesToPoints(0.01)
                
                
            End With
        End If
    Next

End With

End Sub

Sub remove_blockHeaders()

    With ActiveDocument
    
    Dim loopCount As Integer
    loopCount = 1
    
    
    Selection.find.ClearFormatting
    Selection.find.Style = .Styles("Heading 5")
    With Selection.find
     .Text = ""
        .Replacement.Text = ""
        .Forward = True
        .Wrap = wdFindAsk
        .format = True
        .MatchCase = False
        .MatchWholeWord = False
        .MatchByte = False
        .MatchWildcards = False
        .MatchSoundsLike = False
        .MatchAllWordForms = False
    End With
    Selection.HomeKey Unit:=wdStory
    Selection.find.Execute
    
    Do While Selection.find.Found = True And loopCount < 1000
    
        Debug.Print iCount
        Selection.Expand wdParagraph
        Selection.Delete
        Selection.EndOf
        Selection.HomeKey Unit:=wdStory
        Selection.find.Execute
    Loop
    
    
    
    End With

    Call RemoveEmptyParagraphs

End Sub


Sub replace_newline()

    Dim wrdDoc As Document
    Set wrdDoc = ActiveDocument
    wrdDoc.Content.Select

'Replace new line character (^l) with carraige return (^p)
    Selection.find.ClearFormatting
    Selection.find.Replacement.ClearFormatting

    With Selection.find
        'oryginal
        .Text = "^l"
        .Replacement.Text = "^p"
        .Forward = True

    End With

GoHere:
    Selection.find.Execute Replace:=wdReplaceAll

    If Selection.find.Execute = True Then
        GoTo GoHere
    End If

End Sub

Sub format_See_Appendix(i)

    With ActiveDocument
    
    Selection.find.ClearFormatting
    Selection.find.Replacement.ClearFormatting
        
    With Selection.find
        .Text = "See Appendix."
        .Replacement.Text = ""
        .Forward = True
        .Wrap = wdFindStop
        .format = False
        .MatchCase = True
        .MatchWholeWord = False
        .MatchWildcards = False
        .MatchSoundsLike = False
        .MatchAllWordForms = False
    End With
    
    .Tables(i).Select
    
    If Selection.find.Execute Then
        Selection.ParagraphFormat.leftindent = InchesToPoints(0.5)
        Selection.ParagraphFormat.SpaceBefore = 10
    End If
    Selection.Collapse
  
    End With

End Sub

Sub format_UserNote(i)

    With ActiveDocument
    
    Selection.find.ClearFormatting
    Selection.find.Replacement.ClearFormatting
        
    With Selection.find
        .Text = "User Note: "
        .Replacement.Text = ""
        .Forward = True
        .Wrap = wdFindStop
        .format = False
        .MatchCase = True
        .MatchWholeWord = False
        .MatchWildcards = False
        .MatchSoundsLike = False
        .MatchAllWordForms = False
    End With

    .Tables(i).Select
    
    Selection.find.Execute
    If Selection.find.Found = True Then
        Selection.SelectRow
 '       Selection.Expand (wdTableRow)
 '       Selection.Expand (wdParagraph)
        Selection.Font.ColorIndex = wdAuto
        Selection.Font.Italic = True
        Selection.Font.Bold = False
        Selection.ParagraphFormat.leftindent = InchesToPoints(0.5)
'        Selection.find.Execute Replace:=wdReplaceAll
    End If
    Selection.Collapse
    
    End With

End Sub


Sub RemoveEmptyParagraphs()

    Selection.find.ClearFormatting
    Selection.find.Replacement.ClearFormatting
    Selection.find.Replacement.Font.Underline = wdUnderlineSingle
    With Selection.find
        .Text = "^p^$"
        .Replacement.Text = "^&"
        .Forward = True
        .Wrap = wdFindContinue
        .format = True
        .MatchCase = True
        .MatchWholeWord = False
        .MatchWildcards = False
        .MatchSoundsLike = False
        .MatchAllWordForms = False
    End With
    Selection.find.Execute Replace:=wdReplaceAll
    
    Selection.find.ClearFormatting
    Selection.find.Font.Italic = True
    Selection.find.Replacement.ClearFormatting
    Selection.find.Replacement.Font.Underline = wdUnderlineSingle
    With Selection.find
        .Text = "^p"
        .Replacement.Text = "^&"
        .Forward = True
        .Wrap = wdFindContinue
        .format = True
        .MatchCase = True
        .MatchWholeWord = False
        .MatchWildcards = False
        .MatchSoundsLike = False
        .MatchAllWordForms = False
    End With
    Selection.find.Execute Replace:=wdReplaceAll
    
    Selection.find.ClearFormatting
    Selection.find.Font.Underline = wdUnderlineSingle
    Selection.find.Replacement.ClearFormatting
    With Selection.find.Replacement.Font
        .Bold = True
        .Underline = wdUnderlineSingle
    End With
    With Selection.find
        .Text = "^p"
        .Replacement.Text = "^&"
        .Forward = True
        .Wrap = wdFindContinue
        .format = True
        .MatchCase = True
        .MatchWholeWord = False
        .MatchWildcards = False
        .MatchSoundsLike = False
        .MatchAllWordForms = False
    End With
    Selection.find.Execute Replace:=wdReplaceAll
    
    Selection.find.ClearFormatting
    Selection.find.Font.Bold = False
    Selection.find.Replacement.ClearFormatting
    With Selection.find
        .Text = "^p"
        .Replacement.Text = ""
        .Forward = True
        .Wrap = wdFindContinue
        .format = True
        .MatchCase = True
        .MatchWholeWord = False
        .MatchWildcards = False
        .MatchSoundsLike = False
        .MatchAllWordForms = False
    End With
    Selection.find.Execute Replace:=wdReplaceAll
    
    Selection.find.ClearFormatting
    Selection.find.Font.Underline = wdUnderlineSingle
    Selection.find.Replacement.ClearFormatting
    Selection.find.Replacement.Font.Underline = wdUnderlineNone
    With Selection.find
        .Text = "^p^$"
        .Replacement.Text = "^&"
        .Forward = True
        .Wrap = wdFindContinue
        .format = True
        .MatchCase = True
        .MatchWholeWord = False
        .MatchWildcards = False
        .MatchSoundsLike = False
        .MatchAllWordForms = False
    End With
    Selection.find.Execute Replace:=wdReplaceAll
    
    
     Selection.find.ClearFormatting
    Selection.find.Replacement.ClearFormatting
    With Selection.find.Replacement.Font
        .Bold = False
        .Italic = False
    End With
    With Selection.find
        .Text = "^p"
        .Replacement.Text = "^p"
        .Forward = True
        .Wrap = wdFindContinue
        .format = True
        .MatchCase = False
        .MatchWholeWord = False
        .MatchWildcards = False
        .MatchSoundsLike = False
        .MatchAllWordForms = False
    End With
    Selection.find.Execute Replace:=wdReplaceAll
        
 
End Sub

Sub Remove_Export_Tag()

    Selection.find.ClearFormatting
    With Selection.find
        .Text = "Export Tag: "
        .Replacement.Text = ""
        .Forward = True
        .Wrap = wdFindAsk
        .format = False
        .MatchCase = False
        .MatchWholeWord = False
        .MatchWildcards = False
        .MatchSoundsLike = False
        .MatchAllWordForms = False
    End With
    
    Do While Selection.find.Execute
        Selection.Rows.Delete
    Loop
    
End Sub



Sub NumberingAppendices()
' Working on numbering the appendices
' Currently Double Prints A. should fix that/one possible method is just go back and look for it and delete it
'
    Selection.TypeBackspace
    Selection.TypeText Text:=" "
    'Selection.Fields.Add Range:=Selection.Range, Type:=wdFieldEmpty, Text:= _
    '    "AUTONUM  \* ALPHABETIC ", PreserveFormatting:=False
    
    ActiveWindow.View.ShowFieldCodes = True
     Selection.Fields.Add Range:=Selection.Range, Type:=wdFieldEmpty, _
    preserveFormatting:=False
Selection.TypeText Text:="QUOTE"
 Selection.Fields.Add Range:=Selection.Range, Type:=wdFieldEmpty, _
    preserveFormatting:=False
Selection.TypeText Text:="Set A2Z"
Selection.Fields.Add Range:=Selection.Range, Type:=wdFieldEmpty, _
    preserveFormatting:=False
Selection.TypeText Text:="=MOD("
Selection.Fields.Add Range:=Selection.Range, Type:=wdFieldEmpty, _
    preserveFormatting:=False
Selection.TypeText Text:="SEQ ABC"
'Selection.Fields.Add Range:=Selection.Range, Type:=wdFieldEmpty, _
'    PreserveFormatting:=False
'Selection.TypeText Text:="MERGEFIELD FHB"
Selection.MoveRight Unit:=wdCharacter, count:=2
Selection.TypeText Text:="-1,26)+1"
Selection.MoveRight Unit:=wdCharacter, count:=4
Selection.Fields.Add Range:=Selection.Range, Type:=wdFieldEmpty, _
    preserveFormatting:=False
Selection.TypeText Text:="Set AA2ZZ"
Selection.Fields.Add Range:=Selection.Range, Type:=wdFieldEmpty, _
    preserveFormatting:=False
Selection.TypeText Text:="=INT(("
Selection.Fields.Add Range:=Selection.Range, Type:=wdFieldEmpty, _
    preserveFormatting:=False
Selection.TypeText Text:="SEQ ABC \c"
Selection.MoveRight Unit:=wdCharacter, count:=2
Selection.TypeText Text:="-1)/26)"
Selection.MoveRight Unit:=wdCharacter, count:=4
Selection.Fields.Add Range:=Selection.Range, Type:=wdFieldEmpty, _
    preserveFormatting:=False
Selection.TypeText Text:="IF"
Selection.Fields.Add Range:=Selection.Range, Type:=wdFieldEmpty, _
    preserveFormatting:=False
Selection.TypeText Text:="AA2ZZ \* ALPHABETIC"
Selection.MoveRight Unit:=wdCharacter, count:=2
Selection.TypeText Text:="= """""
Selection.MoveLeft Unit:=wdCharacter, count:=1
Selection.TypeText Text:=" "
Selection.MoveRight Unit:=wdCharacter, count:=2
Selection.TypeText Text:=""""""
Selection.Fields.Add Range:=Selection.Range, Type:=wdFieldEmpty, _
    preserveFormatting:=False
Selection.TypeText Text:="AA2ZZ \* ALPHABETIC"
Selection.MoveRight Unit:=wdCharacter, count:=2
Selection.Fields.Add Range:=Selection.Range, Type:=wdFieldEmpty, _
    preserveFormatting:=False
Selection.TypeText Text:="A2Z \* ALPHABETIC"
ActiveWindow.View.ShowFieldCodes = False
    
    
    Selection.MoveLeft Unit:=wdCharacter, count:=1, Extend:=wdExtend
    Selection.Copy
    Selection.find.ClearFormatting
    Selection.find.Replacement.ClearFormatting
    With Selection.find
        .Text = "See Appendix"
        .Replacement.Text = "See Appendix ^c"
        .Forward = True
        .Wrap = wdFindAsk
        .format = False
        .MatchCase = True
        .MatchWholeWord = False
        .MatchWildcards = False
        .MatchSoundsLike = False
        .MatchAllWordForms = False
    End With
    Selection.find.Execute Replace:=wdReplaceAll
End Sub



Sub UpdateMultipleFiles()
Dim file
Dim path As String

'Change this to the folder with the files that you want to run macros on
path = "Q:\Student Work\Emma's Student Work\Suneeth\Grad Exit 2015 Program-level Appendices\New folder\"

file = Dir(path & "\" & "*.*")

Application.DisplayAlerts = wdAlertsNone

Do While file <> ""
    Documents.Open FileName:=path & file
    
    ' Call all the macros that you want to run on the files in the folder
    Call define_table_styles
    Call format_appendix
    Call remove_first_row
    Call Remove_Responses_Tag
    Call preview_remove_block_titles
    Call delete_text_brackets
    
    ' Saves the file
    ActiveDocument.Save
    ActiveDocument.Close
    ' set file to next in Dir
    file = Dir()
Loop
End Sub

Sub Remove_Responses_Tag()

    Selection.find.ClearFormatting
    With Selection.find
        .Text = "Responses: (^?)"
        .Replacement.Text = "Responses"
        .Forward = True
        .Wrap = wdFindAsk
        .format = False
        .MatchCase = False
        .MatchWholeWord = False
        .MatchWildcards = False
        .MatchSoundsLike = False
        .MatchAllWordForms = False
    End With
    Selection.find.Execute Replace:=wdReplaceAll
    
    Selection.find.ClearFormatting
    With Selection.find
        .Text = "Responses: (^?^?)"
        .Replacement.Text = "Responses"
        .Forward = True
        .Wrap = wdFindAsk
        .format = False
        .MatchCase = False
        .MatchWholeWord = False
        .MatchWildcards = False
        .MatchSoundsLike = False
        .MatchAllWordForms = False
    End With
    Selection.find.Execute Replace:=wdReplaceAll
    
    
    Selection.find.ClearFormatting
    With Selection.find
        .Text = "Responses: (^?^?^?)"
        .Replacement.Text = "Responses"
        .Forward = True
        .Wrap = wdFindAsk
        .format = False
        .MatchCase = False
        .MatchWholeWord = False
        .MatchWildcards = False
        .MatchSoundsLike = False
        .MatchAllWordForms = False
    End With
    Selection.find.Execute Replace:=wdReplaceAll
    
        Selection.find.ClearFormatting
    With Selection.find
        .Text = "Responses: (^?^?^?^?)"
        .Replacement.Text = "Responses"
        .Forward = True
        .Wrap = wdFindAsk
        .format = False
        .MatchCase = False
        .MatchWholeWord = False
        .MatchWildcards = False
        .MatchSoundsLike = False
        .MatchAllWordForms = False
    End With
    Selection.find.Execute Replace:=wdReplaceAll
    
    
End Sub

Sub delete_text_brackets()
' Specifically for Rebecca's Grad Exit Project
' remove_open_bracket Macro
'
'
    Selection.find.ClearFormatting
    Selection.find.Replacement.ClearFormatting
    With Selection.find
        .Text = "(\[)*(\])"
        .Replacement.Text = ""
        .Forward = True
        .Wrap = wdFindContinue
        .format = False
        .MatchCase = False
        .MatchWholeWord = False
        .MatchWildcards = True
        .MatchSoundsLike = False
        .MatchAllWordForms = False
    End With
    Selection.find.Execute Replace:=wdReplaceAll
End Sub

Sub remove_first_row()
'
' Removes question data export tags from the question info tables in the survey preview
' Called as part of the final cleaning up macro
'
    With ActiveDocument
    
    Dim ntables As Long
    ntables = .Tables.count
    
    For i = 1 To ntables
        ncol = .Tables(i).Columns.count
        
'        Delete first row of the question info (data export tag)
'        This will only appear in question info in the preview; all others have 3+ columns
'        This can be used for appendices to remove first row from coded and full text comments
        
        'delete data export tag
        .Tables(i).Rows(1).Select
        Selection.Rows.Delete
                    

    Next
            
    End With
    
End Sub

Sub renumber_lists()

With ActiveDocument

Dim ntables As Long
Dim nCols As Integer
Dim count As Integer

ntables = .Tables.count
count = 0

For i = 1 To ntables
    nCols = .Tables(i).Columns.count
    .Tables(i).Select
    
    
    If nCols = 1 Then
        With Selection.find
        .Forward = True
        .Wrap = wdFindStop
        .Execute FindText:="^#. ", ReplaceWith:=count & ". ", Replace:=wdReplaceAll
        .format = False
        .MatchCase = False
        .MatchWholeWord = False
        .MatchWildcards = False
        .MatchSoundsLike = False
        .MatchAllWordForms = False
        End With
         
                        
        With Selection.find
        .Forward = True
        .Wrap = wdFindStop
        .Execute FindText:="^#^#. ", ReplaceWith:=count & ". ", Replace:=wdReplaceAll
        .format = False
        .MatchCase = False
        .MatchWholeWord = False
        .MatchWildcards = False
        .MatchSoundsLike = False
        .MatchAllWordForms = False
        End With
        
        
        With Selection.find
        .Forward = True
        .Wrap = wdFindStop
        .Execute FindText:="^#^#^#. ", ReplaceWith:=count & ". ", Replace:=wdReplaceAll
        .format = False
        .MatchCase = False
        .MatchWholeWord = False
        .MatchWildcards = False
        .MatchSoundsLike = False
        .MatchAllWordForms = False
        End With
        
        
        With Selection.find
        .Forward = True
        .Wrap = wdFindStop
        .Execute FindText:="^#^#^#^#. ", ReplaceWith:=count & ". ", Replace:=wdReplaceAll
        .format = False
        .MatchCase = False
        .MatchWholeWord = False
        .MatchWildcards = False
        .MatchSoundsLike = False
        .MatchAllWordForms = False
        End With
        
        count = count + 1
    End If
Next

End With
End Sub

Sub AppendicesNumbering()
With ActiveDocument

Dim ntables As Long
Dim nCols As Integer
Dim count As Integer

ntables = .Tables.count
count = 0

For i = 1 To ntables
    nRows = .Tables(i).Rows.count
    For j = 1 To nRows
        .Tables(i).Rows(j).Select
        
        With Selection.find
          .Text = "See Appendix"
            .Replacement.Text = "See Appendix " + count
            .Forward = True
            .Wrap = wdFindAsk
            .format = False
            .MatchCase = True
            .MatchWholeWord = False
            .MatchWildcards = False
            .MatchSoundsLike = False
            .MatchAllWordForms = False
        End With
        With Selection
            If .find.Forward = True Then
                .Collapse direction:=wdCollapseStart
                count = count + 1
            Else
                .Collapse direction:=wdCollapseEnd
            End If
            .find.Execute Replace:=wdReplaceOne
            If .find.Forward = True Then
                .Collapse direction:=wdCollapseEnd
            Else
                .Collapse direction:=wdCollapseStart
            End If
            .find.Execute
        End With
    Next

Next
End With
End Sub
Sub insert_page_breaks()
'This macro checks to ensure that a table is not split onto two pages
'If it is it will push the entire table on to the next page
'NOT SURE IF THIS CHECKS TO SEE IF THE QUESTION AND RESPONSE ARE ON THE SAME PAGE MIGHT HAVE TO GO BACK AND CHECK


With ActiveDocument
Dim ntables As Long
ntables = .Tables.count

'If for your purpose you need to start in a later point in the document change i = 1 to i = x where x is the table number you want to start at
For i = 1 To ntables
    Dim firstRow As Integer
    Dim lastRow As Integer
    Dim nRows As Integer
    nRows = .Tables(i).Rows.count
    .Tables(i).Rows(1).Select
    firstRow = Selection.Information(wdActiveEndPageNumber)
    .Tables(i).Rows(nRows).Select
    lastRow = Selection.Information(wdActiveEndPageNumber)
    
    If firstRow <> lastRow Then
        Dim nCols As Integer
        nCols = .Tables(i).Columns.count
        If nCols <> 1 Then
            .Tables(i - 1).Select
            Selection.InsertBreak Type:=0
            Else
            .Tables(i).Select
            Selection.InsertBreak Type:=0
        End If
    End If
    
    Next
    
    
End With
End Sub
Sub remove_page_breaks()
'This needs to be run if a table or something was inserted after the insert page breaks macro was run
'Before re running the insert_page_breaks as the entire document will need to be reformatted not just
'The seciton that the insertion changes


With ActiveDocument
Selection.find.ClearFormatting
Selection.find.Replacement.ClearFormatting
With Selection.find
.Text = "^m"
.Replacement.Text = ""
.Forward = True
.Wrap = wdFindContinue
.format = False
.MatchCase = False
.MatchWholeWord = False
.MatchByte = False
.MatchAllWordForms = False
.MatchSoundsLike = False
.MatchWildcards = False
.MatchFuzzy = False
End With
Selection.find.Execute Replace:=wdReplaceAll
End With
End Sub

Sub test_appendix()
'Doesn;t Work But I think its somewhat on the right track maybe?

'{QUOTE
    '{SET A2Z
        '{=MOD(
            '{SEQ ABC}
        '-1,26)+1}
    '}
    '{SET AA2ZZ
            '{=INT((
                '{SEQ ABC \c}
            '-1)/26)}
    '}
    '{IF
        '{AA2ZZ \* ALPHABETIC}
        '= " " ""
        '{AA2ZZ \* ALPHABETIC}
    '}
        '{A2Z \* ALPHABETIC}
'}

ActiveWindow.View.ShowFieldCodes = True

Selection.Fields.Add Range:=Selection.Range, Type:=wdFieldEmpty, _
    preserveFormatting:=False
Selection.TypeText Text:="Set A2Z"
Selection.Fields.Add Range:=Selection.Range, Type:=wdFieldEmpty, _
    preserveFormatting:=False
Selection.TypeText Text:="=MOD("
Selection.Fields.Add Range:=Selection.Range, Type:=wdFieldEmpty, _
    preserveFormatting:=False
Selection.TypeText Text:="SEQ ABC"
'Selection.Fields.Add Range:=Selection.Range, Type:=wdFieldEmpty, _
'    PreserveFormatting:=False
'Selection.TypeText Text:="MERGEFIELD FHB"
Selection.MoveRight Unit:=wdCharacter, count:=2
Selection.TypeText Text:="-1,26)+1"
Selection.MoveRight Unit:=wdCharacter, count:=4
Selection.Fields.Add Range:=Selection.Range, Type:=wdFieldEmpty, _
    preserveFormatting:=False
Selection.TypeText Text:="Set AA2ZZ"
Selection.Fields.Add Range:=Selection.Range, Type:=wdFieldEmpty, _
    preserveFormatting:=False
Selection.TypeText Text:="=INT(("
Selection.Fields.Add Range:=Selection.Range, Type:=wdFieldEmpty, _
    preserveFormatting:=False
Selection.TypeText Text:="SEQ ABC \c"
Selection.MoveRight Unit:=wdCharacter, count:=2
Selection.TypeText Text:="-1)/26)"
Selection.MoveRight Unit:=wdCharacter, count:=4
Selection.Fields.Add Range:=Selection.Range, Type:=wdFieldEmpty, _
    preserveFormatting:=False
Selection.TypeText Text:="IF"
Selection.Fields.Add Range:=Selection.Range, Type:=wdFieldEmpty, _
    preserveFormatting:=False
Selection.TypeText Text:="AA2ZZ \* ALPHABETIC"
Selection.MoveRight Unit:=wdCharacter, count:=2
Selection.TypeText Text:="= """""
Selection.MoveLeft Unit:=wdCharacter, count:=1
Selection.TypeText Text:=" "
Selection.MoveRight Unit:=wdCharacter, count:=2
Selection.TypeText Text:=""""""
Selection.Fields.Add Range:=Selection.Range, Type:=wdFieldEmpty, _
    preserveFormatting:=False
Selection.TypeText Text:="AA2ZZ \* ALPHABETIC"
Selection.MoveRight Unit:=wdCharacter, count:=2
Selection.Fields.Add Range:=Selection.Range, Type:=wdFieldEmpty, _
    preserveFormatting:=False
Selection.TypeText Text:="A2Z \* ALPHABETIC"

'Selection.TypeText Text:="T"
Selection.MoveRight Unit:=wdCharacter, count:=3
Selection.TypeText Text:=", "
Selection.Fields.Add Range:=Selection.Range, Type:=wdFieldEmpty, _
    preserveFormatting:=False
Selection.TypeText Text:="COMPARE "
Selection.Fields.Add Range:=Selection.Range, Type:=wdFieldEmpty, _
    preserveFormatting:=False
Selection.TypeText Text:="MERGEFIELD Other"
Selection.MoveRight Unit:=wdCharacter, count:=2
Selection.TypeText Text:=" <> """""
Selection.MoveLeft Unit:=wdCharacter, count:=1
Selection.TypeText Text:="T"
Selection.MoveRight Unit:=wdCharacter, count:=3
Selection.TypeText Text:=")"
Selection.MoveRight Unit:=wdCharacter, count:=2
Selection.TypeText Text:=" = 1 """""
Selection.MoveLeft Unit:=wdCharacter, count:=1
Selection.TypeText Text:="IfTrue"
Selection.MoveRight Unit:=wdCharacter, count:=1
Selection.TypeText Text:=" """""
Selection.MoveLeft Unit:=wdCharacter, count:=1
Selection.TypeText Text:="IfFalse"

End Sub



Sub reset_page_breaks()

Call remove_page_breaks
Call insert_page_breaks

End Sub



Sub keepTableWithQuestion(i As Integer)

'Dim tbl As Table
'Dim i As Integer
'Dim ntables As Long
Dim questionRange As Range
'ntables = ActiveDocument.Tables.count
'Debug.Print ntables

'For i = 1 To ntables
    
    If ActiveDocument.Tables(i).Columns.count > 1 And i >= 2 Then
'        Dim rng As Variant
'        rng = ActiveDocument.Range(Start:=ActiveDocument.Tables(i - 1).Range.Start, End:=ActiveDocument.Tables(i).Range.End)
'        Debug.Print "Table index: i=" & i
'        Debug.Print "Question: " & rng
'        rng.ParagraphFormat.KeepWithNext = True

        Dim qrng As Range
        Set qrng = ActiveDocument.Tables(i - 1).Range
        qrng.End = ActiveDocument.Tables(i).Range.End
        Debug.Print "Table index: i=" & i
        Debug.Print "Question: " & qrng
        qrng.ParagraphFormat.KeepWithNext = True
        
    End If
'Next

End Sub

