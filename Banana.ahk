/************************************************************************
 * @description Use Microsoft Edge WebView2 control in ahk.
 * @author Bananajuseyo
 * @date 2024/12/26
 * @version 1.00
 * @see {@link https://github.com/banana-juseyo/Banana-Macro-PtcgP Github Repository}
 * @see {@link https://gall.dcinside.com/m/pokemontcgpocket/291864 DCinside PtcgP Gallery Release Article}
 ***********************************************************************/

; 무한불판 매크로 by Banana-juseyo
; 권장 스크린 해상도 : 1920 * 1080
; 권장 플레이어 : mumuplayer
; 권장 인스턴스 해상도 : 540 * 960 (220 dpi)

#Requires AutoHotkey v2.0
; webview2 := DllCall("LoadLibrary", "Str", ".\app\WebView2Loader.dll")
#Include .\app\WebView2.ahk
#SingleInstance Force

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

_appTitle := "Banana Macro"
_version := "v1.00"
_website := "https://github.com/banana-juseyo/Banana-Macro-PtcgP"
_author := "banana-juseyo"
_repoName := "Banana-Macro-PtcgP"

; 글로벌 변수
global _isRunning := FALSE
global _isPausing := FALSE
global _debug := FALSE
global messageQueue := []
global _configGUIHwnd := ""
global GInstance := {}
global recentText := ""
global RecentTextCtrl := {}
global oldTexts := ""
global _userIni := {}

; 로그 파일 설정
global logFile := A_ScriptDir . "\log\" . A_YYYY . A_MM . A_DD . "_" . A_Hour . A_Min . A_Sec . "_" . "log.txt"

d := 2.25
width := Round(560 * d)
height := Round(432 * d)
radius := Round(8 * d)

;; 메인 UI 정의
ui := Gui("-SysMenu -Caption +LastFound")
ui.OnEvent('Close', (*) => ExitApp())
ui.Show("w560 h432")
_instanceWindow := WinGetID(A_ScriptName, , "Code",)
WinSetTitle _appTitle . " " . _version, _instanceWindow
WinSetRegion Format("0-0 w{1} h{2} r{3}-{3}", width, height, radius), _instanceWindow

;; 메인 UI 생성 (with 웹뷰2)
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
    global _isPausing, _configGUIHwnd, GInstance

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
                SendMsg("⏸️ 일시 정지")
            }
            else if ( NOT _isPausing) {
                SendMsg("▶️ 재개")
            }
            return
        case "_button_click_footer_stop":
            FinishRun()
            return
        case "_button_click_footer_settings":
            GInstance := ConfigGUI()
            return
        case "_click_github_link":
            Run _website
            return
    }
}

;; 자동 업데이트 관련 정의
; 자동 업데이트 시퀀스 실행 함수
latestVersion := CheckForUpdates(_version, _author, _repoName)
if (latestVersion) {
    downloadedFile := DownloadUpdateFile(_author, _repoName, "main", A_ScriptDir)
    if (downloadedFile) {
        InstallUpdate(A_ScriptDir)
    }
}

; 업데이트 확인 함수
; -> 업데이트 확인 성공 시 최신 버전 string 반환
CheckForUpdates(currentVersion, _author, _repoName) {
    latestReleaseUrl := Format("https://api.github.com/repos/{}/releases/latest", _author "/" _repoName)
    http := ComObject("WinHttp.WinHttpRequest.5.1")
    http.Open("GET", latestReleaseUrl, True)
    http.Send()
    http.WaitForResponse()
    if (http.Status != 200) {
        SendDebugMsg "릴리즈 정보를 받아오는데 실패했습니다: " http.Status
        return False
    }
    response := http.ResponseText
    latestVersion := StrExtract(response, '"tag_name":"', '"')
    if (currentVersion != latestVersion) {
        SendDebugMsg Format("업데이트가 가능합니다: {} -> {}", currentVersion, latestVersion)
        return latestVersion
    } else {
        SendDebugMsg "가능한 업데이트가 없습니다."
        return False
    }
}

StrExtract(text, start, stop) {
    pos1 := InStr(text, start) + StrLen(start)
    pos2 := InStr(text, stop, false, pos1)
    return SubStr(text, pos1, pos2 - pos1)
}

; 최신 업데이트 파일 다운로드 함수
; -> 다운로드 성공 시 파일의 전체 경로 번환
DownloadUpdateFile(_author, _repoName, assetName, downloadPath) {
    latestReleaseUrl := Format("https://api.github.com/repos/{}/releases/latest", _author "/" _repoName)
    http := ComObject("WinHttp.WinHttpRequest.5.1")
    http.Open("GET", latestReleaseUrl, True)
    http.Send()
    http.WaitForResponse()
    if (http.Status != 200) {
        MsgBox "릴리즈 정보를 받아오는데 실패했습니다: " http.Status
        return False
    }
    response := http.ResponseText
    downloadUrl := StrExtract(response, Format('"name":"{}",', assetName), '"browser_download_url":"') . '"'
    fileName := StrExtract(response, '"name":"', '"')
    if !downloadUrl {
        SendDebugMsg("최신 릴리즈에 에셋이 발견되지 않았습니다.")
        return False
    }
    http.Open("GET", downloadUrl, False)
    http.Send()
    filePath := downloadPath "\" fileName
    FileAppend(http.ResponseBody, filePath)
    MsgBox Format("다운로드를 완료했습니다: ", fileName)
    return filePath
}

