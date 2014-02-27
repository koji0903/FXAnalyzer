Option Explicit
'********************************************************
' 電話帳サンプルソフト
'********************************************************
Private DB As Database
Private Const FILENAME = "c:\Database.mdb"

'********************************************************
' イベントハンドラ
'********************************************************
Private Sub AddButton_Click()
    If (Not AddLogic()) Then Exit Sub
    Call ClearData
End Sub

Private Sub CloseButton_Click()
    Call Unload(Me)
End Sub

Private Sub Form_Load()
    Call ConnectDatabase
    CodeTextBox.Text = ""
    Call ClearData
End Sub

Private Sub Form_Unload(Cancel As Integer)
    Call CloseDatabase
End Sub

Private Sub ReadButton_Click()
    Call ReadLogic
End Sub

Private Sub UpdateButton_Click()
    Call UpdateLogic
End Sub

Private Sub DeleteButton_Click()
    If (Not DeleteLogic()) Then Exit Sub
    Call ClearData
End Sub

'********************************************************
' 名前と電話番号の表示をクリアします
'********************************************************
Private Sub ClearData()
    NameTextBox.Text = ""
    TelephoneNumberTextBox.Text = ""
End Sub

'********************************************************
' エラーメッセージ表示
' ErrorNumber   エラー番号
'********************************************************
Private Sub ShowErrorMessage(ByVal ErrorNumber As Long)
    Call MsgBox( _
        CStr(ErrorNumber) & vbCr & Error$(ErrorNumber))
End Sub

'********************************************************
' Code プロパティ
' Returns:  番号
' Remarks:  CodeTextBox.Text に入力されている値です
'********************************************************
Private Property Get Code() As Long
    Code = Val(CodeTextBox.Text)
End Property

Private Property Let Code(ByVal Value As Long)
    CodeTextBox.Text = CStr(Value)
End Property

'********************************************************
' 追加処理を実行します
' Returns:  結果 [True:成功 / False:失敗]
'********************************************************
Private Function AddLogic() As Boolean
    If (InvalidCode(Code)) Then
        Call MsgBox("追加できませんでした")
        AddLogic = False
        Exit Function
    End If
    
    Call AddRecord(Code)

    AddLogic = True
End Function

'********************************************************
' 更新処理を実行します
' Returns:  結果 [True:成功 / False:失敗]
'********************************************************
Private Function UpdateLogic() As Boolean
    If (InvalidCode(Code)) Then
        Call MsgBox("更新に失敗しました")
        UpdateLogic = False
        Exit Function
    End If
    
    Call UpdateRecord( _
        Code, _
        NameTextBox.Text, _
        TelephoneNumberTextBox.Text)
    
    UpdateLogic = True
End Function

'********************************************************
' 削除処理を実行します
' Returns:  結果 [True:成功 / False:失敗]
'********************************************************
Private Function DeleteLogic() As Boolean
    If (InvalidCode(Code)) Then
        Call MsgBox("削除に失敗しました")
        DeleteLogic = False
        Exit Function
    End If
    
    Call DeleteRecord(Code)
    
    DeleteLogic = True
End Function

'********************************************************
' 読込み処理を実行します
' Returns:  結果 [True:成功 / False:失敗]
'********************************************************
Private Function ReadLogic() As Boolean
    Dim RS As Recordset
    Set RS = ReadRecord(Code)
    If (RS Is Nothing) Then Exit Function
    If (RS.BOF And RS.EOF) Then
        Call MsgBox("登録されていませんでした")
        ReadLogic = False
    Else
        NameTextBox.Text = RS("名前")
        TelephoneNumberTextBox.Text = RS("電話番号")
        ReadLogic = True
    End If
    Call RS.Close
End Function

'********************************************************
' 番号値が有効かどうかを検証した結果を取得します
' Value:    番号の値
' Returns:  結果 [True:無効 / False:有効]
'********************************************************
Private Function InvalidCode( _
    ByVal Value As Long) As Boolean

    If (Value <= 0 Or Value >= 100000000) Then
        Call MsgBox("番号の値が不正です")
        InvalidCode = True
    Else
        InvalidCode = False
    End If
