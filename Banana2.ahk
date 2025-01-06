/************************************************************************
 * @description 바나나 무한 불판 매크로
 * @author Banana-juseyo
 * @date 2024/12/29
 * @version 1.00
 * @see {@link https://github.com/banana-juseyo/Banana-Macro-PtcgP Github Repository}
 * @see {@link https://gall.dcinside.com/m/pokemontcgpocket/ DCinside PtcgP Gallery}
 ***********************************************************************/

; 바나나 무한 불판 매크로 by Banana-juseyo
; 권장 스크린 해상도 : 1920 * 1080
; 권장 플레이어 : mumuplayer
; 권장 인스턴스 해상도 : 540 * 960 (220 dpi)

global _appTitle := "Banana Macro"
global _author := "banana-juseyo"
global _currentVersion := "v1.00"
global _website := "https://github.com/banana-juseyo/Banana-Macro-PtcgP"
global _repoName := "Banana-Macro-PtcgP"

#Requires AutoHotkey v2.0
#Include .\app\WebView2.ahk
#Include .\app\_JXON.ahk
#Include .\app\MatchLibrary.ahk
#Include .\app\ImagePut.ahk

;; 이미지 변수
global _imageFile_friendRequestListCard := A_ScriptDir . "\asset\match\friendRequestListCard.png"
global _imageFile_friendRequestListEmpty := A_ScriptDir . "\asset\match\friendRequestListEmpty.png"
global _imageFile_friendRequestListClearButton := A_ScriptDir . "\asset\match\friendRequestListClearButton.png"
global _imageFile_userDetailEmblem := A_ScriptDir . "\asset\match\userDetailEmblem.png"
global _imageFile_userDetailMybest := A_ScriptDir . "\asset\match\userDetailMybest.png"
global _imageFile_passportPikachu := A_ScriptDir . "\asset\match\passportPikachu.png"
global _imageFile_userDetailAccept := A_ScriptDir . "\asset\match\userDetailAccept.png"
global _imageFile_userDetailDecline := A_ScriptDir . "\asset\match\userDetailDecline.png"
global _imageFile_userDetailRequestFriend := A_ScriptDir . "\asset\match\userDetailRequestFriend.png"
global _imageFile_userDetailFriendNow := A_ScriptDir . "\asset\match\userDetailFriendNow.png"
global _imageFile_userDetailEmpty := A_ScriptDir . "\asset\match\userDetailEmpty.png"
global _imageFile_userDetailRequestNotFound := A_ScriptDir . "\asset\match\userDetailRequestNotFound.png"
global _imageFile_friendMenuButton := A_ScriptDir . "\asset\match\friendsMenuButton.png"
global _imageFile_friendListCard := A_ScriptDir . "\asset\match\friendListCard.png"
global _imageFile_friendListEmpty := A_ScriptDir . "\asset\match\friendListEmpty.png"
global _imageFile_removeFriendConfirm := A_ScriptDir . "\asset\match\removeFriendConfirm.png"
global _imageFile_appIcon := A_ScriptDir . "\asset\image\_app_Icon.png"
global _imageFile_close := A_ScriptDir . "\asset\image\_app_Close.png"
global _imageFile_restart := A_ScriptDir . "\asset\image\_app_Restart.png"

; 전역 변수
global g_IsRunning := FALSE
global _isPausing := FALSE
global _debug := TRUE
global messageQueue := []
global _downloaderGUIWindow := ""
global _configGUIWindow := ""
global g_CurrentLogic := ""
global g_CaseDescription := ""
global g_CurrentResolution := ""
global GuiInstance := {}
global recentText := ""
global RecentTextCtrl := {}
global oldTexts := ""
global g_UserIni := {}
global targetWindowX := ''
global targetWindowY := ''
global targetWindowWidth := ''
global targetWindowHeight := ''
global _thisUserPass := ''
global _thisUserFulfilled := ''
global targetControl := ''
global targetControlX := ''
global targetControlY := ''
global targetControlWidth := ''
global targetControlHeight := ''
global targetControlHeightMargin := ''
global Match := MatchClass()

; 환경값 초기화 & 기본값
global _delayConfig := 150
global _instanceNameConfig := ""
global _acceptingTermConfig := 8 * 60000
global _deletingTermConfig := 2 * 60000

; 로그 파일 설정
global logFile := A_ScriptDir . "\log\" . A_YYYY . A_MM . A_DD . "_" . A_Hour . A_Min . A_Sec . "_" . "log.txt"

;; 디버그용 GUI 정의
global statusGUI := Gui()
statusGUI.Opt("-SysMenu +Caption")
RecentTextCtrl := statusGUI.Add("Text", "x10 y10 w360 h20")
RecentTextCtrl.SetFont("s11", "Segoe UI Emoji, Segoe UI")
OldTextCtrl := statusGUI.Add("Text", "x10 y30 w360 h160")
OldTextCtrl.SetFont("C666666", "Segoe UI Emoji, Segoe UI")
if (_debug == TRUE) {
    statusGUI.Show("")
}
SendDebugMsg('Debug message will be shown here.')

;; 실행 시 업데이트/필수 파일 자동 다운로드 로직
DownloaderInstance := Downloader()
;; msedge.dll 파일 확인
DownloaderInstance.CheckMsedgeDLL()
;; 스크립트 업데이트 확인
; 임시 폴더의 업데이트 스크립트 삭제
updateScriptPath := A_Temp "\updater.ahk"
if FileExist(updateScriptPath)
    FileDelete(updateScriptPath)
; 스크립트 업데이트 실행
; DownloaderInstance.CheckForUpdates()

class Downloader {
    gui := ""
    ProgressBar := {}
    TextCtrl := {}
    Http := {}
    _progress := 0

    __New() {
        if (_downloaderGUIWindow && WinExist(_downloaderGUIWindow)) {
            WinActivate(_downloaderGUIWindow)
            this.gui := GuiFromHwnd(_downloaderGUIWindow)
        }
    }

    ; 다운로더 GUI 호출
    OpenDownloaderGUI() {
        global _downloaderGUIWindow
        global ProgressBar, TextCtrl

        _gui := GUI()
        _downloaderGUIWindow := _gui.hwnd
        _gui.Opt("-SysMenu -Caption")
        _gui.Title := "자동 업데이트"

        TextCtrl := _gui.Add("Text", "x10 y10 w300", "파일 상태 확인 중...")
        ProgressBar := _gui.Add("Progress", "x10 y40 w300 h20")

        _gui.Show()
        this.gui := _gui
        return _gui
    }

    Dismiss() {
        if (WinActive(_downloaderGUIWindow)) {
            This.gui.Destroy()
            return
        }
    }

    ; 파일 업데이트 체크
    CheckMsedgeDLL() {
        ; 경로 표현 시 \ (백슬래시) 대신 / (슬래시) 사용
        _msedgeProjectPath := "/app/msedge.dll"
        _fullpath := A_ScriptDir . _msedgeProjectPath

        if (FileExist(_fullpath) && FileGetSize(_fullpath) >= 283108904) {
            SendDebugMsg("업데이트할 파일이 없습니다.")
        } else {
            FileInfo := DownloaderInstance.GetRepoApi(_msedgeProjectPath)
            if (FileInfo["isAvailable"]) {
                d := DownloaderInstance.Download(FileInfo, _fullpath)
            } else {
                MsgBox("138::파일 업데이트에 실패했습니다.")
            }
            if (d) {
                if (WinActive(DownloaderInstance.gui.hwnd)) {
                    DownloaderInstance.gui.Destroy()
                }
            }
            else {
                MsgBox("146::파일 다운로드에 실패했습니다.")
            }
        }
    }

    ; 파일 다운로드 실행
    Download(FileInfo, _fullPath) {
        global TextCtrl
        global _progress

        url := FileInfo["downloadUrl"]
        fileName := FileInfo["fileName"]
        destination := FileInfo["destination"]
        size := FileInfo["size"]

        ; 다운로더 GUI 열기
        DownloaderInstance.OpenDownloaderGUI()

        ; 파일 확인
        if FileExist(_fullPath) {
            FileDelete(_fullPath)
        }
        try {
            TextCtrl.Text := "다운로드 중 : " fileName
            SetTimer(() => This.UpdateDownloadProgress(_fullPath, size), 100)
            Download(url, _fullPath)

            if (FileGetSize(_fullPath) >= size) {
                global TextCtrl
                TextCtrl.Text := ("다운로드 완료")
                Sleep(1000)
                return TRUE
            }
            return TRUE
        }
        catch Error as e {
            MsgBox "[Download]`n다운로드 중 오류가 발생했습니다.`n" e.Message
            Reload
        }
    }