; 업데이트 설치 함수
InstallUpdate(updateFilePath) {
    if !FileExist(updateFilePath) {
        MsgBox Format("Update file not found: {}", updateFilePath)
        return False
    }
    MsgBox Format("Installing update from: {}", updateFilePath)
    Run(updateFilePath)
    ExitApp
}

; 환경 설정 불러오기
_userIni := ReadUserIni()

;; 환경설정 GUI 정의
OpenConfigGUI() {
    global _configGUIHwnd

    _gui := GUI()
    _configGUIHwnd := _gui.hwnd
    _gui.Opt("-SysMenu +LastFound +Owner" ui.Hwnd)
    _gui.Title := "환경 설정"
    _gui.BackColor := "DADCDE"
    _defaultValue := ""

    section := { x1: 30, y1: 30 }
    _confInstanceNameTitle := _gui.Add("Text", Format("x{} y{} w100 h30", section.x1, section.y1 + 5),
    "인스턴스 이름")
    _confInstanceNameTitle.SetFont("q3  s10 w600")
    _redDotText := _gui.Add("Text", Format("x{} y{} w10 h30", section.x1 + 93, section.y1 + 3),
    "*")
    _redDotText.SetFont("q3 s11 w600 cF65E3C")
    _confInstanceNameField := _gui.Add("Edit", Format("x{} y{} w280 h26 -VScroll Background", section.x1 +
        120,
        section.y1), _userIni.InstanceName)
    _confInstanceNameField.SetFont("q3  s13")
    _confInstanceNameField.name := "InstanceName"
    _confInstanceNameHint := _gui.Add("Text", Format("x{} y{} w280 h24", section.x1 + 120, section.y1 + 36),
    "불판이 가동중인 뮤뮤 플레이어 인스턴스 이름을 정확하게 입력해 주세요.")
    _confInstanceNameHint.SetFont("q3  s8 c636363")

    switch _userIni.Delay {
        global _defaultValue
        case "150": _defaultValue := "Choose1"
        case "250": _defaultValue := "Choose2"
        case "350": _defaultValue := "Choose3"
    }
    section := { x1: 30, y1: 100, default: _defaultValue }
    _confDelayTitle := _gui.Add("Text", Format("x{} y{} w100 h30", section.x1, section.y1 + 5), "딜레이`n(ms)"
    )
    _confDelayTitle.SetFont("q3 s10 w600")
    _confDelayField := _gui.Add("DropDownList", Format("x{} y{} w280 {}", section.x1 + 120,
        section.y1, section.default), [150, 250, 350])
    _confDelayField.SetFont("q3  s13")
    _confDelayField.name := "Delay"
    _confDelayHint := _gui.Add("Text", Format("x{} y{} w280 h24", section.x1 + 120, section.y1 + 30),
    "앱의 전반에 걸쳐 지연 시간을 설정합니다.`n값이 커지면 속도는 느려지지만 오류 확률이 줄어듭니다.")
    _confDelayHint.SetFont("q3  s8 c636363")

    switch _userIni.AcceptingTerm {
        global _defaultValue
        case 6: _defaultValue := "Choose1"
        case 8: _defaultValue := "Choose2"
        case 10: _defaultValue := "Choose3"
        case 12: _defaultValue := "Choose4"
    }
    section := { x1: 30, y1: 170, default: _defaultValue }
    _confAcceptingTermTitle := _gui.Add("Text", Format("x{} y{} w100 h30", section.x1, section.y1 + 5),
    "친구 수락 시간`n(분)")
    _confAcceptingTermTitle.SetFont("q3  s10 w600")
    _confAcceptingTermField := _gui.Add("DropDownList", Format("x{} y{} w280 {}", section.x1 + 120,
        section.y1, section.default), [6, 8, 10, 12])
    _confAcceptingTermField.SetFont("q3  s13")
    _confAcceptingTermField.name := "AcceptingTerm"
    _confAcceptingTermHint := _gui.Add("Text", Format("x{} y{} w280 h24", section.x1 + 120, section.y1 + 30
    ),
    "친구 수락 단계의 시간을 설정합니다.`n평균적으로 분당 8명 정도의 수락을 받을 수 있습니다.")
    _confAcceptingTermHint.SetFont("q3  s8 c636363")

    switch _userIni.BufferTerm {
        global _defaultValue
        case 2: _defaultValue := "Choose1"
        case 3: _defaultValue := "Choose2"
        case 4: _defaultValue := "Choose3"
    }
    section := { x1: 30, y1: 240, default: _defaultValue }
    _confBufferTermTitle := _gui.Add("Text", Format("x{} y{} w100 h30", section.x1, section.y1 + 5),
    "삭제 유예 시간`n(분)")
    _confBufferTermTitle.SetFont("q3  s10 w600")
    _confBufferTermField := _gui.Add("DropDownList", Format("x{} y{} w280 {}", section.x1 + 120, section.y1,
        section.default
    ), [2, 3, 4])
    _confBufferTermField.SetFont("q3  s13")
    _confBufferTermField.name := "BufferTerm"
    _confBufferTermHint := _gui.Add("Text", Format("x{} y{} w280 h24", section.x1 + 120, section.y1 + 30),
    "친구 수락을 완료한 뒤, 친구 삭제까지의 유예 시간을 설정합니다.")
    _confBufferTermHint.SetFont("q3  s8 c636363")

    section := { x1: 30, y1: 310 }
    _confirmButton := _gui.Add("Button", Format("x{} y{} w120 h40 BackgroundDADCDE", section.x1 + 76,
        section.y1
    ), "저장")
    _confirmButton.SetFont("q3  w600")
    _confirmButton.OnEvent("Click", Submit)
    _cancleButton := _gui.Add("Button", Format("x{} y{} w120 h40 BackgroundDADCDE", section.x1 + 200,
        section.y1
    ), "취소")
    _cancleButton.SetFont("q3  w600")
    _cancleButton.OnEvent("Click", Dismiss)

    _gui.Show("")
    _gui.Move(528, 205, 480, 410)

    return _gui

    Submit(*) {
        global _userIni
        _userIni := _gui.Submit(TRUE)
        UpdateUserIni(_userIni)
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

class ConfigGUI {
    gui := ""

    __New() {
        if (_configGUIHwnd && WinExist(_configGUIHwnd)) {
            WinActivate(_configGUIHwnd)
            this.gui := GuiFromHwnd(_configGUIHwnd)
        }
        else {
            this.gui := OpenConfigGUI()
        }
    }

    Submit() {
        global _userIni
        _userIni := this.gui.Submit(TRUE)
        UpdateUserIni(_userIni)
        this.gui.Destroy()
        return
    }

    Dismiss() {
        if (WinActive(_configGUIHwnd)) {
            this.gui.Destroy()
            return
        }
    }
}

; GInstance := ConfigGUI()

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
        SendMsg("⏸️ 일시 정지")
    }
    else if ( NOT _isPausing) {
        SendMsg("▶️ 재개")
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

#HotIf WinActive(_configGUIHwnd)
~Enter:: {
    _gui := GuiFromHwnd(_configGUIHwnd)
    GInstance.Submit()
}
~Esc:: {
    GInstance.Dismiss()
}

;; 환경값 초기화
global _delayConfig := _userIni.Delay
global _instanceNameConfig := _userIni.InstanceName
global _acceptingTermConfig := _userIni.AcceptingTerm * 60000
global _deletingTermConfig := _userIni.BufferTerm * 60000

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

SendMsg("포켓몬 카드 게임 포켓 갤러리")
SendMsg(" ")
SendMsg("바나나 무한 불판 매크로 " _version " by Banana-juseyo")
SendMsg(" ")
SendMsg("🍌 매크로 초기화 완료")

;; 메인 함수 선언
_main(_currentLogic := "00") {
    global _isRunning
    global targetWindowHwnd

    if ( NOT _instanceNameConfig) {
        GInstance := ConfigGUI()
        SendMsg("[오류] 인스턴스 이름이 입력되지 않았습니다.")
        SetTimer(() => FinishRun(), -1)
        return
    }

    targetWindowHwnd := WinExist(_instanceNameConfig)
    _isRunning := TRUE

    if targetWindowHwnd {
        WinGetPos(&targetWindowX, &targetWindowY, &targetWindowWidth, &targetWindowHeight, targetWindowHwnd)
        global targetControlHandle := ControlGetHwnd('nemuwin1', targetWindowHwnd)
    }
    if !targetWindowHwnd {
        SendMsg("[오류] 입력한 인스턴스에서 PtcgP 앱을 확인할 수 없습니다 : " _instanceNameConfig)
        SetTimer(() => FinishRun(), -1)
        return
    }
    WinMove(, , 527, 970, targetWindowHwnd)
    WinActivate (targetWindowHwnd)
    CoordMode("Pixel", "Screen")

    ; 전역 변수 선언
    global targetWindowX, targetWindowY, targetWindowWidth, targetWindowHeight, _thisUserPass, _thisUserFulfilled
    global _nowAccepting
    global _recentTick, _currentTick
    global failCount

    _nowAccepting := TRUE
    _thisUserPass := FALSE
    _thisUserFulfilled := FALSE
    _recentTick := A_TickCount
    _currentTick := A_TickCount

    loop {
        if (!_isRunning) {
            break
        }
        ; 타겟 윈도우 재설정
        ; 타겟 윈도우의 크기를 동적으로 반영하기 위해 루프 속에서 실행
        WinGetPos(&targetWindowX, &targetWindowY, &targetWindowWidth, &targetWindowHeight, targetWindowHwnd)

        switch _currentLogic {
            ; 00. 화면 초기화
            case "00":
                SendMsg("✅ 친구 추가부터 시작")
                caseDescription := '화면 초기화'
                SendMsg("[Current] " . _currentLogic . " : " . caseDescription)
                InitLocation("RequestList")
                _currentLogic := "01"
                static globalRetryCount := 0
                failCount := 0

                ; 01. 친구 추가 확인
            case "01":
                caseDescription := '신청 확인'
                SendMsg("[Current] " . _currentLogic . " : " . caseDescription)

                elapsedTime := _getElapsedTime()
                PhaseToggler(elapsedTime)

                if (_nowAccepting = FALSE) {
                    _currentLogic := "D00"
                    SendMsg("[페이즈 전환] 수락을 중단합니다. " . Round(_deletingTermConfig / 60000) . "분 후 친구 삭제 시작.")
                    globalRetryCount := 0
                    Sleep(_deletingTermConfig)
                }

                if (_nowAccepting == TRUE && _currentLogic == "01") {
                    match := ImageSearch(
                        &matchedX
                        , &matchedY
                        , getScreenXbyWindowPercentage('60%')
                        , getScreenYbyWindowPercentage('5%')
                        , getScreenXbyWindowPercentage('99%')
                        , getScreenYbyWindowPercentage('75%')
                        , '*50 ' . _imageFile_friendRequestListCard)  ; // 신청 카드 확인
                    if (match == 1) { ; // 신청 카드 있는 경우
                        targetX := matchedX - targetWindowX
                        targetY := matchedY - targetWindowY - 50
                        delayLong()
                        ControlClick('X' . targetX . ' Y' . targetY, targetWindowHwnd, , 'Left', 1, 'NA', ,)
                        delayShort() ; // 오류 방지 위해 2중 클릭
                        ControlClick('X' . targetX . ' Y' . targetY, targetWindowHwnd, , 'Left', 1, 'NA', ,)
                        _currentLogic := "02-A"
                        failCount := 0 ; // 유저 화면 진입 시 failCount 초기화
                        globalRetryCount := 0
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
                            , '*50 ' . _imageFile_friendRequestListEmpty) ; // 잔여 신청 목록 = 0 인지 확인
                        if (match == 1) { ; // 잔여 신청 목록 = 0 인 경우
                            SendMsg('[안내] 잔여 신청 목록이 없습니다. 10초 후 새로고침.')
                            sleep(10000) ; 10초 중단
                            InitLocation("RequestList")
                            globalRetryCount := 0
                        }
                        else if (match == 0) { ; // 신청 목록 확인 실패, 일시적인 오류일 수 있어 failCount로 처리
                            failCount := failCount + 1
                            delayLong()
                        }
                    }
                }
                if (failCount >= 5) {
                    globalRetryCount := globalRetryCount + 1
                    if (globalRetryCount > 5) {
                        SendMsg("[심각] 반복적인 화면 인식 실패. 프로그램을 종료합니다.")
                        ExitApp
                    }
                    SendMsg("[오류] 신청 목록 확인 실패. 화면을 초기화 합니다.")
                    InitLocation("RequestList")
                    _currentLogic := "01"
                    failCount := 0
                    delayShort()
                }

            case "02-A": ; // 02. 유저 디테일 // A. 화면 진입 확인
                caseDescription := '유저 화면 진입'
                SendMsg("[Current] " . _currentLogic . " : " . caseDescription)
                match := ImageSearch(
                    &matchedX,
                    &matchedY,
                    getScreenXbyWindowPercentage('12%'),
                    getScreenYbyWindowPercentage('70%'),
                    getScreenXbyWindowPercentage('88%'),
                    getScreenYbyWindowPercentage('77%'),
                    '*50 ' . _imageFile_userDetailRequestFriend)
                if (match == 1) {
                    SendMsg("[오류] 유저의 신청 취소")
                    _clickCloseModalButton()
                    _thisUserFulfilled := TRUE
                    _currentLogic := "01"
                }
                else if (match == 0) {
                    match := ImageSearch(
                        &matchedX
                        , &matchedY
                        , getScreenXbyWindowPercentage('35%')
                        , getScreenYbyWindowPercentage('80%')
                        , getScreenXbyWindowPercentage('65%')
                        , getScreenYbyWindowPercentage('92%')
                        , '*50 ' . _imageFile_userDetailEmblem)
                    if (match == 1) {
                        ; ControlClick(targetControlHandle, targetWindowHandle, , 'WD', 1, 'NA', , ) ;
                        ControlClick(targetControlHandle, targetWindowHwnd, , 'WD', 2, 'NA', ,) ;
                        delayShort()
                        ; _clickSafeArea() ; // 어째선지 호출이 안됨
                        ControlClick(
                            'X' . getWindowXbyWindowPercentage('98%') . ' Y' . getWindowYbyWindowPercentage('50%')
                            , targetWindowHwnd, , 'Left', 2, 'NA', ,)
                        _currentLogic := "02-B"
                        failCount := 0
                        ; _delayLong() ; // 1배속
                        delayShort() ; // 2배속
                    }
                    else if (match == 0) {
                        failCount := failCount + 1
                        SendMsg("[안내] 유저화면 진입완료 대기 중")
                        delayShort()
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
                            SendMsg('[안내] 잔여 신청 목록이 없습니다. 10초 후 새로고침.')
                            _currentLogic := "01"
                            failCount := 0
                            sleep(10000) ; 10초 중단
                            InitLocation("RequestList")
                        }
                        else if (match == 0) {
                            SendMsg("[오류] 유저 화면 진입 실패. 화면을 초기화 합니다.")
                            _currentLogic := "01"
                            failCount := 0
                            InitLocation("RequestList")
                        }
                    }
                }

                ; 02. 유저 디테일 // B. 마이베스트 진입 시도
            case "02-B":
                caseDescription := '마이베스트 카드 검색'
                SendMsg("[Current] " . _currentLogic . " : " . caseDescription)
                _clickSafeArea()
                match := ImageSearch(
                    &matchedX
                    , &matchedY
                    , getScreenXbyWindowPercentage('20%')
                    , getScreenYbyWindowPercentage('5%')
                    , getScreenXbyWindowPercentage('80%')
                    , getScreenYbyWindowPercentage('90%')
                    , '*100 ' . _imageFile_userDetailEmpty)
                if (match == 1) {
                    SendMsg("[오류] 마이 베스트 미설정")
                    SendMsg("❌ 입국 심사 거절")
                    _thisUserPass := FALSE
                    _thisUserFulfilled := FALSE
                    _currentLogic := "03-B"
                }
                else if (match == 0) {
                    match := ImageSearch(
                        &matchedX
                        , &matchedY
                        , getScreenXbyWindowPercentage('38%')
                        , getScreenYbyWindowPercentage('5%')
                        , getScreenXbyWindowPercentage('62%')
                        , getScreenYbyWindowPercentage('90%')
                        , '*100 ' . _imageFile_userDetailMybest)
                    if (match == 1) {
                        targetX := (matchedX - targetWindowX) + 20
                        targetY := (matchedY - targetWindowY) + 100
                        ControlClick('X' . targetX . ' Y' . targetY, targetWindowHwnd, , 'Left', 1, 'NA', ,)
                        delayShort() ; // 오류 자꾸 발생해서 2중 클릭 예외 처리
                        ControlClick('X' . targetX . ' Y' . targetY, targetWindowHwnd, , 'Left', 1, 'NA', ,)
                        ; _delayLong() ; // 1배속
                        _currentLogic := "03-A"
                        failCount := 0
                        delayLong()
                    }
                    else if (match == 0) {
                        failCount := failCount + 1
                    }
                    if (failCount >= 5) {
                        SendMsg("[오류] 마이 베스트 진입 불가")
                        _clickCloseModalButton()
                        _currentLogic := "01"
                        failCount := 0
                        delayShort()
                    }
                }

                ; 03. 입국 심사 // A. 여권 확인
            case "03-A":
                caseDescription := '입국 심사 : 여권 확인'
                SendMsg("[Current] " . _currentLogic . " : " . caseDescription)
                ; _delayLong() ; // 1배속
                if (failCount < 5) {
                    match := ImageSearch(
                        &matchedX
                        , &matchedY
                        , getScreenXbyWindowPercentage('2%')
                        , getScreenYbyWindowPercentage('83%')
                        , getScreenXbyWindowPercentage('22%')
                        , getScreenYbyWindowPercentage('90%')
                        , '*50 ' . _imageFile_passportPikachu)
                    if (match == 1) {
                        _thisUserPass := TRUE
                        _thisUserFulfilled := FALSE
                        SendMsg("✅ 입국 심사 통과")
                        ControlClick('X' . getWindowXbyWindowPercentage('50%') . ' Y' . getWindowYbyWindowPercentage(
                            '95%'), targetWindowHwnd, , 'Left', 1, 'NA', ,)
                        _currentLogic := "03-B"
                        failCount := 0
                        delayShort()
                    }
                    else if (match == 0) {
                        SendMsg("[여권 인식 실패] 잠시 후 재시도 ")
                        failCount := failCount + 1
                        delayLong()
                    }
                }
                if (failCount >= 5) {
                    SendMsg("❌ 입국 심사 거절")
                    _thisUserPass := FALSE
                    _thisUserFulfilled := FALSE
                    ControlClick('X' . getWindowXbyWindowPercentage('50%') . ' Y' . getWindowYbyWindowPercentage('95%'),
                    targetWindowHwnd, , 'Left', 1, 'NA', ,)
                    _currentLogic := "03-B"
                    failCount := 0
                    delayShort()
                }

                ; 03. 입국 심사 // B. 유저 화면 재진입, 신청 처리
            case "03-B":
                caseDescription := '유저 화면 재진입, 신청 처리'
                SendMsg("[Current] " . _currentLogic . " : " . caseDescription)
                match := ImageSearch(
                    &matchedX
                    , &matchedY
                    , getScreenXbyWindowPercentage('38%')
                    , getScreenYbyWindowPercentage('5%')
                    , getScreenXbyWindowPercentage('62%')
                    , getScreenYbyWindowPercentage('90%')
                    , '*100 ' . _imageFile_userDetailMybest)
                if (match == 1) {
                    ControlClick(targetControlHandle, targetWindowHwnd, , 'WU', 3, 'NA', ,) ;
                    delayShort()
                    _currentLogic := "03-C"
                }
                else if (match == 0) {
                    ControlClick(targetControlHandle, targetWindowHwnd, , 'WU', 1, 'NA', ,)
                    delayShort()
                    ControlClick(targetControlHandle, targetWindowHwnd, , 'WD', 1, 'NA', ,)
                    delayShort()
                    failCount := failCount + 1
                }
                if (failCount >= 5) {
                    SendMsg("[오류] 승인 화면 진입 실패. 화면을 초기화 합니다.")
                    _currentLogic := "01"
                    InitLocation("RequestList")
                    failCount := 0
                }

            case "03-C":
                caseDescription := '신청 처리'
                SendMsg("[Current] " . _currentLogic . " : " . caseDescription)
                if (_thisUserPass == TRUE && _thisUserFulfilled == FALSE) {
                    SendMsg("[승인 진행]")
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
                        targetX := matchedX - targetWindowX + 10
                        targetY := matchedY - targetWindowY + 10
                        ; _statusMsg("[클릭]`ntargetX : " . targetX . "`ntargetY : " . targetY)
                        ControlClick('X' . targetX . ' Y' . targetY, targetWindowHwnd, , 'Left', 1, 'NA', ,)
                        _thisUserFulfilled := TRUE
                        delayLong() ; // 닌텐도 서버 이슈로 로딩 발생
                    }
                    else if (match == 0) {
                        failCount := failCount + 1
                        ControlClick(targetControlHandle, targetWindowHwnd, , 'WU', 3, 'NA', ,) ;

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
                            SendMsg("[오류] 유저의 신청 취소")
                            _clickCloseModalButton()
                            _thisUserFulfilled := TRUE
                            _currentLogic := "01"
                        }
                        else if (match == 0) {
                            delayShort()
                        }
                    }
                    if (failCount >= 5) {
                        SendMsg("[오류] 승인 불가")
                        _clickCloseModalButton()
                        _currentLogic := "01"
                        failCount := 0
                        delayShort()
                    }

                }
                if (_thisUserPass == FALSE && _thisUserFulfilled == FALSE) {
                    SendMsg("[거절 진행]")
                    match := ImageSearch(
                        &matchedX
                        , &matchedY
                        , getScreenXbyWindowPercentage('12%')
                        , getScreenYbyWindowPercentage('70%')
                        , getScreenXbyWindowPercentage('88%')
                        , getScreenYbyWindowPercentage('77%')
                        , '*50 ' . _imageFile_userDetailDecline)
                    if (match == 1) {
                        targetX := matchedX - targetWindowX
                        targetY := matchedY - targetWindowY
                        ControlClick('X' . targetX . ' Y' . targetY, targetWindowHwnd, , 'Left', 1, 'NA', ,)
                        _thisUserFulfilled := TRUE
                    }
                    else if (match == 0) {
                        failCount := failCount + 1
                        ControlClick(targetControlHandle, targetWindowHwnd, , 'WU', 3, 'NA', ,) ;
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
                        ControlClick('X' . getWindowXbyWindowPercentage('50%') . ' Y' . getWindowYbyWindowPercentage(
                            '95%'), targetWindowHwnd, , 'Left', 1, 'NA', ,)
                        SendMsg("[승인 완료] 다음 신청 진행")
                        _currentLogic := "01"
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
                            SendMsg("[오류] '신청은 발견되지 않았습니다'")
                            ControlClick(
                                'X' . getWindowXbyWindowPercentage('50%') . ' Y' . getWindowYbyWindowPercentage('68%')
                                , targetWindowHwnd, , 'Left', 1, 'NA', ,)
                            delayShort()
                            ControlClick('X' . getWindowXbyWindowPercentage('50%') . ' Y' .
                            getWindowYbyWindowPercentage('95%'), targetWindowHwnd, , 'Left', 1, 'NA', ,)
                            _currentLogic := "01"
                            delayLong()
                        }
                        else if (match == 0) {
                            SendMsg("[안내] 수락완료 대기 중")
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
                        SendMsg("[거절 완료] 다음 신청 진행")
                        _currentLogic := "01"
                        delayShort()
                    }
                    else if (match == 0) {
                        failCount := failCount + 1
                    }
                }
                if (failCount >= 5) {
                    SendMsg("[오류] 유저 화면 진입 실패. 화면을 초기화 합니다.")
                    _currentLogic := "01"
                    failCount := 0
                    SendInput "{esc}"
                    InitLocation("RequestList")
                }

                ;; 거절 로직 시작
            case "D00":
                SendMsg("🗑️ 친구 삭제 부터 작업 시작")
                caseDescription := '친구 삭제를 위해 메뉴 초기화'
                SendMsg("[Current] " . _currentLogic . " : " . caseDescription)
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
                    targetX := matchedX - targetWindowX + 10
                    targetY := matchedY - targetWindowY + 10
                    ControlClick('X' . targetX . ' Y' . targetY, targetWindowHwnd, , 'Left', 1, 'NA', ,)
                    _currentLogic := "D01"
                    delayLong()
                }
                else if (match == 0) {
                    ; _statusMsg("match = 0")
                }

            case "D01":
                caseDescription := "친구 목록 확인"
                SendMsg("[Current] " . _currentLogic . " : " . caseDescription)
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
                    targetX := matchedX - targetWindowX
                    targetY := matchedY - targetWindowY
                    ControlClick('X' . targetX . ' Y' . targetY, targetWindowHwnd, , 'Left', 1, 'NA', ,)
                    delayShort()
                    ControlClick('X' . targetX . ' Y' . targetY, targetWindowHwnd, , 'Left', 1, 'NA', ,)
                    _currentLogic := "D02"
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
                        SendMsg("[안내] 친구를 모두 삭제했습니다.")
                        SendMsg("[페이즈 전환] 수락을 재개합니다.")
                        PhaseToggler()
                        globalRetryCount := 0 ; 성공 시 초기화
                        _currentLogic := "00"
                    }
                    else if (match == 0) {
                        failCount := failCount + 1
                    }
                    if (failCount >= 5) {
                        globalRetryCount := globalRetryCount + 1
                        if (globalRetryCount > 5) {
                            SendMsg("[심각] 반복적인 화면 인식 실패. 프로그램을 종료합니다.")
                            ExitApp
                        }
                        SendMsg("[오류] 유저 화면 진입 실패. 화면을 초기화 합니다.")
                        failCount := 0
                        InitLocation('FriendList')
                    }
                }

            case "D02":
                caseDescription := "친구 화면 진입"
                SendMsg("[Current] " . _currentLogic . " : " . caseDescription)
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
                    targetX := matchedX - targetWindowX + 5
                    targetY := matchedY - targetWindowY + 5
                    ControlClick('X' . targetX . ' Y' . targetY, targetWindowHwnd, , 'Left', 1, 'NA', ,)
                    _currentLogic := "D03"
                    delayLong()
                }
                else if (match == 0) {
                    failCount := failCount + 1
                }
                if (failCount >= 5) {
                    SendMsg("[오류] 친구 삭제 호출 실패. 화면을 초기화 합니다.")
                    _currentLogic := "D01"
                    failCount := 0
                    InitLocation("FriendList")
                }

            case "D03":
                caseDescription := "친구 삭제 진행"
                SendMsg("[Current] " . _currentLogic . " : " . caseDescription)
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
                        targetX := matchedX - targetWindowX + 50
                        targetY := matchedY - targetWindowY + 20
                        ControlClick('X' . targetX . ' Y' . targetY, targetWindowHwnd, , 'Left', 1, 'NA', ,)
                        _thisUserDeleted := TRUE
                        ; _statusMsg("[친구 삭제 완료]")
                        delayLong()
                    }
                    else if (match == 0) {
                        failCount := failCount + 1
                    }
                    if (failCount >= 5) {
                        SendMsg("[오류] 친구 삭제 호출 실패. 화면을 초기화 합니다.")
                        _currentLogic := "D01"
                        failCount := 0
                        SendInput "{esc}"
                        InitLocation("FriendList")
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
                        _currentLogic := "D01"
                        delayLong()
                    }
                    else if (match == 0) {
                        failCount := failCount + 1
                    }
                    if (failCount >= 5) {
                        SendMsg("[오류] 화면 전환 실패. 화면을 초기화 합니다.")
                        _currentLogic := "D01"
                        failCount := 0
                        SendInput "{esc}"
                        InitLocation("FriendList")
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
    return Round(targetWindowX + (targetWindowWidth * replacedPercentage / 100), -1)
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
    return Round(targetWindowY + (targetWindowHeight * replacedPercentage / 100), -1)
}