End Function

'********************************************************
' レコードを追加します
' Code:  番号
' Returns:  結果 [True:成功 / False:失敗]
'********************************************************
Private Function AddRecord(ByVal Code As Long) As Boolean
    Dim SqlText As String
    SqlText = GetAddSqlText(Code)
    AddRecord = ExecuteQuery(SqlText)
End Function

'********************************************************
' レコードを更新します
' Code:          番号
' NameValue      名前
' TelephoneNumber   電話番号
' Returns:  結果 [True:成功 / False:失敗]
'********************************************************
Private Function UpdateRecord( _
    ByVal Code As Long, _
    ByVal NameValue As String, _
    ByVal TelephoneNumber As String _
) As Boolean
    Dim SqlText As String
    SqlText = GetUpdateSqlText( _
        Code, NameValue, TelephoneNumber)
    UpdateRecord = ExecuteQuery(SqlText)
End Function

'********************************************************
' レコードを削除します
' Code:  番号
' Returns:  結果 [True:成功 / False:失敗]
'********************************************************
Private Function DeleteRecord(ByVal Code As Long) As Boolean
    Dim SqlText As String
    SqlText = GetDeleteSqlText(Code)
    DeleteRecord = ExecuteQuery(SqlText)
End Function

'********************************************************
' レコードを読み込みます
' Code:  番号
' Returns:  RecordSet オブジェクト
'********************************************************
Private Function ReadRecord( _
    ByVal Code As Long) As Recordset

    Dim Sql As String
    Sql = GetSelectSqlText(Code)

    On Error Resume Next
    Err.Number = 0

    Dim RS As Recordset
    Set RS = DB.OpenRecordset(Sql, dbOpenSnapshot)
    If (Err.Number <> 0) Then
        Call ShowErrorMessage(Err.Number)
    End If
    On Error GoTo 0

    Set ReadRecord = RS
End Function

'********************************************************
' 各 SQL 文字列を取得します
' Code:  番号
' Returns:  SQL 文字列
'********************************************************
Private Function GetSelectSqlText( _
    ByVal Code As Long) As String

    GetSelectSqlText = _
        "SELECT * FROM MyTable " & _
        "WHERE 番号 = " & CStr(Code)
End Function

Private Function GetAddSqlText( _
    ByVal Code As Long) As String

    GetAddSqlText = _
        "INSERT INTO MyTable(番号, 名前, 電話番号) " & _
        "VALUES(" & CStr(Code) & ", '' , '')"
End Function

Private Function GetUpdateSqlText( _
    ByVal Code As Long, _
    ByVal NameValue As String, _
    ByVal TelephoneNumber As String _
) As String
    GetUpdateSqlText = _
        "UPDATE MyTable " & _
        "Set " & _
            "名前 = '" & NameValue & "', " & _
            "電話番号 = '" & TelephoneNumber & "' " & _
        "WHERE 番号 = " & CStr(Code)
End Function

Private Function GetDeleteSqlText( _
    ByVal Code As Long) As String

    GetDeleteSqlText = _
        "DELETE * FROM MyTable " & _
        "WHERE 番号 = " & CStr(Code)
End Function

'********************************************************
' クエリーを実行します
' SqlText:  実行したい SQL 文字列
' Returns:  結果 [True:成功 / False:失敗]
'********************************************************
Private Function ExecuteQuery( _
    ByVal SqlText As String) As Boolean
    
    ExecuteQuery = True
    
    On Error Resume Next
    Err.Number = 0
    Call DB.Execute(SqlText)
    If (Err.Number <> 0) Then
        Call ShowErrorMessage(Err.Number)
        ExecuteQuery = False
    End If
    On Error GoTo 0
End Function

'********************************************************
' データベースへの接続を開始します
'********************************************************
Private Sub ConnectDatabase()
    Set DB = _
        DBEngine.Workspaces(0).OpenDatabase(FILENAME)
End Sub

'********************************************************
' データベースの接続を終了します
'********************************************************
Private Sub CloseDatabase()
    Call DB.Close
End Sub