    ; 다운로드 진행에 따라 progress 업데이트
    UpdateDownloadProgress(_fullPath, _fullSize) {
        global ProgressBar, _progress
        try {
            _currentSize := FileGetSize(_fullPath)
            _progress := Floor((_currentSize / _fullSize) * 100) ; 진행률 계산

            ProgressBar.Value := _progress

            if (_currentSize >= _fullSize) {
                _progress := 100
                SetTimer(this.UpdateDownloadProgress, 0)
                return
            }
        }
        catch Error as e {
            MsgBox ("[UpdateDownloadProgress]`n파일 다운로드 중 오류가 발생했습니다.`n" e.Message)
            Reload
        }
    }

    ; Repo Api에서 파일 조회 -> obj
    GetRepoApi(ProjectFilePath) {
        i := InStr(ProjectFilePath, "/", , -1)
        Path := SubStr(ProjectFilePath, 1, i - 1)
        FileName := SubStr(ProjectFilePath, i + 1)
        if (ProjectFilePath == "/app/msedge.dll") {
            url := "https://api.github.com/repos/banana-juseyo/Banana-Macro-PtcgP/contents/app/msedge.dll"
            try {
                http := ComObject("WinHttp.WinHttpRequest.5.1")
                http.Open("GET", url, TRUE)
                http.Send()
                http.WaitForResponse()
                response := http.ResponseText
                ; responsStr := Jxon_Dump(response)
                responseMap := Jxon_Load(&response)
                if (responseMap["name"] == "msedge.dll") {
                    return Map(
                        "isAvailable", TRUE,
                        "fileName", responseMap["name"],
                        "destination", A_ScriptDir . Path . "/",
                        "fullPath", A_ScriptDir . Path . "/" . responseMap["name"],
                        "downloadUrl", responseMap["download_url"],
                        "size", responseMap["size"]
                    )
                } else {
                    return Map("isAvailable", FALSE)
                }
            }
            catch Error as e {
                MsgBox "패키지 파일 확인 중 오류가 발생했습니다: " e.Message
                return Map("isAvailable", false)
            }
        } else {
            url := "https://api.github.com/repos/banana-juseyo/" . _repoName . "/contents" . Path
            try {
                http := ComObject("WinHttp.WinHttpRequest.5.1")
                http.Open("GET", url, TRUE)
                http.Send()
                http.WaitForResponse()
                response := http.ResponseText
                ; responsStr := Jxon_Dump(response)
                responseMap := Jxon_Load(&response)
                for key, file in responseMap {
                    if (file["name"] = FileName) {
                        return Map(
                            "isAvailable", TRUE,
                            "fileName", FileName,
                            "destination", A_ScriptDir . Path . "/",
                            "fullPath", A_ScriptDir . Path . "/" . FileName,
                            "downloadUrl", file["download_url"],
                            "size", file["size"]
                        )
                    }
                }
                return Map("isAvailable", FALSE)
            }
            catch Error as e {
                MsgBox "패키지 파일 확인 중 오류가 발생했습니다: " e.Message
                return Map("isAvailable", false)
            }
        }
    }

    ; 스크립트 최신 버전 확인
    CheckForUpdates() {
        url := "https://api.github.com/repos/banana-juseyo/Banana-Macro-PtcgP/releases/latest"
        try {
            http := ComObject("WinHttp.WinHttpRequest.5.1")
            http.Open("GET", url, true)
            http.Send()
            http.WaitForResponse()

            response := http.ResponseText
            response := Jxon_Load(&response)
            ; 버전 비교
            latestVersion := response["tag_name"]
            if (latestVersion != _currentVersion) {
                ; 업데이트가 필요한 경우
                fileInfo := Map(
                    "isAvailable", TRUE,
                    "fileName", response["assets"][1]["name"],
                    "destination", tempFile := A_Temp,
                    "fullPath", tempFile := A_Temp "\" A_ScriptName ".new",
                    "downloadUrl", response["assets"][1]["browser_download_url"],
                    "size", response["assets"][1]["size"]
                )
                return this.PerformUpdate(fileInfo)
            }
            ; 업데이트가 필요하지 않은 경우
            return true
        }
        catch Error as e {
            MsgBox "311::업데이트 확인 중 오류가 발생했습니다: " e.Message
            return false
        }
    }

    ; 업데이트 실행
    PerformUpdate(FileInfo) {
        downloadUrl := FileInfo["downloadUrl"]
        try {
            _fullpath := FileInfo["fullPath"]
            FileAppend("", _fullpath)
            backupFile := A_ScriptFullPath ".backup"
            ; 새 버전 다운로드
            ; Download(downloadUrl, tempFile)
            d := DownloaderInstance.Download(FileInfo, _fullpath)
            ; 현재 스크립트 백업
            if FileExist(backupFile)
                FileDelete(backupFile)
            FileCopy(A_ScriptFullPath, backupFile)
            ; 업데이트 스크립트 파일 생성
            updateScriptPath := this.CreateUpdateScript(_fullpath)
            ; 업데이트 스크립트 실행 후 현재 스크립트 종료
            Run(updateScriptPath)
            ExitApp

            return true
        }
        catch Error as e {
            MsgBox "342::업데이트 설치 중 오류가 발생했습니다: " e.Message
            return false
        }
    }

    CreateUpdateScript(tempFile) {
        ; 외부에서 업데이트를 수행할 새로운 AHK 업데이트 스크립트 생성
        updateScript := '#Requires AutoHotkey v2.0`n'
        updateScript .= 'Sleep(2000)`n'
        updateScript .= 'originalFile := "' A_ScriptFullPath '"`n'
        updateScript .= 'newFile := "' tempFile '"`n'
        updateScript .= '`n'
        updateScript .= 'try {`n'
        updateScript .= 'if FileExist(originalFile)`n'
        updateScript .= 'FileDelete(originalFile)`n'
        updateScript .= 'FileMove(newFile, originalFile)`n'
        updateScript .= 'Run(originalFile)`n'
        updateScript .= '} Catch Error as e {`n'
        updateScript .= 'MsgBox("Error While Update: " . e.Message)`n'
        updateScript .= '}`n'
        updateScript .= 'ExitApp'

        ; 업데이트 스크립트 임시 파일 생성
        updateScriptPath := A_Temp "\updater.ahk"
        if FileExist(updateScriptPath)
            FileDelete(updateScriptPath)

        FileAppend(updateScript, updateScriptPath)
        return updateScriptPath
    }
}

;; 메인 UI 정의
d := 1.25
width := Round(560 * d)
height := Round(432 * d)
radius := Round(8 * d)

ui := Gui("-SysMenu -Caption +LastFound")
ui.OnEvent('Close', (*) => ExitApp())

hIcon := LoadPicture(".\asset\image\app.ico", "Icon1 w" 32 " h" 32, &imgtype)
SendMessage(0x0080, 1, hIcon, ui)

dpiScale := A_ScreenDPI / 96
calculatedWidth := 560 * dpiScale
calculatedHeigth := 432 * dpiScale

ui.Show("w" calculatedWidth " h" calculatedHeigth)
g_UiWindow := WinGetID(A_ScriptName, , "Code",)
WinSetTitle _appTitle . " " . _currentVersion, g_UiWindow
WinSetRegion Format("0-0 w{1} h{2} r{3}-{3}", calculatedWidth, calculatedHeigth, radius), g_UiWindow

