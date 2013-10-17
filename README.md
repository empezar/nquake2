nquake2
=======

nQuake2 for Windows

To compile an nQuake2 installer, follow these steps:

1) Download NSIS (http://nsis.sourceforge.net/) - version 2.46 or v3.0+ doesn't matter.
2) Copy/move the Plugins and Include folders to C:\Program Files (x86)\NSIS\.
3) Right-click the nquake2-installer_source.nsi file and open with makensisw.exe.

Tips:
* Most of the code resides in nquake2-installer_source.nsi but some code that is used often can be found in nquake2-macros.nsh.
* Edit the contents of the installer pages in the .ini files and their functions in the installer source file (e.g. Function DOWNLOAD for the download page).

If you decide to fork nQuake2 into your own installer, I would love to get some credit, but since this is GPL I can't force you :)

-
Niclas "Empezar" Lindstedt
2013-10-17