; getWindowXbyWindowPercentage() 정의
; 클릭 등 창 내부 상호작용에 사용 // 퍼센티지 상대값을 창 기준 절대값으로 변환
getWindowXbyWindowPercentage(somePercentage) {
    if targetWindowWidth = false {
        MsgBox "타겟 윈도우가 설정되지 않았습니다."
        return
    }
    replacedPercentage := StrReplace(somePercentage, "%")
    if IsNumber(replacedPercentage) = false {
        MsgBox "올바른 퍼센티지 값이 입력되지 않았습니다."
        return
    }
    return Round((targetWindowWidth * replacedPercentage / 100), -1)
}

getWindowYbyWindowPercentage(somePercentage) {
    if targetWindowHeight = false {
        MsgBox "타겟 윈도우가 설정되지 않았습니다."
        return
    }

    replacedPercentage := StrReplace(somePercentage, "%")
    if IsNumber(replacedPercentage) = false {
        MsgBox "올바른 퍼센티지 값이 입력되지 않았습니다."
        return
    }
    return Round((targetWindowHeight * replacedPercentage / 100), -1)

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
        , targetWindowHwnd, , 'Left', 1, 'NA', ,)
}

_clickSafeArea() {
    ControlClick(
        'X' . getWindowXbyWindowPercentage('98%') . ' Y' . getWindowYbyWindowPercentage('50%')
        , targetWindowHwnd, , 'Left', 2, 'NA', ,)
}