;; 메인 UI 생성 (웹뷰2)
wvc := WebView2.CreateControllerAsync(ui.Hwnd, { AdditionalBrowserArguments: "--enable-features=msWebView2EnableDraggableRegions" })
.await2()
wv := wvc.CoreWebView2
nwr := wv.NewWindowRequested(NewWindowRequestedHandler)
uiHtmlPath := A_ScriptDir . "\asset\html\index.html"
wv.Navigate("file:///" . StrReplace(uiHtmlPath, "\", "/"))

NewWindowRequestedHandler(wv2, arg) {
    deferral := arg.GetDeferral()
    arg.NewWindow := wv2
    deferral.Complete()
}

;; 메인 UI에서 넘어오는 값을 확인하는 리스너 -> Loop 중 함수로 넘기면 실행이 안됨 (우선순위 이슈)
nwr := wv.WebMessageReceived(HandleWebMessageReceived)
HandleWebMessageReceived(sender, args) {
    global _isPausing, _configGUIWindow, GuiInstance

    message := args.TryGetWebMessageAsString()
    switch message {
        case "_button_click_header_home":
            Run _website
            return
        case "_button_click_header_restart":
            FinishRun()
            Reload
            return
        case "_button_click_header_quit":
            ExitApp
            return
        case "_button_click_footer_start":
            SetTimer(() => StartRun("00"), -1)
            return
        case "_button_click_footer_clear_friends":
            SetTimer(() => StartRun("D00"), -1)
            return
        case "_button_click_footer_pause":
            TogglePauseMode()
            Pause -1
            if (_isPausing) {
                SendUiMsg("⏸️ 일시 정지")
            }
            else if ( NOT _isPausing) {
                SendUiMsg("▶️ 재개")
            }
            return
        case "_button_click_footer_stop":
            FinishRun()
            return
        case "_button_click_footer_settings":
            GuiInstance := ConfigGUI()
            return
        case "_click_github_link":
            Run _website
            return
    }
}

;; 환경 설정 관련 로직 시작
; 환경 설정 불러오기
g_UserIni := ReadUserIni()

; 환경 설정 GUI 커스텀 클래스
class ConfigGUI {
    gui := ""

    __New() {
        if (_configGUIWindow && WinExist(_configGUIWindow)) {
            WinActivate(_configGUIWindow)
            this.gui := GuiFromHwnd(_configGUIWindow)
        }
        else {
            this.gui := OpenConfigGUI()
        }
    }

    Submit() {
        global g_UserIni
        g_UserIni := this.gui.Submit(TRUE)
        UpdateUserIni(g_UserIni)
        this.gui.Destroy()
        return
    }

    Dismiss() {
        if (WinActive(_configGUIWindow)) {
            this.gui.Destroy()
            return
        }
    }
}

;; 환경값 재설정
_delayConfig := g_UserIni.Delay
_instanceNameConfig := g_UserIni.InstanceName
_acceptingTermConfig := g_UserIni.AcceptingTerm * 60000
_deletingTermConfig := g_UserIni.BufferTerm * 60000
_displayResolutionConfig := g_UserIni.DisplayResolution

; 환경설정 GUI 정의
OpenConfigGUI() {
    global _configGUIWindow

    _gui := GUI()
    _configGUIWindow := _gui.hwnd
    _gui.Opt("-SysMenu +LastFound +Owner" ui.Hwnd)
    _gui.Title := "환경 설정"
    _gui.BackColor := "DADCDE"
    _defaultValue := ""

    section := { x1: 30, y1: 30 }
    _confInstanceNameTitle := _gui.Add("Text", Format("x{} y{} w100 h30", section.x1, section.y1 + 5),
    "인스턴스 이름")
    _confInstanceNameTitle.SetFont("q5  s10 w600")
    _redDotText := _gui.Add("Text", Format("x{} y{} w10 h30", section.x1 + 140, section.y1 + 3),
    "*")
    _redDotText.SetFont("q5 s11 w600 cF65E3C")
    _confInstanceNameField := _gui.Add("Edit", Format("x{} y{} w280 h26 -VScroll Background", section.x1 + 140,
        section.y1), g_UserIni.InstanceName)
    _confInstanceNameField.SetFont("q5  s13")
    _confInstanceNameField.name := "InstanceName"
    _confInstanceNameHint := _gui.Add("Text", Format("x{} y{} w360 h24", section.x1 + 140, section.y1 + 36),
    "불판이 가동중인 뮤뮤 플레이어 인스턴스 이름을 정확하게 입력해 주세요.")
    _confInstanceNameHint.SetFont("q5  s8 c636363")

    switch g_UserIni.DisplayResolution {
        global _defaultValue
        case "FHD": _defaultValue := "Choose1"
        case "QHD": _defaultValue := "Choose2"
        case "4K": _defaultValue := "Choose3"
    }

    section := { x1: 30, y1: 100, default: _defaultValue }
    _confDisplayResolutionTitle := _gui.Add("Text", Format("x{} y{} w100 h30", section.x1, section.y1 + 5),
    "디스플레이`n해상도"
    )
    _confDisplayResolutionTitle.SetFont("q5 s10 w600")
    _confDisplayResolutionField := _gui.Add("DropDownList", Format("x{} y{} w160 {}", section.x1 + 140,
        section.y1, section.default), ["FHD (125%)", "QHD (150%)", "4K (200%)"])
    _confDisplayResolutionField.SetFont("q5  s13")
    _confDisplayResolutionField.name := "DisplayResolution"
    _confDisplayResolutionHint := _gui.Add("Text", Format("x{} y{} w360 h24", section.x1 + 140, section.y1 + 30),
    "현재 디스플레이의 해상도를 선택해 주세요.`n해상도를 변경한 경우 뮤뮤 플레이어를 재시작해야 정상적으로 동작합니다.")
    _confDisplayResolutionHint.SetFont("q5  s8 c636363")

    switch g_UserIni.Delay {
        global _defaultValue
        case "150": _defaultValue := "Choose1"
        case "250": _defaultValue := "Choose2"
        case "350": _defaultValue := "Choose3"
    }
    section := { x1: 30, y1: 170, default: _defaultValue }
    _confDelayTitle := _gui.Add("Text", Format("x{} y{} w100 h30", section.x1, section.y1 + 5), "딜레이`n(ms)"
    )
    _confDelayTitle.SetFont("q5 s10 w600")
    _confDelayField := _gui.Add("DropDownList", Format("x{} y{} w100 {}", section.x1 + 140,
        section.y1, section.default), [150, 250, 350])
    _confDelayField.SetFont("q5  s13")
    _confDelayField.name := "Delay"
    _confDelayHint := _gui.Add("Text", Format("x{} y{} w360 h24", section.x1 + 140, section.y1 + 30),
    "앱의 전반에 걸쳐 지연 시간을 설정합니다.`n값이 커지면 속도는 느려지지만 오류 확률이 줄어듭니다.")
    _confDelayHint.SetFont("q5  s8 c636363")

    switch g_UserIni.AcceptingTerm {
        global _defaultValue
        case 6: _defaultValue := "Choose1"
        case 8: _defaultValue := "Choose2"
        case 10: _defaultValue := "Choose3"
        case 12: _defaultValue := "Choose4"
    }
    section := { x1: 30, y1: 240, default: _defaultValue }
    _confAcceptingTermTitle := _gui.Add("Text", Format("x{} y{} w100 h30", section.x1, section.y1 + 5),
    "친구 수락 시간`n(분)")
    _confAcceptingTermTitle.SetFont("q5  s10 w600")
    _confAcceptingTermField := _gui.Add("DropDownList", Format("x{} y{} w100 {}", section.x1 + 140,
        section.y1, section.default), [6, 8, 10, 12])
    _confAcceptingTermField.SetFont("q5  s13")
    _confAcceptingTermField.name := "AcceptingTerm"
    _confAcceptingTermHint := _gui.Add("Text", Format("x{} y{} w360 h24", section.x1 + 140, section.y1 + 30
    ),
    "친구 수락 단계의 시간을 설정합니다.`n평균적으로 1분당 8명 정도의 수락을 받을 수 있습니다.")
    _confAcceptingTermHint.SetFont("q5  s8 c636363")

    switch g_UserIni.BufferTerm {
        global _defaultValue
        case 2: _defaultValue := "Choose1"
        case 3: _defaultValue := "Choose2"
        case 4: _defaultValue := "Choose3"
    }
    section := { x1: 30, y1: 310, default: _defaultValue }
    _confBufferTermTitle := _gui.Add("Text", Format("x{} y{} w100 h30", section.x1, section.y1 + 5),
    "삭제 유예 시간`n(분)")
    _confBufferTermTitle.SetFont("q5  s10 w600")
    _confBufferTermField := _gui.Add("DropDownList", Format("x{} y{} w100 {}", section.x1 + 140, section.y1,
        section.default
    ), [2, 3, 4])
    _confBufferTermField.SetFont("q5  s13")
    _confBufferTermField.name := "BufferTerm"
    _confBufferTermHint := _gui.Add("Text", Format("x{} y{} w360 h24", section.x1 + 140, section.y1 + 30),
    "친구 수락을 완료한 뒤, 친구 삭제까지의 유예 시간을 설정합니다.")
    _confBufferTermHint.SetFont("q5  s8 c636363")

    section := { x1: 30, y1: 380 }
    _confirmButton := _gui.Add("Button", Format("x{} y{} w100 h40 BackgroundDADCDE", section.x1 + 76,
        section.y1
    ), "저장")
    _confirmButton.SetFont("q5  w600")
    _confirmButton.OnEvent("Click", Submit)
    _cancleButton := _gui.Add("Button", Format("x{} y{} w100 h40 BackgroundDADCDE", section.x1 + 200,
        section.y1
    ), "취소")
    _cancleButton.SetFont("q5  w600")
    _cancleButton.OnEvent("Click", Dismiss)

    _gui.Show("")
    _gui.Move(528, 205, 560, 480)

    return _gui

    Submit(*) {
        global g_UserIni
        g_UserIni := _gui.Submit(TRUE)
        switch _confDisplayResolutionField.Value {
            case 1: g_UserIni.DisplayResolution := "FHD"
            case 2: g_UserIni.DisplayResolution := "QHD"
            case 3: g_UserIni.DisplayResolution := "4K"
        }
        UpdateUserIni(g_UserIni)
        _gui.Destroy()
        return
    }
    Dismiss(*) {
        if (WinActive(_gui.Hwnd)) {
            _gui.Destroy()
            return
        }
    }
}

F5:: {
    SetTimer(() => StartRun("00"), -1)
}
F6:: {
    SetTimer(() => StartRun("D00"), -1)
}
F7:: {
    TogglePauseMode()
    Pause -1
    if (_isPausing) {
        SendUiMsg("⏸️ 일시 정지")
    }
    else if ( NOT _isPausing) {
        SendUiMsg("▶️ 재개")
    }
    return
}
F8:: {
    SetTimer(() => FinishRun(), -1)
    Reload
}

^R:: {
    SetTimer(() => FinishRun(), -1)
    Reload
}

#HotIf WinActive(_configGUIWindow)
~Enter:: {
    _gui := GuiFromHwnd(_configGUIWindow)
    GuiInstance.Submit()
}
~Esc:: {
    GuiInstance.Dismiss()
}

SendUiMsg("포켓몬 카드 게임 포켓 갤러리")
SendUiMsg(" ")
SendUiMsg("바나나 무한 불판 매크로 " _currentVersion " by banana-juseyo")
SendUiMsg(" ")
SendUiMsg("매크로 초기화 완료")

class MatchClass {
    _matchedX := 0
    _matchedY := 0

    __New() {
    }

    MatchImage(itemName) {
        item := MatchLibrary[itemName]

        r := ImageSearch(
            &matchedX
            , &matchedY
            , getScreenXbyWindowPercentage(item.rangeX1)
            , getScreenYbyWindowPercentage(item.rangeY1)
            , getScreenXbyWindowPercentage(item.rangeX2)
            , getScreenYbyWindowPercentage(item.rangeY2)
            , '*' item.matchTolerance ' ' . item.matchImage[g_CurrentResolution])
        if r {
            this._matchedX := matchedX
            this._matchedY := matchedY
        }
        return r
    }

}

;; 메인 함수 선언
Main() {
    ; 전역 변수 초기화
    global Match
    global g_CurrentLogic
    global g_CaseDescription
    global g_IsRunning
    global targetWindow
    global GuiInstance
    global g_CurrentResolution := g_UserIni.DisplayResolution
    global _instanceNameConfig := g_UserIni.InstanceName

    global targetWindowX, targetWindowY, targetWindowWidth, targetWindowHeight, _thisUserPass, _thisUserFulfilled
    global targetControlX, targetControlY, targetControlWidth, targetControlHeight, targetControlHeightMargin
    global _recentTick, _currentTick
    global failCount
    global _nowAccepting

    g_IsRunning := TRUE
    _nowAccepting := TRUE
    _thisUserPass := FALSE
    _thisUserFulfilled := FALSE
    _recentTick := A_TickCount
    _currentTick := A_TickCount

    SetTitleMatchMode 3

    if ( NOT _instanceNameConfig) {
        GuiInstance := ConfigGUI()
        SendUiMsg("[오류] 인스턴스 이름이 입력되지 않았습니다.")
        SetTimer(() => FinishRun(), -1)
        return
    }
    if ( NOT WinExist(_instanceNameConfig)) {
        GuiInstance := ConfigGUI()
        SendUiMsg("[오류] 입력한 이름의 인스턴스를 찾을 수 없습니다.")
        SetTimer(() => FinishRun(), -1)
        return
    }

    targetWindow := WinExist(_instanceNameConfig)
    if ( NOT targetWindow) {
        SendUiMsg("[오류] 입력한 인스턴스에서 PtcgP 앱을 확인할 수 없습니다 : " _instanceNameConfig)
        SetTimer(() => FinishRun(), -1)
        return
    }
    else if targetWindow {
        WinGetPos(&targetWindowX, &targetWindowY, &targetWindowWidth, &targetWindowHeight, targetWindow)
        targetControl := ControlGetHwnd('nemuwin1', targetWindow)
        ControlGetPos(&targetControlX, &targetControlY, &targetControlWidth, &targetControlHeight, targetControl)
        targetControlHeightMargin := targetWindowHeight - targetControlHeight
    }

    if (g_CurrentResolution == "fhd") {
        WinMove(, , 403, 970, targetWindow)
    }
    WinActivate (targetWindow)
    CoordMode("Pixel", "Screen")

    loop {
        if (!g_IsRunning) {
            break
        }
        ; 타겟 윈도우 재설정
        ; 타겟 윈도우의 크기를 동적으로 반영하기 위해 루프 속에서 실행
        WinGetPos(&targetWindowX, &targetWindowY, &targetWindowWidth, &targetWindowHeight, targetWindow)

        switch g_CurrentLogic {

            ; 00. 화면 초기화
            case "00":
                ;; 환경값 재설정
                _delayConfig := g_UserIni.Delay
                _instanceNameConfig := g_UserIni.InstanceName
                _acceptingTermConfig := g_UserIni.AcceptingTerm * 60000
                _deletingTermConfig := g_UserIni.BufferTerm * 60000

                SendUiMsg("✅ 친구 추가부터 시작")
                g_CaseDescription := '화면 초기화'
                LogicStartLog()
                InitLocation('RequestList')
                g_CurrentLogic := "1-01"
                static globalRetryCount := 0
                failCount := 0

                ; 01. 친구 추가 확인
            case "1-01":
                g_CaseDescription := '신청 확인'
                LogicStartLog()

                elapsedTime := _getElapsedTime()
                PhaseToggler(elapsedTime)

                if (_nowAccepting = FALSE) {
                    g_CurrentLogic := "D00"
                    SendUiMsg("[페이즈 전환] 수락을 중단합니다. " . Round(_deletingTermConfig / 60000) . "분 후 친구 삭제 시작.")
                    globalRetryCount := 0
                    Sleep(_deletingTermConfig)
                    continue
                }
                if (failCount >= 5) {
                    globalRetryCount := globalRetryCount + 1
                    if (globalRetryCount > 5) {
                        SendUiMsg("[심각] 반복적인 화면 인식 실패. 프로그램을 종료합니다.")
                        ExitApp
                    }
                    SendUiMsg("[오류] 신청 목록 확인 실패. 화면을 초기화 합니다.")
                    InitLocation('RequestList')
                    g_CurrentLogic := "1-01"
                    failCount := 0
                    delayShort()
                    continue
                }

                if (_nowAccepting == TRUE && g_CurrentLogic == "1-01") {
                    xy := MatchObject("FriendRequestListCard")
                    if xy {
                        Click(xy)
                        delayLong()
                        TryLogicTransition('1-02')
                        continue
                    }
                    else {
                        failCount := failCount + 1
                        delayShort()
                        continue
                    }

                    ; // 신청화면에서 각종 예외 케이스 처리 -> fail count 합쳐야
                    else if (match == 0) {
                        xy := MatchObject("FriendRequestListEmpty")
                        if xy {
                            SendUiMsg("[안내] 잔여 신청 목록이 없습니다. 10초 후 새로고침.")
                            sleep(10000) ; 10초 중단
                            InitLocation('RequestList')
                            globalRetryCount := 0
                        }
                        else if (match == 0) { ; // 신청 목록 확인 실패, 일시적인 오류일 수 있어 failCount로 처리
                            failCount := failCount + 1
                            delayLong()
                        }
                    }
                    if (failCount >= 5) {
                        ; 잔여 신청 목록이 0인지 체크
                        match := ImageSearch(
                            &matchedX
                            , &matchedY
                            , getScreenXbyWindowPercentage('20%')
                            , getScreenYbyWindowPercentage('45%')
                            , getScreenXbyWindowPercentage('80%')
                            , getScreenYbyWindowPercentage('55%')
                            , '*50 ' . _imageFile_friendRequestListEmpty)
                        if (match == 1) {
                            SendUiMsg("[안내] 잔여 신청 목록이 없습니다. 10초 후 새로고침.")
                            g_CurrentLogic := "1-01"
                            failCount := 0
                            sleep(10000) ; 10초 중단
                            InitLocation('RequestList')
                        }
                        else if (match == 0) {
                            SendUiMsg("[오류] 유저 화면 진입 실패. 화면을 초기화 합니다.")
                            g_CurrentLogic := "1-01"
                            failCount := 0
                            InitLocation('RequestList')
                        }
                    }

                    case "1-02": ; // 1-02 유저 디테일 - 예외 케이스 확인 및 마이 베스트 확인
                        g_CaseDescription := '유저 화면 진입'
                        LogicStartLog()
                        ; // failcount 먼저 체크
                        if (failCount >= 5) {
                            SendUiMsg("[오류] 마이 베스트 진입 불가")
                            _clickCloseModalButton()
                            g_CurrentLogic := "1-01"
                            failCount := 0
                            delayShort()
                            continue
                        }
                        ; // 마이 베스트 설정 1 (엠블럼 O)
                        xy := MatchObject("UserDetailMybestButton1")
                        if xy {
                            Click(xy)
                            delayShort()
                            Click(xy)
                            delayShort()
                            g_CurrentLogic := '1-03'
                            failCount := 0
                            continue
                        }
                        ; // 마이 베스트 설정 2 (엠블럼 X)
                        xy := MatchObject("UserDetailMybestButton2")
                        if xy {
                            Click(xy)
                            delayShort()
                            Click(xy)
                            delayShort()
                            g_CurrentLogic := '1-03'
                            failCount := 0
                            continue
                        }
                        ; // 유저가 신청 취소한 경우
                        xy := MatchObject("UserDetailRequestFriend")
                        if xy {
                            SendUiMsg("[예외] 유저의 신청 취소")
                            _clickCloseModalButton()
                            g_CurrentLogic := "1-01"
                            failCount := 0
                            delayShort()
                            continue
                        }
                        ; // 마이 베스트 미설정 1 (엠블럼 O)
                        xy := MatchObject("UserDetailEmpty1")
                        if xy {
                            SendUiMsg("[예외] 마이 베스트 미설정")
                            SendUiMsg("❌ 입국 거절")
                            _clickCloseModalButton()
                            g_CurrentLogic := "1-01"
                            failCount := 0
                            delayShort()
                            continue
                        }
                        ; // 마이 베스트 미설정 2 (엠블럼 X)
                        xy := MatchObject("UserDetailEmpty2")
                        if xy {
                            SendUiMsg("[예외] 마이 베스트 미설정")
                            SendUiMsg("❌ 입국 거절")
                            _clickCloseModalButton()
                            g_CurrentLogic := "1-01"
                            failCount := 0
                            delayShort()
                            continue
                        }
                        failCount := failCount + 1
                        SendUiMsg("[안내] 마이베스트 진입 재시도")
                        delayShort()
                        continue

                        ; 1-03 입국 심사 / 여권 확인
                    case "1-03":
                        g_CaseDescription := '입국 심사 : 여권 확인'
                        LogicStartLog()
                        ; // failcount 먼저 체크
                        if (failCount >= 5) {
                            _thisUserPass := FALSE
                            _thisUserFulfilled := FALSE
                            SendUiMsg("❌ 입국 거절")
                            _clickCloseModalButton()
                            TryLogicTransition('1-06')
                            continue
                        }
                        ; // 여권 체크
                        xy := MatchObject('PassportPikachu')
                        if xy {
                            _thisUserPass := TRUE
                            _thisUserFulfilled := FALSE
                            SendUiMsg("✅ 입국 심사 통과")
                            _clickCloseModalButton()
                            TryLogicTransition('1-04')
                            continue
                        }
                        else {
                            SendUiMsg("[여권 미확인] 잠시 후 재시도 ")
                            failCount := failCount + 1
                            delayLong()
                            continue
                        }

                    case "1-04":
                        g_CaseDescription := '유저 화면 : 승인 처리'
                        LogicStartLog()
                        ; // failcount 먼저 체크
                        if (failCount >= 5) {
                            SendUiMsg("[오류] 승인 처리 불가")
                            _clickCloseModalButton()
                            g_CurrentLogic := "1-01"
                            failCount := 0
                            delayShort()
                            continue
                        }
                        ; // 승인 버튼 클릭
                        xy := MatchObject("UserDetailAccept")
                        if xy {
                            Click(xy)
                            r := TryLogicTransition('1-05')
                            if r {
                                SendUiMsg("승인 처리 완료")
                            }
                            continue
                        }
                        else {
                            failCount := failCount + 1
                            continue
                        }
                    case "1-05":
                        g_CaseDescription := '심사 승인 처리, 결과 확인'
                        LogicStartLog()

                        if (_thisUserPass == TRUE && _thisUserFulfilled == FALSE) {
                            match := ImageSearch(
                                &matchedX
                                , &matchedY
                                , getScreenXbyWindowPercentage('12%')
                                , getScreenYbyWindowPercentage('70%')
                                , getScreenXbyWindowPercentage('88%')
                                , getScreenYbyWindowPercentage('77%')
                                , '*50 ' . _imageFile_userDetailAccept)
                            ; _statusMsg("[match] = " . match)
                            if (match == 1) {
                                targetX := xy[1] - targetWindowX + 10
                                targetY := xy[2] - targetWindowY + 10
                                ; _statusMsg("[클릭]`ntargetX : " . targetX . "`ntargetY : " . targetY)
                                ControlClick('X' . targetX . ' Y' . targetY, targetWindow, , 'Left', 1, 'NA', ,)
                                _thisUserFulfilled := TRUE
                                delayLong() ; // 닌텐도 서버 이슈로 로딩 발생
                            }
                            else if (match == 0) {
                                failCount := failCount + 1
                                ControlClick(targetControl, targetWindow, , 'WU', 3, 'NA', ,) ;

                                ; 재시도 후 failsafe, 해당 유저의 신청 포기 처리, 현재 case 정보 로그 남기기
                                match := ImageSearch(
                                    &matchedX,
                                    &matchedY,
                                    getScreenXbyWindowPercentage('12%'),
                                    getScreenYbyWindowPercentage('70%'),
                                    getScreenXbyWindowPercentage('88%'),
                                    getScreenYbyWindowPercentage('77%'),
                                    '*50 ' . _imageFile_userDetailRequestFriend)
                                if (match == 1) {
                                    SendUiMsg("[오류] 유저의 신청 취소")
                                    _clickCloseModalButton()
                                    _thisUserFulfilled := TRUE
                                    g_CurrentLogic := "1-01"
                                }
                                else if (match == 0) {
                                    delayShort()
                                }
                            }
                            if (failCount >= 5) {
                                SendUiMsg("[오류] 승인 불가")
                                _clickCloseModalButton()
                                g_CurrentLogic := "1-01"
                                failCount := 0
                                delayShort()
                            }

                        }
                        if (_thisUserPass == FALSE && _thisUserFulfilled == FALSE) {
                            match := ImageSearch(
                                &matchedX
                                , &matchedY
                                , getScreenXbyWindowPercentage('12%')
                                , getScreenYbyWindowPercentage('70%')
                                , getScreenXbyWindowPercentage('88%')
                                , getScreenYbyWindowPercentage('77%')
                                , '*50 ' . _imageFile_userDetailDecline)
                            if (match == 1) {
                                targetX := xy[1] - targetWindowX
                                targetY := xy[2] - targetWindowY
                                ControlClick('X' . targetX . ' Y' . targetY, targetWindow, , 'Left', 1, 'NA', ,)
                                _thisUserFulfilled := TRUE
                            }
                            else if (match == 0) {
                                failCount := failCount + 1
                                ControlClick(targetControl, targetWindow, , 'WU', 3, 'NA', ,) ;
                            }
                        }
                        if (_thisUserPass == TRUE && _thisUserFulfilled == TRUE) {
                            match := ImageSearch(
                                &matchedX,
                                &matchedY,
                                getScreenXbyWindowPercentage('12%'),
                                getScreenYbyWindowPercentage('70%'),
                                getScreenXbyWindowPercentage('88%'),
                                getScreenYbyWindowPercentage('77%'),
                                '*50 ' . _imageFile_userDetailFriendNow)
                            if (match == 1) {
                                ControlClick('X' . getWindowXbyWindowPercentage('50%') . ' Y' .
                                getWindowYbyWindowPercentage(
                                    '95%'), targetWindow, , 'Left', 1, 'NA', ,)
                                SendUiMsg("[승인 완료] 다음 신청 진행")
                                g_CurrentLogic := "1-01"
                            }
                            else if (match == 0) {
                                ; _delayXLong() ; // 유저가 입국 절차 중간에 신청 취소 시 닌텐도 서버 이슈로 긴 로딩 발생
                                ; 딜레이를 주면 전체 사이클이 느려지는 문제 / 차라리 사이클을 한번 더 돌리는게 이득
                                match := ImageSearch(
                                    &matchedX
                                    , &matchedY
                                    , getScreenXbyWindowPercentage('25%')
                                    , getScreenYbyWindowPercentage('43%')
                                    , getScreenXbyWindowPercentage('75%')
                                    , getScreenYbyWindowPercentage('52%')
                                    , '*50 ' . _imageFile_userDetailRequestNotFound)
                                if (match == 1) {
                                    SendUiMsg("[오류] '신청은 발견되지 않았습니다'")
                                    ControlClick(
                                        'X' . getWindowXbyWindowPercentage('50%') . ' Y' . getWindowYbyWindowPercentage(
                                            '68%')
                                        , targetWindow, , 'Left', 1, 'NA', ,)
                                    delayShort()
                                    ControlClick('X' . getWindowXbyWindowPercentage('50%') . ' Y' .
                                    getWindowYbyWindowPercentage('95%'), targetWindow, , 'Left', 1, 'NA', ,)
                                    g_CurrentLogic := "1-01"
                                    delayLong()
                                }
                                else if (match == 0) {
                                    SendUiMsg("[안내] 수락완료 대기 중")
                                    failCount := failCount + 1
                                }
                            }
                        }
                        if (_thisUserPass == FALSE && _thisUserFulfilled == TRUE) {
                            match := ImageSearch(
                                &matchedX,
                                &matchedY,
                                getScreenXbyWindowPercentage('12%'),
                                getScreenYbyWindowPercentage('70%'),
                                getScreenXbyWindowPercentage('88%'),
                                getScreenYbyWindowPercentage('77%'),
                                '*50 ' . _imageFile_userDetailRequestFriend)
                            if (match == 1) {
                                _clickCloseModalButton()
                                SendUiMsg("[거절 완료] 다음 신청 진행")
                                g_CurrentLogic := "1-01"
                                delayShort()
                            }
                            else if (match == 0) {
                                failCount := failCount + 1
                            }
                        }
                        if (failCount >= 5) {
                            SendUiMsg("[오류] 유저 화면 진입 실패. 화면을 초기화 합니다.")
                            g_CurrentLogic := "1-01"
                            failCount := 0
                            SendInput "{esc}"
                            InitLocation('RequestList')
                        }

                        ;; 거절 로직 시작
                    case "D00":
                        ;; 환경값 재설정
                        _delayConfig := g_UserIni.Delay
                        _instanceNameConfig := g_UserIni.InstanceName
                        _acceptingTermConfig := g_UserIni.AcceptingTerm * 60000
                        _deletingTermConfig := g_UserIni.BufferTerm * 60000

                        SendUiMsg("🗑️ 친구 삭제 부터 시작")
                        g_CaseDescription := '친구 삭제를 위해 메뉴 초기화'
                        LogicStartLog()
                        failCount := 0
                        _clickCloseModalButton()
                        delayXLong()
                        match := ImageSearch(
                            &matchedX
                            , &matchedY
                            , getScreenXbyWindowPercentage('2%')
                            , getScreenYbyWindowPercentage('80%')
                            , getScreenXbyWindowPercentage('24%')
                            , getScreenYbyWindowPercentage('90%')
                            , '*100 ' . _imageFile_friendMenuButton)
                        if (match == 1) {
                            ; _statusMsg("match = 1")
                            targetX := xy[1] - targetWindowX + 10
                            targetY := xy[2] - targetWindowY + 10
                            ControlClick('X' . targetX . ' Y' . targetY, targetWindow, , 'Left', 1, 'NA', ,)
                            g_CurrentLogic := "D01"
                            delayLong()
                        }
                        else if (match == 0) {
                            ; _statusMsg("match = 0")
                        }

                    case "D01":
                        g_CaseDescription := "친구 목록 확인"
                        LogicStartLog()
                        delayShort()
                        static globalRetryCount := 0 ; 무한루프 시 앱 종료를 위해

                        match := ImageSearch(
                            &matchedX
                            , &matchedY
                            , getScreenXbyWindowPercentage('56%')
                            , getScreenYbyWindowPercentage('20%')
                            , getScreenXbyWindowPercentage('98%')
                            , getScreenYbyWindowPercentage('44%')
                            , '*100 ' . _imageFile_friendListCard)
                        if (match == 1) {
                            globalRetryCount := 0
                            ; _statusMsg("match = 1")
                            targetX := xy[1] - targetWindowX
                            targetY := xy[2] - targetWindowY
                            ControlClick('X' . targetX . ' Y' . targetY, targetWindow, , 'Left', 1, 'NA', ,)
                            delayShort()
                            ControlClick('X' . targetX . ' Y' . targetY, targetWindow, , 'Left', 1, 'NA', ,)
                            g_CurrentLogic := "D02"
                            _thisUserDeleted := FALSE
                            failCount := 0 ; 성공 시 초기화
                            delayLong()
                        }
                        else if (match == 0) {
                            match := ImageSearch(
                                &matchedX
                                , &matchedY
                                , getScreenXbyWindowPercentage('20%')
                                , getScreenYbyWindowPercentage('45%')
                                , getScreenXbyWindowPercentage('80%')
                                , getScreenYbyWindowPercentage('55%')
                                , '*100 ' . _imageFile_friendListEmpty)
                            if (match == 1) {
                                SendUiMsg("[안내] 친구를 모두 삭제했습니다.")
                                SendUiMsg("[페이즈 전환] 수락을 재개합니다.")
                                PhaseToggler()
                                globalRetryCount := 0 ; 성공 시 초기화
                                g_CurrentLogic := "00"
                            }
                            else if (match == 0) {
                                failCount := failCount + 1
                            }
                            if (failCount >= 5) {
                                globalRetryCount := globalRetryCount + 1
                                if (globalRetryCount > 5) {
                                    SendUiMsg("[심각] 반복적인 화면 인식 실패. 프로그램을 종료합니다.")
                                    ExitApp
                                }
                                SendUiMsg("[오류] 유저 화면 진입 실패. 화면을 초기화 합니다.")
                                failCount := 0
                                InitLocation('FriendList')
                            }
                        }

                    case "D02":
                        g_CaseDescription := "친구 화면 진입"
                        LogicStartLog()
                        delayShort()
                        match := ImageSearch(
                            &matchedX,
                            &matchedY,
                            getScreenXbyWindowPercentage('12%'),
                            getScreenYbyWindowPercentage('70%'),
                            getScreenXbyWindowPercentage('88%'),
                            getScreenYbyWindowPercentage('77%'),
                            '*50 ' . _imageFile_userDetailFriendNow)
                        if (match == 1) {
                            ; _statusMsg("match = 1")
                            targetX := xy[1] - targetWindowX + 5
                            targetY := xy[2] - targetWindowY + 5
                            ControlClick('X' . targetX . ' Y' . targetY, targetWindow, , 'Left', 1, 'NA', ,)
                            g_CurrentLogic := "D03"
                            delayLong()
                        }
                        else if (match == 0) {
                            failCount := failCount + 1
                        }
                        if (failCount >= 5) {
                            SendUiMsg("[오류] 친구 삭제 호출 실패. 화면을 초기화 합니다.")
                            g_CurrentLogic := "D01"
                            failCount := 0
                            InitLocation('FriendList')
                        }

                    case "D03":
                        g_CaseDescription := "친구 삭제 진행"
                        LogicStartLog()
                        if (_thisUserDeleted == FALSE) {
                            match := ImageSearch(
                                &matchedX,
                                &matchedY,
                                getScreenXbyWindowPercentage('50%'),
                                getScreenYbyWindowPercentage('62%'),
                                getScreenXbyWindowPercentage('98%'),
                                getScreenYbyWindowPercentage('74%'),
                                '*50 ' . _imageFile_removeFriendConfirm)
                            if (match == 1) {
                                ; _statusMsg("match = 1")
                                targetX := xy[1] - targetWindowX + 50
                                targetY := xy[2] - targetWindowY + 20
                                ControlClick('X' . targetX . ' Y' . targetY, targetWindow, , 'Left', 1, 'NA', ,)
                                _thisUserDeleted := TRUE
                                ; _statusMsg("[친구 삭제 완료]")
                                delayLong()
                            }
                            else if (match == 0) {
                                failCount := failCount + 1
                            }
                            if (failCount >= 5) {
                                SendUiMsg("[오류] 친구 삭제 호출 실패. 화면을 초기화 합니다.")
                                g_CurrentLogic := "D01"
                                failCount := 0
                                SendInput "{esc}"
                                InitLocation('FriendList')
                            }
                        }
                        else if (_thisUserDeleted == TRUE) {
                            ; _statusMsg("[매치 시도] "
                            ; . getScreenXbyWindowPercentage('12%')
                            ; . " " . getScreenYbyWindowPercentage('70%')
                            ; . " " . getScreenXbyWindowPercentage('88%')
                            ; . " " . getScreenYbyWindowPercentage('77%'))
                            delayShort()
                            match := ImageSearch(
                                &matchedX,
                                &matchedY,
                                getScreenXbyWindowPercentage('12%'),
                                getScreenYbyWindowPercentage('70%'),
                                getScreenXbyWindowPercentage('88%'),
                                getScreenYbyWindowPercentage('77%'),
                                '*50 ' . _imageFile_userDetailRequestFriend)
                            if (match == 1) {
                                _clickCloseModalButton()
                                g_CurrentLogic := "D01"
                                delayLong()
                            }
                            else if (match == 0) {
                                failCount := failCount + 1
                            }
                            if (failCount >= 5) {
                                SendUiMsg("[오류] 화면 전환 실패. 화면을 초기화 합니다.")
                                g_CurrentLogic := "D01"
                                failCount := 0
                                SendInput "{esc}"
                                InitLocation('FriendList')
                            }
                        }

                }
        }
    }

    ; // Current 확인 로직 추가
    ; // Current에 따라 초기 화면으로 돌아가는 로직 추가
    ; // 이전 단계로 넘어가기 전에 현재 화면 체크 로직 필요 / 체크 완료 후 Current 변경 / 전체적으로 화면 변경 시점의 전환 로직 살펴보기
    ; // control 클릭 함수 정리 필요 -->> tryClick
    ; // 주요 버튼 클릭 함수화 ? 가능한지

    ;; 함수 정의
    ; getScreenXbyWindowPercentage() 정의
    ; 1) nn%와 같은 상대값을 입력 받고
    ; 2) 타겟 윈도우의 창 크기를 기준으로 절대값으로 변환
    ; 3) 스크린 기준 좌표로 반환
    getScreenXbyWindowPercentage(somePercentage) {
        if targetWindowWidth = false {
            MsgBox "타겟 윈도우가 설정되지 않았습니다."
            return
        }
        replacedPercentage := StrReplace(somePercentage, "%")
        if IsNumber(replacedPercentage) = false {
            MsgBox "올바른 퍼센티지 값이 입력되지 않았습니다."
            return
        }
        return Round(targetWindowX + (targetWindowWidth * (replacedPercentage / 100)), -1)
    }

    ; getScreenYbyWindowPercentage() 정의
    ; "이미지 서치 시에만" 사용 // 퍼센티지 상대값을 스크린 기준 절대값으로 변환
    getScreenYbyWindowPercentage(somePercentage) {
        if targetWindowHeight = false {
            MsgBox "타겟 윈도우가 설정되지 않았습니다."
            return
        }
        replacedPercentage := StrReplace(somePercentage, "%")
        if IsNumber(replacedPercentage) = false {
            MsgBox "올바른 퍼센티지 값이 입력되지 않았습니다."
            return
        }
        return Round(targetWindowY + (targetWindowHeight * (replacedPercentage / 100)), -1)
    }

    ; getWindowXbyWindowPercentage() 정의
    ; 클릭 등 창 내부 상호작용에 사용 // 퍼센티지 상대값을 창 기준 절대값으로 변환
    getWindowXbyWindowPercentage(somePercentage) {
        if targetWindowWidth == false {
            MsgBox "타겟 윈도우가 설정되지 않았습니다."
            return
        }
        replacedPercentage := StrReplace(somePercentage, "%")
        if IsNumber(replacedPercentage) == false {
            MsgBox "올바른 퍼센티지 값이 입력되지 않았습니다."
            return
        }
        return Round((targetWindowWidth * (replacedPercentage / 100)), -1)
    }

    getWindowYbyWindowPercentage(somePercentage) {
        if targetWindowHeight == false {
            MsgBox "타겟 윈도우가 설정되지 않았습니다."
            return
        }

        replacedPercentage := StrReplace(somePercentage, "%")
        if IsNumber(replacedPercentage) == false {
            MsgBox "올바른 퍼센티지 값이 입력되지 않았습니다."
            return
        }
        return Round((targetWindowHeight * (replacedPercentage / 100)), -1)
    }

    getWindowXbyDecimal(someDecimal) {
        if NOT targetControlHeight {
            MsgBox "타겟 윈도우가 설정되지 않았습니다."
            return
        }
        if NOT IsNumber(someDecimal) {
            MsgBox "올바른 소수 값이 입력되지 않았습니다."
            return
        }
        return Round((targetWindowWidth * someDecimal), -1)
    }

    getWindowYbyDecimal(someDecimal) {
        if NOT targetControlHeight {
            MsgBox "타겟 윈도우가 설정되지 않았습니다."
            return
        }
        if NOT IsNumber(someDecimal) {
            MsgBox "올바른 소수 값이 입력되지 않았습니다."
            return
        }
        return Round((targetWindowHeight * someDecimal / 100), -1)
    }

    getControlXbyDecimal(someDecimal) {
        if NOT targetControlHeight {
            MsgBox "타겟 윈도우가 설정되지 않았습니다."
            return
        }
        if NOT IsNumber(someDecimal) {
            MsgBox "올바른 소수 값이 입력되지 않았습니다."
            return
        }
        return Round(targetControlWidth * someDecimal, -1)
    }

    getControlYbyDecimal(someDecimal) {
        if NOT targetControlHeight {
            MsgBox "타겟 컨트롤이 설정되지 않았습니다."
            return
        }
        if NOT IsNumber(someDecimal) {
            MsgBox "올바른 소수 값이 입력되지 않았습니다."
            return
        }
        return Round(targetControlHeight * someDecimal, -1)
    }

    delayShort() {
        Sleep(_delayConfig)
    }

    delayLong() {
        Sleep(_delayConfig * 3)
    }

    delayXLong() {
        Sleep(_delayConfig * 10)
    }

    delayLoad() {
        Sleep(2000)
    }

    ; 모달 x 버튼 클릭
    _clickCloseModalButton() {
        ControlClick(
            'X' . getWindowXbyWindowPercentage('50%') . ' Y' . getWindowYbyWindowPercentage('95%')
            , targetWindow, , 'Left', 1, 'NA', ,)
    }

    _clickSafeArea() {
        ControlClick(
            'X' . getWindowXbyWindowPercentage('98%') . ' Y' . getWindowYbyWindowPercentage('50%')
            , targetWindow, , 'Left', 2, 'NA', ,)
    }

    _getElapsedTime() {
        global _nowAccepting
        global _recentTick, _currentTick

        _currentTick := A_TickCount
        elapsedTime := _currentTick - _recentTick
        SendUiMsg("[안내] 현재 페이즈 경과 시간 - " . MillisecToTime(elapsedTime))
        return elapsedTime
    }

    PhaseToggler(elapsedTime := 0) {
        global _nowAccepting
        global _recentTick, _currentTick
        global _acceptingTermConfig

        if (_nowAccepting == TRUE
            && elapsedTime > _acceptingTermConfig) {
            _nowAccepting := FALSE
            _recentTick := A_TickCount
            SendUiMsg("[페이즈 변경] 친구 삭제 페이즈로 변경")
            SendUiMsg("[안내] 현재 페이즈 경과 시간 - " . MillisecToTime(elapsedTime))
        }
        else if (_nowAccepting == FALSE) {
            _nowAccepting := TRUE
            _recentTick := A_TickCount
            SendUiMsg("[페이즈 변경]  친구 수락 페이즈로 변경")
            SendUiMsg("[안내] 현재 페이즈 경과 시간 - " . MillisecToTime(elapsedTime))
        }
    }

    ; 목적지로 화면 초기화 : Destination => RequestList / FriendList
    InitLocation(Destination := "RequestList") {
        r := 0
        while r < 10 {
            xy := MatchObject("FriendsMenuButton")
            if xy {
                ClickObject('FriendsMenuButton')
                delayXLong()
                if (Destination == "RequestList") {
                    ClickObject('FriendRequestMenuButton')
                    delayShort()
                    return
                }
                else if (Destination == "FriendList") {
                    return
                }
            }
            else {
                r := r + 1
                _clickCloseModalButton()
                delayLong()
            }
        }
        if (r >= 10) {
            SendUiMsg("[오류] 화면을 초기화할 수 없습니다.")
            return
        }
    }

    MillisecToTime(msec) {
        secs := Floor(Mod(msec / 1000, 60))
        mins := Floor(Mod(msec / (1000 * 60), 60))
        hour := Floor(Mod(msec / (1000 * 60 * 60), 24))
        days := Floor(msec / (1000 * 60 * 60 * 24))
        return Format("{}분 {:2}초", mins, secs)
    }

    ; 디버그 메시지 표시
    SendDebugMsg(Message) {
        global recentText, oldTexts, RecentTextCtrl, OldTextCtrl
        _logRecord(Message)
        if (recentText == "") {
        }
        else {
            oldTexts := recentText . (oldTexts ? "`n" . oldTexts : "")
            OldTextCtrl.Text := oldTexts
        }
        if (StrLen(oldTexts) > 2000) {
            oldTexts := ""
        }

        recentText := Message
        RecentTextCtrl.Text := recentText
        if (_debug == TRUE) {
            statusGUI.Show("NA")
        }
    }

    ; ui 로그 창에 메시지 표시 & 기록
    SendUiMsg(Message) {
        global messageQueue
        messageQueue.Push(Message)

        i := InStr(wv.Source, "/", , -1)
        w := SubStr(wv.source, i + 1)

        if (w == "index.html") {
            _messageQueueHandler()
        }
        else {
            SetTimer(_messageQueueHandler, 100)
        }
    }

    _messageQueueHandler() {
        global messageQueue

        for Message in messageQueue {
            wv.ExecuteScriptAsync("addLog('" Message "')")
            wv.ExecuteScriptAsync("adjustTextAreaHeight()")
            messageQueue.RemoveAt(1)
            _logRecord(Message)
        }
        SetTimer(_messageQueueHandler, 0)
    }

    _logRecord(text) {
        global logfile
        FileAppend "[" . A_YYYY . "-" . A_MM . "-" . A_DD . " " . A_Hour . ":" . A_Min . ":" . A_Sec . "] " . text .
            "`n",
            logfile, "UTF-8"
    }

    ToggleRunUiMode() {
        wv.ExecuteScriptAsync("SwitchUIMode('" g_IsRunning "')")
        return
    }

    ToggleRunMode() {
        global g_IsRunning
        g_IsRunning := NOT g_IsRunning
        wv.ExecuteScriptAsync("SwitchUIMode('" g_IsRunning "')")
        return
    }

    StartRun(startLogic) {
        global g_IsRunning
        global g_CurrentLogic

        g_IsRunning := TRUE
        g_CurrentLogic := startLogic

        wv.ExecuteScriptAsync("SwitchUIMode('" TRUE "')")
        SetTimer(() => Main(), -1)
        return
    }

    FinishRun() {
        global g_IsRunning
        g_IsRunning := FALSE
        wv.ExecuteScriptAsync("SwitchUIMode('" FALSE "')")
        ; SendUiMsg("⏹️ 동작을 중지합니다.")
    }

    TogglePauseMode() {
        global _isPausing
        _isPausing := NOT _isPausing
        wv.ExecuteScriptAsync("SwitchPauseMode('" _isPausing "')")
        return
    }

    ReadUserIni() {
        obj := {}
        obj.InstanceName := IniRead("Settings.ini", "UserSettings", "InstanceName")
        obj.Delay := IniRead("Settings.ini", "UserSettings", "Delay")
        obj.AcceptingTerm := IniRead("Settings.ini", "UserSettings", "AcceptingTerm")
        obj.BufferTerm := IniRead("Settings.ini", "UserSettings", "BufferTerm")
        obj.DisplayResolution := IniRead("Settings.ini", "UserSettings", "DisplayResolution")
        return obj
    }

    UpdateUserIni(obj) {
        IniWrite obj.InstanceName, "Settings.ini", "UserSettings", "InstanceName"
        IniWrite obj.Delay, "Settings.ini", "UserSettings", "Delay"
        IniWrite obj.AcceptingTerm, "Settings.ini", "UserSettings", "AcceptingTerm"
        IniWrite obj.BufferTerm, "Settings.ini", "UserSettings", "BufferTerm"
        IniWrite obj.DisplayResolution, "Settings.ini", "UserSettings", "DisplayResolution"
    }

    MatchObject(itemKey) {
        _predefinedItem := MatchLibrary[itemKey]
        capture := ImagePutBuffer({ window: targetWindow })
        needle := ImagePutBuffer({ file: _predefinedItem.matchImage[g_CurrentResolution] })
        if (xy := capture.ImageSearch(needle)) { ; // 스크린 기준 좌표 반환
            SendDebugMsg("[MatchImage] 이미지 매치 성공 : " _predefinedItem.name " / " xy[1] ", " xy[2])
            xy[1] := xy[1] + getWindowXbyDecimal(_predefinedItem.pointXOffsetFromMatch)
            xy[2] := xy[2] + getWindowYbyDecimal(_predefinedItem.pointYOffsetFromMatch)
            SendDebugMsg("[MatchImage] 클릭 좌표 변환 : " _predefinedItem.name " / " xy[1] ", " xy[2])
            return xy ; // 스크린 기준 클릭 좌표 반환
        }
        else {
            SendDebugMsg("[MatchImage] 이미지 매치 실패 : " _predefinedItem.name)
            return ""
        }
    }

    Click(xy) {
        x := xy[1]
        y := xy[2]
        SendDebugMsg("[Click]: " x ", " y)
        ControlClick('X' . x . ' Y' . y, targetWindow, , 'Left', 1, 'NA', ,)
    }

    ClickObject(itemKey) {
        _predefinedItem := MatchLibrary[itemKey]
        x := getControlXbyDecimal(_predefinedItem.pointX)
        y := getControlYbyDecimal(_predefinedItem.pointY) + targetControlHeightMargin
        SendDebugMsg("[ClickObject]: " x ", " y)
        ControlClick('X' . x . ' Y' . y, targetWindow, , 'Left', 1, 'NA', ,)
    }

    LogicStartLog() {
        SendUiMsg("[Current] " . g_CurrentLogic . " : " . g_CaseDescription)
    }

    TryLogicTransition(targetLogic) {
        global g_CurrentLogic, failCount, globalRetryCount
        r := 1
        i := TransitionLibrary[targetLogic]
        SendDebugMsg("[TryLogicTransition] 타겟 로직: " targetLogic)
        while r <= 3 {
            xy := MatchObject(i)
            if xy {
                g_CurrentLogic := targetLogic
                failCount := 0
                return g_CurrentLogic
            }
            else {
                r := r + 1
                SendDebugMsg("[TryLogicTransition] 재시도")
                delayLong()
            }
        }
        failCount := failCount + 1
        SendUiMsg("[오류] " targetLogic "으로 전환 실패. 재시도합니다.")
        return false
    }

    TransitionLibrary := Map(
        '1-02', 'UserDetailAccept',
        '1-04', 'UserDetailAccept',
        '1-05', 'UserDetailFriendNow',
        '1-06', 'UserDetailDecline',
    )