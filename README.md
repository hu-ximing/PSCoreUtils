# PSCoreUtils

PowerShell 7 custom utility modules.

- `grep`
  
  [https://github.com/hu-ximing/grep](https://github.com/hu-ximing/grep)
  
  PowerShell implementation of linux `grep`
  
  ```powershell
  grep "hello" 1.txt *.cpp
  ```
  
  ```powershell
  cat Hello.java | grep "hello"
  ```
  
  ```powershell
  ls | grep 1.txt
  ```

- `Test-TcpPortConnection` or `tp`
  
  Quickly test tcp port connection to a computer.
  
  Source code is provided by [Surender Kumar's blog](https://www.techtutsonline.com/powershell-alternative-telnet-command/)
  
  ```powershell
  tp 192.168.100.10 8080
  ```

- `Get-Spotlight`
  
  Copy Windows Spotlight pictures to desktop.
  
  ```powershell
  Get-Spotlight # picture folder is copied to desktop
  ```

- `ln`
  
  PowerShell implementation of linux `ln`
  
  ```powershell
  # softlink
  ln -s "/path/to/file_or_directory" "path/to/symlink"
  
  # hardlink
  ln "/path/to/file" "path/to/hardlink"
  ```

- `touch`
  
  PowerShell implementation of linux `touch`
  
  ```powershell
  touch 1.txt
  ```

- `Get-Image`
  
  Gets details of a image file.
  
  ```powershell
  Get-Image .\cat.jpg
  ```
  
  ```txt
  D:\pictures\cat\cat.jpg
  
  Tag                  :
  PhysicalDimension    : {Width=4096, Height=3072}
  Size                 : {Width=4096, Height=3072}
  Width                : 4096
  Height               : 3072
  HorizontalResolution : 72
  VerticalResolution   : 72
  Flags                : 77840
  RawFormat            : Jpeg
  PixelFormat          : Format24bppRgb
  PropertyIdList       : {271, 272, 282, 283…}
  PropertyItems        : {271, 272, 282, 283…}
  Palette              : System.Drawing.Imaging.ColorPalette
  FrameDimensionsList  : {7462dc86-6180-4c7e-8e3f-ee7333a7a483}
  ```

- `Compare-Directory`
  
  Roughly compares content between two directories.
  
  ```powershell
  Compare-Directory .\dir1 .\dir2
  ```
  
  ```powershell
  Name  Length SideIndicator
  ----  ------ -------------
  a.txt      0 => # a.txt is empty in dir2
  c.txt      0 => # c.txt is only in dir2
  a.txt      6 <= # a.txt is modified in dir1
  b.txt      0 <= # b.txt is only in dir1
  ```

- `chext`
  
  Change the extensions of all `.cpp` files and `a.log` to `.txt`
  
  ```powershell
  chext *.cpp, a.log txt
  ```

- `Get-FullHistory` or `history`
  
  Prints command line history. Edit the history file with `-e` flag.
  
  This modifies the default `history` alias.
  
  ```powershell
  history # history is print to the console
  ```