_getElapsedTime() {
    global _nowAccepting
    global _recentTick, _currentTick

    _currentTick := A_TickCount
    elapsedTime := _currentTick - _recentTick
    SendMsg("[안내] 현재 페이즈 경과 시간 - " . MillisecToTime(elapsedTime))
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
        SendMsg("[페이즈 변경] 친구 삭제 페이즈로 변경")
        SendMsg("[안내] 현재 페이즈 경과 시간 - " . MillisecToTime(elapsedTime))
    }
    else if (_nowAccepting == FALSE) {
        _nowAccepting := TRUE
        _recentTick := A_TickCount
        SendMsg("[페이즈 변경]  친구 수락 페이즈로 변경")
        SendMsg("[안내] 현재 페이즈 경과 시간 - " . MillisecToTime(elapsedTime))
    }
}

InitLocation(Destination := "RequestList") {
    failCount := 0
    while failCount < 10 {
        match := ImageSearch(
            &matchedX
            , &matchedY
            , getScreenXbyWindowPercentage('2%')
            , getScreenYbyWindowPercentage('80%')
            , getScreenXbyWindowPercentage('24%')
            , getScreenYbyWindowPercentage('90%')
            , '*100 ' . _imageFile_friendMenuButton)
        if (match == 1) {
            SendMsg("화면 인식 성공")
            targetX := matchedX - targetWindowX + 10
            targetY := matchedY - targetWindowY + 10
            ControlClick('X' . targetX . ' Y' . targetY, targetWindowHwnd, , 'Left', 1, 'NA', ,)
            delayXLong()
            if (Destination == "RequestList") {
                ControlClick('X' . getWindowXbyWindowPercentage('80%') . ' Y' . getWindowYbyWindowPercentage('86%'),
                targetWindowHwnd, , 'Left', 1, 'NA', ,)
                delayShort()
                return
            }
            else if (Destination == "FriendList") {
                return
            }
        }
        else if match == 0 {
            failCount := failCount + 1
            _clickCloseModalButton()
            delayLong()
        }
    }
    if (failCount >= 10) {
        SendMsg("[오류] 화면을 초기화할 수 없습니다.")
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
SendMsg(Message) {
    wv.ExecuteScriptAsync("addLog('" Message "')")
    wv.ExecuteScriptAsync("adjustTextAreaHeight()")
    _logRecord(Message)
}

_logRecord(text) {
    global logfile
    FileAppend "[" . A_YYYY . "-" . A_MM . "-" . A_DD . " " . A_Hour . ":" . A_Min . ":" . A_Sec . "] " . text . "`n",
        logfile, "UTF-8"
}

ToggleRunUiMode() {
    wv.ExecuteScriptAsync("SwitchUIMode('" _isRunning "')")
    return
}

ToggleRunMode() {
    global _isRunning
    _isRunning := NOT _isRunning
    wv.ExecuteScriptAsync("SwitchUIMode('" _isRunning "')")
    return
}

StartRun(startLogic) {
    global _isRunning
    _isRunning := TRUE
    wv.ExecuteScriptAsync("SwitchUIMode('" TRUE "')")
    SetTimer(() => _main(startLogic), -1)
    return
}

FinishRun() {
    global _isRunning
    _isRunning := FALSE
    wv.ExecuteScriptAsync("SwitchUIMode('" FALSE "')")
    SendMsg("⏹️ 동작을 중지합니다.")
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
    return obj
}

UpdateUserIni(obj) {
    IniWrite obj.InstanceName, "Settings.ini", "UserSettings", "InstanceName"
    IniWrite obj.Delay, "Settings.ini", "UserSettings", "Delay"
    IniWrite obj.AcceptingTerm, "Settings.ini", "UserSettings", "AcceptingTerm"
    IniWrite obj.BufferTerm, "Settings.ini", "UserSettings", "BufferTerm"
}
