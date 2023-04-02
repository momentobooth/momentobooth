# The following works but is quite slow
#WinActivate("Remote")
#WinWaitActive("Remote") # A wait is not even necessary
#Sleep(500) # Samesies
#Send("1")
ControlClick("Remote", "", 1001)
# ID of notes text is 65535, could be used to get status of transfer